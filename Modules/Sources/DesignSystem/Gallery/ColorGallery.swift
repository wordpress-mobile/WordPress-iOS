import SwiftUI

struct ColorGallery: View {
    @Environment(\.self) var environment

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            Group {
                foregroundSection
                backgroundSection
            }
        }
        .navigationTitle("Colors")
    }

    private var foregroundSection: some View {
        Section(header: sectionTitle("Foreground")) {
            listItem(
                with: "Primary",
                description: "Color(.label)",
                color: Color(.label)
            )
            listItem(
                with: "Secondary",
                description: "Color(.secondaryLabel)",
                color: Color(.secondaryLabel)
            )
            listItem(
                with: "Tertiary",
                description: "Color(.tertiaryLabel)",
                color: Color(.tertiaryLabel)
            )
            listItem(
                with: "Quaternary",
                description: "Color(.quaternaryLabel)",
                color: Color(.quaternaryLabel)
            )
            listItem(
                with: "Success",
                description: "Color.green",
                color: Color.green
            )
            listItem(
                with: "Warning",
                description: "Color.yellow",
                color: Color.yellow
            )
            listItem(
                with: "Error",
                description: "Color.red",
                color: .red
            )
        }
    }

    private var backgroundSection: some View {
        Section(header: sectionTitle("Background")) {
            listItem(
                with: "Primary",
                description: "Color(.systemBackground)",
                color: Color(.systemBackground)
            )
            listItem(
                with: "Secondary",
                description: "Color(.systemBackground)",
                color: Color(.secondarySystemBackground)
            )
            listItem(
                with: "Tertiary",
                description: "Color(.tertiarySystemBackground)",
                color: Color(.tertiarySystemBackground)
            )
            listItem(
                with: "SystemFill",
                description: "Color(.systemFill)",
                color: Color(.systemFill)
            )
            listItem(
                with: "Secondary SystemFill",
                description: "Color(.secondarySystemFill)",
                color: Color(.secondarySystemFill)
            )
            listItem(
                with: "Tertiary SystemFill",
                description: "Color(.tertiarySystemFill)",
                color: Color(.tertiarySystemFill)
            )
            listItem(
                with: "Quaternary SystemFill",
                description: "Color(.quaternarySystemFill)",
                color: Color(.quaternarySystemFill)
            )
            listItem(
                with: "Grouped",
                description: "Color(.systemGroupedBackground)",
                color: Color(.systemGroupedBackground)
            )
            listItem(
                with: "Secondary Grouped",
                description: "Color(.secondarySystemGroupedBackground)",
                color: Color(.secondarySystemGroupedBackground)
            )
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Font.headline)
            .foregroundColor(.secondary)
    }

    private func colorSquare(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 44, height: 44)
    }

    private func listItem(with name: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            colorSquare(color)
            VStack(spacing: 8) {
                HStack {
                    Text(name)
                        .foregroundColor(.primary)
                    Spacer()
                }
                HStack {
                    Text(color.hexString(for: environment)).foregroundColor(.secondary).font(.caption)
                    Spacer()
                }
            }
        }
    }
}

private extension Color {

    func hexString(for environment: EnvironmentValues) -> String {

        if #available(iOS 17.0, *) {
            let resolved = self.resolve(in: environment)

            guard let components = resolved.cgColor.components, components.count >= 3 else {
                return ""
            }

            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])

            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }

        return ""
    }
}

// MARK: - Helpers for Color Gallery
private extension UIColor {
    func color(for trait: UITraitCollection?) -> UIColor {
        if let trait {
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

}
