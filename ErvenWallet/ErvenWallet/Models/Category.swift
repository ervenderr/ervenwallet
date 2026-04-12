import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "tag"
    var colorHex: String = "#8E8E93"
    var typeRaw: String = CategoryType.expense.rawValue
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(
        name: String,
        icon: String = "tag",
        colorHex: String = "#8E8E93",
        type: CategoryType,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.typeRaw = type.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var type: CategoryType {
        get { CategoryType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }
}
