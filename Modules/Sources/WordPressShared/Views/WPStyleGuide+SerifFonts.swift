import Foundation
import UIKit

#if SWIFT_PACKAGE
import WordPressSharedObjC
#endif

/// WPStyleGuide Extension to use serif fonts.
///
extension WPStyleGuide {
    /// Returns the system serif font (New York) for iOS 13+ but defaults to noto for older os's
    @objc public class func serifFontForTextStyle(
        _ style: UIFont.TextStyle,
        fontWeight weight: UIFont.Weight = .regular) -> UIFont {

        guard #available(iOS 13, *) else {
            return WPStyleGuide.notoFontForTextStyle(style, fontWeight: weight)
        }

        return scaledFont(for: style, weight: weight, design: .serif)
    }

    // Returns the system serif font (New York) for iOS 13+ but defaults to noto for older os's, at the default size for the specified style
    @objc public class func fixedSerifFontForTextStyle(_ style: UIFont.TextStyle,
                                                       fontWeight weight: UIFont.Weight = .regular) -> UIFont {

        let defaultContentSizeCategory = UITraitCollection(preferredContentSizeCategory: .large) // .large is the default
        let fontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultContentSizeCategory).pointSize

        guard #available(iOS 13, *),
              let fontDescriptor = UIFont.systemFont(ofSize: fontSize, weight: weight).fontDescriptor.withDesign(.serif)  else {
            switch weight {
            case .bold, .semibold, .heavy, .black:
                return WPStyleGuide.fixedBoldNotoFontWithSize(fontSize)
            default:
                return WPStyleGuide.fixedNotoFontWithSize(fontSize)
            }
        }

        // Uses size from original font, so we don't want to override it here.
        return UIFont(descriptor: fontDescriptor, size: 0.0)
    }

    private class func notoFontForTextStyle(_ style: UIFont.TextStyle,
                                            fontWeight weight: UIFont.Weight = .regular) -> UIFont {
        var font: UIFont

        switch weight {
        // Map all the bold weights to the bold font
        case .bold, .semibold, .heavy, .black:
            font = WPStyleGuide.notoBoldFontForTextStyle(style)
        default:
            font = WPStyleGuide.notoFontForTextStyle(style)
        }

        return font
    }
}
