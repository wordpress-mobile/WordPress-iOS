import Foundation
import UIKit
import WordPressShared
import WordPressSharedObjCUI

/// WPStyleGuide Extension to use serif fonts.
///
extension WPStyleGuide {
    /// Returns a system serif font scaled for the user's text size.
    @objc public class func serifFontForTextStyle(
        _ style: UIFont.TextStyle,
        fontWeight weight: UIFont.Weight = .regular
    ) -> UIFont {

        scaledFont(for: style, weight: weight, design: .serif)
    }

    /// Returns a system serif font at the default size for the text style.
    @objc public class func fixedSerifFontForTextStyle(
        _ style: UIFont.TextStyle,
        fontWeight weight: UIFont.Weight = .regular
    ) -> UIFont {

        let font = fixedFont(for: style, weight: weight)
        guard let fontDescriptor = font.fontDescriptor.withDesign(.serif) else {
            return font
        }

        // Uses size from original font, so we don't want to override it here.
        return UIFont(descriptor: fontDescriptor, size: 0.0)
    }
}
