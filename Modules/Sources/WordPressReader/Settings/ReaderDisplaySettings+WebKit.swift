import UIKit

// MARK: - ReaderDisplaySetting (CSS)

extension ReaderDisplaySettings {
    /// Creates a set of CSS styles that could be applied to a HTML file with
    /// Gutenberg blocks to render them in a nice app that fits with the design
    /// of the app.
    @MainActor
    func makeStyles(tintColor: UIColor) -> String {
        Self.baseStylesheet.appending(makeStyleOverrides(tintColor: tintColor))
    }

    private static let baseStylesheet: String = {
        guard let fileURL = Bundle.module.url(forResource: "gutenbergContentStyles", withExtension: "css"),
              let string = try? String(contentsOf: fileURL) else {
            assertionFailure("css missing")
            return ""
        }
        return string
    }()

    /// Additional styles based on system or custom theme.
    private func makeStyleOverrides(tintColor: UIColor) -> String {
        """
        :root {
            --text-font: \(font.cssString);
            --link-font-weight: \(color == .system ? "inherit" : "600");
            --link-text-decoration: \(color == .system ? "inherit" : "underline");
        }

        @media(prefers-color-scheme: light) {
            \(makeColors(interfaceStyle: .light, tintColor: tintColor))
        }

        @media(prefers-color-scheme: dark) {
            \(makeColors(interfaceStyle: .dark, tintColor: tintColor))
        }
        """
    }

    /// CSS color definitions that matches the current color theme.
    ///
    /// - parameter interfaceStyle: The current `UIUserInterfaceStyle` value.
    private func makeColors(interfaceStyle: UIUserInterfaceStyle, tintColor: UIColor) -> String {
        let trait = UITraitCollection(userInterfaceStyle: interfaceStyle)
        return """
        :root {
            --text-color: \(color.foreground.color(for: trait).cssHex);
            --text-secondary-color: \(color.secondaryForeground.color(for: trait).cssHex);
            --link-color: \(tintColor.color(for: trait).cssHex);
            --mention-background-color: \(tintColor.withAlphaComponent(0.1).color(for: trait).cssHex);
            --background-secondary-color: \( color.secondaryBackground.color(for: trait).cssHex);
            --border-color: \(color.border.color(for: trait).cssHex);
        }
        """
    }
}

private extension UIColor {
    var cssHex: String {
        "#\(hexStringWithAlpha)"
    }
}
