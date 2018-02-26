import Foundation

extension Style {
    static var wordPress: Skin {
        return WordPressSkin()
    }
    
    /// Creates a UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func fontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        return UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
    }
}
