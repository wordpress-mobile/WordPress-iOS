import SwiftUI

struct SpacingGallery: View {
    var body: some View {
        NavigationView {
            List {
                spacingRow(spacing: Spacing.DS.minimum, title: "Minimum")
                spacingRow(spacing: Spacing.DS.small, title: "Small")
                spacingRow(spacing: Spacing.DS.medium, title: "Medium")
                spacingRow(spacing: Spacing.DS.default, title: "Default")
                spacingRow(spacing: Spacing.DS.large, title: "Large")
                spacingRow(spacing: Spacing.DS.maximum, title: "Maximum")
            }
        }
        .navigationTitle("Spacing")
    }

    private func spacingRow(spacing: CGFloat, title: String) -> some View {
        HStack() {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.DS.Foreground.secondary)
                .frame(width: spacing)
                .padding(.trailing, Spacing.DS.maximum + Spacing.DS.medium - spacing)

            Text(title).foregroundColor(.DS.Foreground.primary)
        }
    }
}
