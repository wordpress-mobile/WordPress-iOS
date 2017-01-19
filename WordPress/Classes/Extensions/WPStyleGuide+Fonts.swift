import Foundation
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the Reader feature.
///
extension WPStyleGuide {

    /// Returns the font delta for the specified category, adjusting the delta by
    /// by one per step.
    ///
    public class func singleStepFontSizeDelta(_ category: UIContentSizeCategory) -> CGFloat {
        if category == .extraSmall {
            return -3.0
        } else if category == .small {
            return -2.0
        } else if category == .medium {
            return -1.0
        } else if category == .large {
            return 0.0
        } else if category == .extraLarge {
            return 1.0
        } else if category == .extraExtraLarge {
            return 2.0
        }

        // .extraExtraExtraLarge and all Accessibility sizes.
        return 3.0
    }

}
