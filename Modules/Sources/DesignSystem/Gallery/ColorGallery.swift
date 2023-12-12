import SwiftUI

struct ColorGallery: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            Group {
                foregroundSection
                backgroundSection
                dividerSection
            }
        }
        .navigationTitle("Colors")
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
            listItem(
                with: "Brand",
                hexString: hexString(for: .DS.Foreground.brand(isJetpack: true)),
                color: Color.DS.Foreground.brand(isJetpack: true)
            )
            listItem(
                with: "Success",
                hexString: hexString(for: .DS.Foreground.success),
                color: Color.DS.Foreground.brand(isJetpack: true)
            )
            listItem(
                with: "Warning",
                hexString: hexString(for: .DS.Foreground.warning),
                color: Color.DS.Foreground.warning
            )
            listItem(
                with: "Error",
                hexString: hexString(for: .DS.Foreground.error),
                color: Color.DS.Foreground.error
            )
        }
    }

    private var backgroundSection: some View {
        Section(header: sectionTitle("Background")) {
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
            listItem(
                with: "Brand",
                hexString: hexString(for: .DS.Background.brand(isJetpack: true)),
                color: Color.DS.Background.brand(isJetpack: true)
            )
        }
    }

    private var dividerSection: some View {
        Section(header: sectionTitle("Divider")) {
            listItem(
                with: "Divider",
                hexString: hexString(for: .DS.divider),
                color: Color.DS.divider
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

// MARK: - Helpers for Color Gallery
private extension UIColor {
    func color(for trait: UITraitCollection?) -> UIColor {
        if let trait = trait {
            return resolvedColor(with: trait)
        }
        return self
    }

    func lightVariant() -> UIColor {
        return color(for: UITraitCollection(userInterfaceStyle: .light))
    }

    func darkVariant() -> UIColor {
        return color(for: UITraitCollection(userInterfaceStyle: .dark))
    }

    func hexString() -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
