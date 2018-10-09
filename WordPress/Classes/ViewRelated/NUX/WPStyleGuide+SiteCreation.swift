import WordPressShared


extension WPStyleGuide {

    class func edgeInsetForLoginTextFields() -> UIEdgeInsets {
        return UIEdgeInsets(top: 7, left: 20, bottom: 7, right: 20)
    }

    /// Return the system font in medium weight for the given style
    ///
    /// - note: iOS won't return UIFontWeightMedium for dynamic system font :(
    /// So instead get the dynamic font size, then ask for the non-dynamic font at that size
    ///
    class func mediumWeightFont(forStyle style: UIFont.TextStyle, maximumPointSize: CGFloat = WPStyleGuide.maxFontSize) -> UIFont {
        let fontToGetSize = WPStyleGuide.fontForTextStyle(style)
        let maxAllowedFontSize = CGFloat.minimum(fontToGetSize.pointSize, maximumPointSize)
        return UIFont.systemFont(ofSize: maxAllowedFontSize, weight: .medium)
    }
}
