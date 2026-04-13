import SwiftUI

/// ErvenWallet brand mark. Render in a Preview at 1024×1024 and screenshot
/// to produce the App Icon asset. Theme: "Quiet Ledger" — deep teal + gold.
struct AppLogo: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                // Background: deep teal gradient, iOS-icon squircle.
                RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.06, green: 0.53, blue: 0.49),  // #0F8780
                                Color(red: 0.04, green: 0.33, blue: 0.31)   // #0A5450
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Ledger mark: three rows forming a stylized "E".
                // Top and middle rows in warm white; bottom row in gold.
                VStack(alignment: .leading, spacing: size * 0.07) {
                    LedgerBar(widthRatio: 0.62)
                        .fill(Color.white.opacity(0.95))
                        .frame(height: size * 0.09)

                    LedgerBar(widthRatio: 0.46)
                        .fill(Color.white.opacity(0.95))
                        .frame(height: size * 0.09)

                    LedgerBar(widthRatio: 0.62)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.75, blue: 0.14), // #FBBF24
                                    Color(red: 0.96, green: 0.62, blue: 0.04)  // #F59E0B
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: size * 0.11)
                        .shadow(color: Color.orange.opacity(0.35), radius: size * 0.015, x: 0, y: size * 0.005)
                }
                .frame(width: size * 0.62, alignment: .leading)
                .offset(x: -size * 0.03)

                // Subtle top highlight for depth.
                RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// A left-aligned rounded bar forming one row of the ledger "E".
private struct LedgerBar: Shape {
    let widthRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let barWidth = rect.width * widthRatio
        let barRect = CGRect(x: 0, y: 0, width: barWidth, height: rect.height)
        return Path(roundedRect: barRect, cornerRadius: rect.height / 2, style: .continuous)
    }
}

#Preview("App Icon 1024") {
    AppLogo()
        .frame(width: 1024, height: 1024)
        .background(Color.black)
}

#Preview("Home Screen 180") {
    AppLogo()
        .frame(width: 180, height: 180)
}
