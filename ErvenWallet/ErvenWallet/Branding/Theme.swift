import SwiftUI
import UIKit

/// Central design tokens for the "Quiet Ledger" theme.
/// All colors, spacing, radii, and shadows live here so the app can be
/// re-skinned from a single file.
enum Theme {

    // MARK: - Palette

    enum Palette {
        static let primary = Color(red: 0.06, green: 0.47, blue: 0.43)       // #0F766E deep teal
        static let primaryDark = Color(red: 0.04, green: 0.33, blue: 0.31)   // #0A5450
        static let primaryLight = Color(red: 0.08, green: 0.58, blue: 0.53)  // #149688

        static let accent = Color(red: 0.96, green: 0.62, blue: 0.04)        // #F59E0B warm gold
        static let accentLight = Color(red: 0.98, green: 0.75, blue: 0.14)   // #FBBF24

        static let income = Color(red: 0.06, green: 0.73, blue: 0.51)        // #10B981 emerald
        static let expense = Color(red: 0.94, green: 0.27, blue: 0.27)       // #EF4444 coral

        static let surface = Color(UIColor.systemBackground)
        static let surfaceElevated = Color(UIColor.secondarySystemBackground)
        static let divider = Color(UIColor.separator)
    }

    // MARK: - Gradients

    enum Gradients {
        static let hero = LinearGradient(
            colors: [Palette.primaryLight, Palette.primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accent = LinearGradient(
            colors: [Palette.accentLight, Palette.accent],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - Shadow

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    enum Shadow {
        static let card = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 4
        )

        static let hero = ShadowStyle(
            color: Palette.primary.opacity(0.35),
            radius: 20,
            x: 0,
            y: 10
        )
    }
}

extension View {
    func themeShadow(_ style: Theme.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// Standard modal detents + drag indicator for Add sheets.
    func themeSheet() -> some View {
        self
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }
}

/// Deterministic color for a category name, so the same category gets the
/// same color across transaction rows, budget bars, and reports.
enum CategoryColor {
    private static let palette: [Color] = [
        Color(red: 0.06, green: 0.47, blue: 0.43),   // teal
        Color(red: 0.96, green: 0.62, blue: 0.04),   // gold
        Color(red: 0.06, green: 0.73, blue: 0.51),   // emerald
        Color(red: 0.94, green: 0.27, blue: 0.27),   // coral
        Color(red: 0.55, green: 0.36, blue: 0.96),   // violet
        Color(red: 0.02, green: 0.58, blue: 0.80),   // sky
        Color(red: 0.93, green: 0.47, blue: 0.78),   // pink
        Color(red: 0.43, green: 0.54, blue: 0.18),   // olive
    ]

    static func color(for name: String) -> Color {
        guard !name.isEmpty else { return palette[0] }
        var hash = 5381
        for byte in name.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return palette[abs(hash) % palette.count]
    }
}
