import SwiftUI

/// Round floating-action button for "add" surfaces. Teal gradient fill,
/// gold accent ring, and themed drop shadow.
struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Theme.Gradients.hero)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Theme.Palette.accentLight.opacity(0.4), lineWidth: 1)
                )
                .themeShadow(Theme.Shadow.hero)
        }
        .buttonStyle(.plain)
    }
}
