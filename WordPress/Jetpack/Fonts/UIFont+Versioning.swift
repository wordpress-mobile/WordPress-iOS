import Foundation

extension FontStyles {

    /// The current version of the Font Styles used in Jetpack.
    static let current: FontStyles = {
        return FontStyles(prominent: FontStyles.prominentFont(style:weight:))
    }()
}

// MARK: - UIFont Extension

extension UIFont {

    /// The current version of the Font Styles used in Jetpack.
    static var styles: FontStyles {
        return FontStyles.current
    }
}

// MARK: - Helpers

extension FontStyles {

    private static func prominentFont(style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        WPStyleGuide.fontForTextStyle(style, fontWeight: weight)
    }
}
