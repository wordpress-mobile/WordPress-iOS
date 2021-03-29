import SwiftUI

extension Text {

    /// This initializer constructs a Text from a String that contains simple HTML elements.
    /// It currently only handles bold and italic text, but could be extended in the future
    /// to check for other attributes.
    ///
    init(htmlString: String) {
        self.init("")

        var text = Text("")

        guard let data = htmlString.data(using: .utf8),
              let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) else {
            return
        }

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length),
                                             options: []) { (attributes, range, _) in
            var subText = Text(attributedString.attributedSubstring(from: range).string)

            if let font = attributes[NSAttributedString.Key.font] as? UIFont {
                if font.isBold {
                    subText = subText.bold()
                }
                if font.isItalic {
                    subText = subText.italic()
                }
            }

            text = text + subText
        }

        self = text
    }
}
