/// Extension on WPStyleGuide to use Dynamic Type fonts.
///
extension WPStyleGuide {

    static let notoLoaded = { () -> Bool in
        WPFontManager.loadNotoFontFamily()
        return true
    }()

    /// Configures a table to automatically resize its rows according to their content.
    ///
    /// - Parameters:
    ///     - tableView: The tableView to configure.
    ///
    public class func configureAutomaticHeightRowsForTableView(_ tableView: UITableView) {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44//WPTableViewDefaultRowHeight
    }

    /// Configures a label with the default system font with the specified style.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///
    public class func configureLabel(_ label: UILabel, forTextStyle style: UIFontTextStyle) {
        label.font = UIFont.preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Configures a label with the default system font with the specified style and traits.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///     - traits: The desired UIFontDescriptorSymbolicTraits.
    ///
    public class func configureLabel(_ label: UILabel, forTextStyle style: UIFontTextStyle, withTraits traits: UIFontDescriptorSymbolicTraits) {
        label.font = self.fontForTextStyle(style, withTraits: traits)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Configures a label with the default system font with the specified style and weight.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///     - weight: The desired weight (UIFontWeightUltraLight, UIFontWeightThin, UIFontWeightLight,
    ///       UIFontWeightRegular, UIFontWeightMedium, UIFontWeightSemibold, UIFontWeightBold,
    ///       UIFontWeightHeavy, UIFontWeightBlack).
    ///
    public class func configureLabel(_ label: UILabel, forTextStyle style: UIFontTextStyle, withWeight weight: CGFloat) {
        label.font = self.fontForTextStyle(style, withWeight: weight)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Configures a label with the regular Noto font with the specified style.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///
    public class func configureLabelForNotoFont(_ label: UILabel, forTextStyle style: UIFontTextStyle) {
        label.font = self.notoFontForTextStyle(style)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Creates a UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    public class func fontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        return UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
    }

    /// Creates a UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///     - traits: The desired UIFontDescriptorSymbolicTraits.
    ///
    /// - Returns: The created font.
    ///
    public class func fontForTextStyle(_ style: UIFontTextStyle, withTraits traits: UIFontDescriptorSymbolicTraits) -> UIFont {
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        fontDescriptor = fontDescriptor.withSymbolicTraits(traits) ?? fontDescriptor
        return UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
    }

    /// Creates a UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///     - weight: The desired weight (UIFontWeightUltraLight, UIFontWeightThin, UIFontWeightLight,
    ///       UIFontWeightRegular, UIFontWeightMedium, UIFontWeightSemibold, UIFontWeightBold,
    ///       UIFontWeightHeavy, UIFontWeightBlack).
    ///
    /// - Returns: The created font.
    ///
    public class func fontForTextStyle(_ style: UIFontTextStyle, withWeight weight: CGFloat) -> UIFont {
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let traits = [UIFontWeightTrait: weight]
        fontDescriptor = fontDescriptor.addingAttributes([UIFontDescriptorTraitsAttribute: traits])
        return UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
    }

    /// Creates a UIFont for the user current text size settings and calculates its size.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font point size.
    ///
    public class func fontSizeForTextStyle(_ style: UIFontTextStyle) -> CGFloat {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
        return font.pointSize
    }

    /// Creates a NotoSerif UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    public class func notoFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return self.customNotoFontNamed("NotoSerif", forTextStyle: style)
    }

    /// Creates a NotoSerif Bold UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    public class func notoBoldFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return self.customNotoFontNamed("NotoSerif-Bold", forTextStyle: style)
    }

    /// Creates a NotoSerif Italic UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    public class func notoItalicFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return self.customNotoFontNamed("NotoSerif-Italic", forTextStyle: style)
    }

    /// Creates a NotoSerif BoldItalic UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    public class func notoBoldItalicFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return self.customNotoFontNamed("NotoSerif-BoldItalic", forTextStyle: style)
    }

    /// Creates a Noto UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - fontName: the Noto font name (NotoSerif, NotoSerif-Bold, NotoSerif-Italic, NotoSerif-BoldItalic)
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font point size.
    ///
    private class func customNotoFontNamed(_ fontName: String, forTextStyle style: UIFontTextStyle) -> UIFont {
        _ = notoLoaded
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        return UIFont(name: fontName, size: fontDescriptor.pointSize)!
    }
}
