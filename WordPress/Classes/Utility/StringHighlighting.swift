import UIKit
import WordPressUI

struct StringHighlighter {
    // MARK: - Style Methods

    static func highlightString(_ substring: String, inString: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: inString)

        guard let subStringRange = inString.nsRange(of: substring) else {
            return attributedString
        }

        attributedString.addAttributes([
            .foregroundColor: substringHighlightTextColor,
            .font: substringHighlightFont
        ], range: subStringRange)

        return attributedString
    }

    // MARK: - Style Values
    static let substringHighlightTextColor = UIAppColor.primary
    static let substringHighlightFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
}
