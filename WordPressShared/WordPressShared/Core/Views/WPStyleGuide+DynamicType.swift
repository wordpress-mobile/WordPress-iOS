import Foundation

/// Extension on WPStyleGuide to use Dynamic Type fonts.
///
extension WPStyleGuide {
    @objc static let defaultTableViewRowHeight: CGFloat = 44.0

    /// Configures a table to automatically resize its rows according to their content.
    ///
    /// - Parameters:
    ///     - tableView: The tableView to configure.
    ///
    @objc public class func configureAutomaticHeightRows(for tableView: UITableView) {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = defaultTableViewRowHeight
    }

    /// Configures a label with the default system font with the specified style.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///
    @objc public class func configureLabel(_ label: UILabel, textStyle style: UIFontTextStyle) {
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
    @objc public class func configureLabel(_ label: UILabel, textStyle style: UIFontTextStyle, symbolicTraits traits: UIFontDescriptorSymbolicTraits) {
        label.font = fontForTextStyle(style, symbolicTraits: traits)
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
    @objc public class func configureLabel(_ label: UILabel, textStyle style: UIFontTextStyle, fontWeight weight: UIFont.Weight) {
        label.font = fontForTextStyle(style, fontWeight: weight)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Configures a label with the regular Noto font with the specified style.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///
    @objc public class func configureLabelForNotoFont(_ label: UILabel, textStyle style: UIFontTextStyle) {
        label.font = notoFontForTextStyle(style)
        label.adjustsFontForContentSizeCategory = true
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

    /// Creates a UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///     - traits: The desired UIFontDescriptorSymbolicTraits.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func fontForTextStyle(_ style: UIFontTextStyle, symbolicTraits traits: UIFontDescriptorSymbolicTraits) -> UIFont {
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
    @objc public class func fontForTextStyle(_ style: UIFontTextStyle, fontWeight weight: UIFont.Weight) -> UIFont {
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)

#if swift(>=4.0)
        let traits = [UIFontDescriptor.TraitKey.weight: weight]
        fontDescriptor = fontDescriptor.addingAttributes([.traits: traits])
#else
        let traits = [UIFontWeightTrait: weight]
        fontDescriptor = fontDescriptor.addingAttributes([UIFontDescriptorTraitsAttribute: traits])
#endif

        return UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
    }

    /// Creates a UIFont for the user current text size settings and calculates its size.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font point size.
    ///
    @objc public class func fontSizeForTextStyle(_ style: UIFontTextStyle) -> CGFloat {
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
    @objc public class func notoFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif", forTextStyle: style)
    }

    /// Creates a NotoSerif Bold UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func notoBoldFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif-Bold", forTextStyle: style)
    }

    /// Creates a NotoSerif Italic UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func notoItalicFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif-Italic", forTextStyle: style)
    }

    /// Creates a NotoSerif BoldItalic UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func notoBoldItalicFontForTextStyle(_ style: UIFontTextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif-BoldItalic", forTextStyle: style)
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
        WPFontManager.loadNotoFontFamily()
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        guard let font = UIFont(name: fontName, size: fontDescriptor.pointSize) else {
            // If we can't get the Noto font for some reason we will default to the system font
            return fontForTextStyle(style)
        }
        return font
    }
}
