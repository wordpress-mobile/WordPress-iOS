import Foundation
import UIKit
import WordPressSharedObjC

/// Extension on WPStyleGuide to use Dynamic Type fonts.
///
extension WPStyleGuide {
    @objc static let defaultTableViewRowHeight: CGFloat = 44.0

    @objc public static let maxFontSize: CGFloat = 32.0

    /// Configures a table to automatically resize its rows according to their content.
    ///
    /// - Parameters:
    ///     - tableView: The tableView to configure.
    ///
    @objc public class func configureAutomaticHeightRows(for tableView: UITableView) {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = defaultTableViewRowHeight
    }

    /// Configures a label with the default system font with the specified style.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///
    @objc public class func configureLabel(_ label: UILabel, textStyle style: UIFont.TextStyle) {
        label.font = fontForTextStyle(style)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Configures a label with the default system font with the specified style and traits.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///     - traits: The desired UIFontDescriptorSymbolicTraits.
    ///
    @objc public class func configureLabel(_ label: UILabel, textStyle style: UIFont.TextStyle, symbolicTraits traits: UIFontDescriptor.SymbolicTraits) {
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
    @objc public class func configureLabel(_ label: UILabel, textStyle style: UIFont.TextStyle, fontWeight weight: UIFont.Weight) {
        label.font = fontForTextStyle(style, fontWeight: weight)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Configures a label with the regular Noto font with the specified style.
    ///
    /// - Parameters:
    ///     - label: The label to configure.
    ///     - style: The desired UIFontTextStyle.
    ///
    @objc public class func configureLabelForNotoFont(_ label: UILabel, textStyle style: UIFont.TextStyle) {
        label.font = notoFontForTextStyle(style)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Creates a UIFont for the user current text size settings and a maximum font size
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///     - maximumPointSize: The biggest font size allowed.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func fontForTextStyle(_ style: UIFont.TextStyle, maximumPointSize: CGFloat = maxFontSize) -> UIFont {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        return UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
    }

    /// Creates a UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///     - traits: The desired UIFontDescriptorSymbolicTraits.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func fontForTextStyle(_ style: UIFont.TextStyle, symbolicTraits traits: UIFontDescriptor.SymbolicTraits, maximumPointSize: CGFloat = maxFontSize) -> UIFont {
        var descriptor = fontDescriptor(style, maximumPointSize: maximumPointSize)
        descriptor = descriptor.withSymbolicTraits(traits) ?? descriptor
        return UIFont(descriptor: descriptor, size: CGFloat(0.0))
    }

    private class func fontDescriptor(_ style: UIFont.TextStyle, maximumPointSize: CGFloat = maxFontSize) -> UIFontDescriptor {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let fontToGetSize = UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
        let scaledFontSize = CGFloat.minimum(fontToGetSize.pointSize, maximumPointSize)
        return fontDescriptor.withSize(scaledFontSize)
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
    @objc public class func fontForTextStyle(_ style: UIFont.TextStyle, fontWeight weight: UIFont.Weight) -> UIFont {
        /// WORKAROUND: Some font weights scale up well initially but they don't scale up well if dynamic type
        ///     is changed in real time.  Creating a scaled font offers an alternative solution that works well
        ///     even in real time.
        let weightsThatNeedScaledFont: [UIFont.Weight] = [.black, .bold, .heavy, .semibold]

        guard !weightsThatNeedScaledFont.contains(weight) else {
            return scaledFont(for: style, weight: weight)
        }

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
    @objc public class func fontSizeForTextStyle(_ style: UIFont.TextStyle) -> CGFloat {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
        return font.pointSize
    }

    /// Creates a UIFont with fixed size, equal to the size of the given text style, assuming a default content size category.
    /// This font will never change its size.
    ///
    /// - Parameters:
    ///   - style: The base UIFontTextStyle to take the size from.
    ///   - weight: The desired font weight
    /// - Returns: The created font.
    ///
    @objc public class func fixedFont(for style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let defaultContentSizeCategory = UITraitCollection(preferredContentSizeCategory: .large) // .large is the default
        let fontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultContentSizeCategory).pointSize
        return UIFont.systemFont(ofSize: fontSize, weight: weight)
    }

    /// Created a scaled UIFont for the specified style and weight.  A scaled font will be resized Automatically
    /// by iOS to respond to dynamic type changes.
    ///
    /// - Important: The size of a scaled font built with this method may not match exactly the size for the built
    /// in fonts at the same dynamic type configuration, but this is currently a limitation with iOS rather than
    /// a limitation with this method.  For more info check:
    ///     https://stackoverflow.com/questions/51243804/uifontmetrics-scaled-font-size-calculation
    ///
    /// - Parameters:
    ///     - style: the style for the font.
    ///     - weight: the weight for the font.
    ///     - design: the design for the font.  The default value is `.default`.
    ///
    /// - Returns: the requested scaled font.
    ///
    class func scaledFont(for style: UIFont.TextStyle, weight: UIFont.Weight, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let fontDescriptorWithDesign = fontDescriptor.withDesign(design) ?? fontDescriptor
        let traits = [UIFontDescriptor.TraitKey.weight: weight]
        let finalDescriptor = fontDescriptorWithDesign.addingAttributes([.traits: traits])

        return UIFont(descriptor: finalDescriptor, size: finalDescriptor.pointSize)
    }

    /// Creates a NotoSerif UIFont at the specified size.
    ///
    /// - Parameters:
    ///     - size: The desired size.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func fixedNotoFontWithSize(_ size: CGFloat) -> UIFont {
        return fixedCustomNotoFontNamed("NotoSerif", withSize: size)
    }

    /// Creates a bold NotoSerif UIFont at the specified size.
    ///
    /// - Parameters:
    ///     - size: The desired size.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func fixedBoldNotoFontWithSize(_ size: CGFloat) -> UIFont {
        return fixedCustomNotoFontNamed("NotoSerif-Bold", withSize: size)
    }

    /// Creates a NotoSerif UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func notoFontForTextStyle(_ style: UIFont.TextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif", forTextStyle: style)
    }

    /// Creates a NotoSerif Bold UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func notoBoldFontForTextStyle(_ style: UIFont.TextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif-Bold", forTextStyle: style)
    }

    /// Creates a NotoSerif Italic UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func notoItalicFontForTextStyle(_ style: UIFont.TextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif-Italic", forTextStyle: style)
    }

    /// Creates a NotoSerif BoldItalic UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    @objc public class func notoBoldItalicFontForTextStyle(_ style: UIFont.TextStyle) -> UIFont {
        return customNotoFontNamed("NotoSerif-BoldItalic", forTextStyle: style)
    }

    /// Creates a Noto UIFont for the user current text size settings.
    ///
    /// - Parameters:
    ///     - fontName: the Noto font name (NotoSerif, NotoSerif-Bold, NotoSerif-Italic, NotoSerif-BoldItalic)
    ///     - style: The desired UIFontTextStyle.
    ///
    /// - Returns: The created font.
    ///
    private class func customNotoFontNamed(_ fontName: String, forTextStyle style: UIFont.TextStyle, maximumPointSize: CGFloat = maxFontSize) -> UIFont {
        WPFontManager.loadNotoFontFamily()
        let descriptor = fontDescriptor(style, maximumPointSize: maximumPointSize)

        guard let font = UIFont(name: fontName, size: descriptor.pointSize) else {
            // If we can't get the Noto font for some reason we will default to the system font
            return fontForTextStyle(style)
        }
        return font
    }

    /// Creates a Noto UIFont at the specified size.
    ///
    /// - Parameters:
    ///     - fontName: the Noto font name (NotoSerif, NotoSerif-Bold, NotoSerif-Italic, NotoSerif-BoldItalic)
    ///     - size: The desired point size.
    ///
    /// - Returns: The created font.
    ///
    private class func fixedCustomNotoFontNamed(_ fontName: String, withSize size: CGFloat) -> UIFont {
        WPFontManager.loadNotoFontFamily()
        guard let font = UIFont(name: fontName, size: size) else {
            // If we can't get the Noto font for some reason we will default to the system font
            if fontName.contains("Bold") {
                return UIFont.systemFont(ofSize: size, weight: .bold)
            } else {
                return UIFont.systemFont(ofSize: size)
            }
        }
        return font
    }
}
