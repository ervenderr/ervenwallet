import Foundation
import SwiftData
import UserNotifications

/// Schedules local notifications for credit card due dates and
/// checks for budget-exceeded situations on app launch.
///
/// No server component — all reminders are scheduled locally via
/// UNUserNotificationCenter and survive app relaunch.
enum NotificationService {

    // MARK: - Authorization

    /// Request permission if not yet determined. Safe to call repeatedly.
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    // MARK: - Bill due reminders

    /// Cancel and re-schedule bill-due reminders for every credit card
    /// account with a dueDay. Fires 2 days before the due date at 9am.
    @MainActor
    static func rescheduleBillReminders(in context: ModelContext) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Array(scheduledBillIDs))
        scheduledBillIDs.removeAll()

        guard let accounts = try? context.fetch(FetchDescriptor<Account>()) else { return }
        let calendar = Calendar.current
        let now = Date()

        for account in accounts where account.type == .creditCard {
            guard let dueDay = account.dueDay else { continue }
            guard let nextDue = nextDueDate(asOf: now, dueDay: dueDay, calendar: calendar),
                  let remindDate = calendar.date(byAdding: .day, value: -2, to: nextDue) else { continue }
            guard remindDate > now else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: remindDate)
            components.hour = 9

            let content = UNMutableNotificationContent()
            content.title = "\(account.name) due soon"
            content.body = "Payment due \(nextDue.formatted(.dateTime.month().day()))"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "bill-\(account.id.uuidString)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
            scheduledBillIDs.insert(id)
        }
    }

    private static var scheduledBillIDs: Set<String> = []

    private static func nextDueDate(asOf date: Date, dueDay: Int, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: date)
        let currentDay = calendar.component(.day, from: date)
        if currentDay >= dueDay {
            components.month = (components.month ?? 1) + 1
        }
        components.day = dueDay
        return calendar.date(from: components)
    }

    // MARK: - Budget alerts

    /// Inspect current-month budgets and fire a one-shot notification
    /// for any budget that is now exceeded. Deduped via notified-set so
    /// the same budget doesn't alert repeatedly across launches.
    @MainActor
    static func checkBudgetAlerts(in context: ModelContext) {
        guard let budgets = try? context.fetch(FetchDescriptor<Budget>()),
              let transactions = try? context.fetch(FetchDescriptor<Transaction>()) else { return }

        let currentMonth = Budget.normalize(month: Date())
        let monthBudgets = budgets.filter { $0.month == currentMonth }
        let calendar = Calendar.current

        var notified = UserDefaults.standard.stringArray(forKey: notifiedKey) ?? []
        let center = UNUserNotificationCenter.current()

        for budget in monthBudgets {
            guard let categoryID = budget.category?.id else { continue }
            var spent: Decimal = 0
            for txn in transactions {
                guard txn.type == .expense,
                      txn.category?.id == categoryID,
                      calendar.isDate(txn.date, equalTo: budget.month, toGranularity: .month) else { continue }
                spent += txn.amount
            }

            let key = "\(budget.id.uuidString)-\(calendar.component(.month, from: currentMonth))"
            guard spent > budget.amount, !notified.contains(key) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Budget exceeded"
            content.body = "\(budget.category?.name ?? "Category") is over budget this month."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "budget-\(key)",
                content: content,
                trigger: nil
            )
            center.add(request)
            notified.append(key)
        }

        UserDefaults.standard.set(notified, forKey: notifiedKey)
    }

    private static let notifiedKey = "NotificationService.notifiedBudgets"
}
