import UIKit

extension UIButton {

    /// Creates a bar button item that looks like the native title menu
    /// (see `navigationItem.titleMenuProvider`, iOS 16+).
    static func makeMenu(title: String, menu: UIMenu) -> UIButton {
        let button = UIButton(configuration: menuButtonConfiguration(title: title))
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        return button
    }

    /// The configuration of a bar button item that looks like the native title menu
    static func menuButtonConfiguration(title: String) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var attributes = $0
            attributes.font = WPStyleGuide.fontForTextStyle(.headline)
            return attributes
        }
        configuration.image = UIImage(systemName: "chevron.down.circle.fill")?.withBaselineOffset(fromBottom: 4)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .secondarySystemFill])
            .applying(UIImage.SymbolConfiguration(font: WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)))
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.baseForegroundColor = .label
        return configuration
    }
}
