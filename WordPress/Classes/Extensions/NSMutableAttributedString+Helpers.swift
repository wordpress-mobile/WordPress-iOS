import Foundation


extension NSMutableAttributedString {

    /// Applies a collection of Styles to all of the substrings that match a given pattern
    ///
    /// - Parameters:
    ///     - pattern: A Regex pattern that should be used to look up for matches
    ///     - styles: Collection of styles to be applied on the matched strings
    ///
    @objc public func applyStylesToMatchesWithPattern(_ pattern: String, styles: [NSAttributedString.Key: Any]) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
            let range = NSRange(location: 0, length: length)

            regex.enumerateMatches(in: string, options: .reportCompletion, range: range) { (result, _, _) -> Void in

                if let theResult = result {
                    self.addAttributes(styles, range: theResult.range)
                }
            }
        } catch { }
    }

    /// Replaces the first occurrence of placeholder text with a particular icon.
    ///
    /// - Parameters:
    ///     - placeholder: Text to find and replace
    ///     - icon: Image to replace placeholder text with, as a text attachment
    ///
    public func replace(_ placeholder: String, with icon: UIImage) {
        let nsstring = string as NSString
        let range = nsstring.range(of: placeholder)
        guard range.location != NSNotFound else {
            return
        }

        let font = attribute(NSAttributedString.Key.font, at: range.location, effectiveRange: nil) as? UIFont
        let capHeight = font?.capHeight ?? 0

        let attachment = NSTextAttachment()
        attachment.image = icon
        let yOrigin = ((capHeight - icon.size.height) / 2.0).rounded()
        attachment.bounds = CGRect(x: 0.0, y: yOrigin, width: icon.size.width, height: icon.size.height)

        let iconString = NSAttributedString(attachment: attachment)
        replaceCharacters(in: range, with: iconString)
    }
}
