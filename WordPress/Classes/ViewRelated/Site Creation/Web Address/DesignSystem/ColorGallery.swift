import SwiftUI

struct ColorGallery: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            foregroundSection
            backgroundSection
            borderSection
        }
    }

    private var foregroundSection: some View {
        Section(header: sectionTitle("Foreground")) {
            listItem(
                with: "Primary",
                hexString: hexString(for: .DS.Foreground.primary),
                color: Color.DS.Foreground.primary
            )
            listItem(
                with: "Secondary",
                hexString: hexString(for: .DS.Foreground.secondary),
                color: Color.DS.Foreground.secondary
            )
            listItem(
                with: "Tertiary",
                hexString: hexString(for: .DS.Foreground.tertiary),
                color: Color.DS.Foreground.tertiary
            )
            listItem(
                with: "Quaternary",
                hexString: hexString(for: .DS.Foreground.quaternary),
                color: Color.DS.Foreground.quaternary
            )
        }
    }

    private var backgroundSection: some View {
        Section(header: sectionTitle("Background")) {
            listItem(
                with: "Brand",
                hexString: hexString(for: .DS.Background.brand),
                color: Color.DS.Background.brand
            )
            listItem(
                with: "Primary",
                hexString: hexString(for: .DS.Background.primary),
                color: Color.DS.Background.primary
            )
            listItem(
                with: "Secondary",
                hexString: hexString(for: .DS.Background.secondary),
                color: Color.DS.Background.secondary
            )
            listItem(
                with: "Tertiary",
                hexString: hexString(for: .DS.Background.tertiary),
                color: Color.DS.Background.tertiary
            )
            listItem(
                with: "Quaternary",
                hexString: hexString(for: .DS.Background.quaternary),
                color: Color.DS.Background.quaternary
            )
        }
    }

    private var borderSection: some View {
        Section(header: sectionTitle("Border")) {
            listItem(
                with: "Divider",
                hexString: hexString(for: .DS.Border.divider),
                color: Color.DS.Border.divider
            )
            listItem(
                with: "Primary",
                hexString: hexString(for: .DS.Border.primary),
                color: Color.DS.Border.primary
            )
            listItem(
                with: "Secondary",
                hexString: hexString(for: .DS.Border.secondary),
                color: Color.DS.Border.secondary
            )
        }
    }

    private func hexString(for color: UIColor?) -> String? {
        colorScheme == .light ? color?.lightVariant().hexString() : color?.darkVariant().hexString()
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Font.headline)
            .foregroundColor(.DS.Foreground.primary)
    }

    private func colorSquare(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 44, height: 44)
    }

    private func listItem(with name: String, hexString: String?, color: Color) -> some View {
        HStack(spacing: 16) {
            colorSquare(color)
            VStack(spacing: 8) {
                HStack {
                    Text(name)
                        .foregroundColor(.DS.Foreground.primary)
                    Spacer()
                }
                HStack {
                    Text("#\(hexString ?? "")")
                        .foregroundColor(.DS.Foreground.secondary)
                    Spacer()
                }
            }
        }
    }
}
