import Foundation

class FormattableContentFormatter {

    /// Helper used by the +Interface Extension.
    ///
    fileprivate var dynamicAttributesCache = [String: AnyObject]()

    func render(content: FormattableContent, with styles: FormattableContentStyles) -> NSAttributedString {
        let attributedText = memoize {
            let snippet = self.text(from: content, with: styles)

            return snippet.trimNewlines()
        }

        return attributedText(styles.key)
    }

    func resetCache() {
        dynamicAttributesCache.removeAll()
    }

    /// This method is meant to aid cache-implementation into all of the AttributedString getters introduced
    /// in this extension.
    ///
    /// - Parameter fn: A Closure that, on execution, returns an attributed string.
    ///
    /// - Returns: A new Closure that on execution will either hit the cache, or execute the closure `fn`
    ///            and store its return value in the cache.
    ///
    fileprivate func memoize(_ fn: @escaping () -> NSAttributedString) -> (String) -> NSAttributedString {
        return { cacheKey in

            if let cachedSubject = self.cacheValueForKey(cacheKey) as? NSAttributedString {
                return cachedSubject
            }

            let newValue = fn()
            self.setCacheValue(newValue, forKey: cacheKey)
            return newValue
        }
    }

    // Dynamic Attribute Cache: Used internally by the Interface Extension, as an optimization.
    ///
    func cacheValueForKey(_ key: String) -> AnyObject? {
        return dynamicAttributesCache[key]
    }

    /// Stores a specified value within the Dynamic Attributes Cache.
    ///
    func setCacheValue(_ value: AnyObject?, forKey key: String) {
        guard let value = value else {
            dynamicAttributesCache.removeValue(forKey: key)
            return
        }

        dynamicAttributesCache[key] = value
    }

    private func text(from content: FormattableContent, with styles: FormattableContentStyles) -> NSAttributedString {

        guard let text = content.text else {
            return NSAttributedString()
        }

        let tightenedText = replaceCommonWhitespaceIssues(in: text)
        let theString = NSMutableAttributedString(string: tightenedText, attributes: styles.attributes)

        if let quoteStyles = styles.quoteStyles {
            theString.applyAttributes(toQuotes: quoteStyles)
        }

        // Apply the Ranges
        var lengthShift = 0

        for range in content.ranges {
            lengthShift += range.apply(styles, to: theString, withShift: lengthShift)
        }

        return theString
    }

    /// Replaces some common extra whitespace with hairline spaces so that comments display better
    ///
    /// - Parameter baseString: string of the comment body before attributes are added
    /// - Returns: string of same length
    /// - Note: the length must be maintained or the formatting will break
    private func replaceCommonWhitespaceIssues(in baseString: String) -> String {
        var newString: String
        // \u{200A} = hairline space (very skinny space).
        // we use these so that the ranges are still in the right position, but the extra space basically disappears
        newString = baseString.replacingOccurrences(of: "\t ", with: "\u{200A}\u{200A}") // tabs before a space
        newString = newString.replacingOccurrences(of: " \t", with: " \u{200A}") // tabs after a space
        newString = newString.replacingOccurrences(of: "\t@", with: "\u{200A}@") // tabs before @mentions
        newString = newString.replacingOccurrences(of: "\t.", with: "\u{200A}.") // tabs before a space
        newString = newString.replacingOccurrences(of: "\t,", with: "\u{200A},") // tabs cefore a comman
        newString = newString.replacingOccurrences(of: "\n\t\n\t", with: "\u{200A}\u{200A}\n\t") // extra newline-with-tab before a newline-with-tab

        // if the length of the string changes the range-based formatting will break
        guard newString.count == baseString.count else {
            return baseString
        }

        return newString
    }
}
