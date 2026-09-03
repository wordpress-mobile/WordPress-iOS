import Foundation

/// Contains methods for formatting post or comment content for display.
///
@objc public class RichContentFormatter: NSObject {

    /// Encapsulates regex instances used in class methods.
    ///
    public struct RegEx {
        // Forbidden tags
        static let styleTags = try! NSRegularExpression(pattern: "<style[^>]*?>[\\s\\S]*?(?:</style>|$)", options: .caseInsensitive)
        static let scriptTags = try! NSRegularExpression(pattern: "<script[^>]*?>[\\s\\S]*?(?:</script>|$)", options: .caseInsensitive)
        static let gutenbergComments = try! NSRegularExpression(pattern: "<p><!-- /?wp:.+? /?--></p>[\\n]?", options: .caseInsensitive)

        // Normalizaing Paragraphs
        static let divTagsStart = try! NSRegularExpression(pattern: "<div[^>]*>", options: .caseInsensitive)
        static let divTagsEnd = try! NSRegularExpression(pattern: "</div>", options: .caseInsensitive)
        static let pTagsStart = try! NSRegularExpression(pattern: "<p[^>]*>\\s*<p[^>]*>", options: .caseInsensitive)
        static let pTagsEnd = try! NSRegularExpression(pattern: "</p>\\s*</p>", options: .caseInsensitive)
        static let newLines = try! NSRegularExpression(pattern: "\\n", options: .caseInsensitive)
        static let preTags = try! NSRegularExpression(pattern: "<pre[^>]*>[\\s\\S]*?</pre>", options: .caseInsensitive)
        static let videoTags = try! NSRegularExpression(pattern: "<video(\\s[^>]*)?>", options: .caseInsensitive)

        // Inline Styles
        static let styleAttr = try! NSRegularExpression(pattern: "\\s+style=(?:\"[^\"]*\"|'[^']*')", options: .caseInsensitive)

        // Gallery Images
        public static let galleryImgTags = try! NSRegularExpression(pattern: "<img[^>]*data-orig-file[^>]*/>", options: .caseInsensitive)

        // Trailing BR Tags
        static let trailingBRTags = try! NSRegularExpression(pattern: "(\\s*<br\\s*(/?)\\s*>\\s*)+$", options: .caseInsensitive)

        // Gutenberg Galleries
        static let gutenbergGalleryList = try! NSRegularExpression(pattern: "(<ul[^>]+>)<li[^>]+gallery-item[^>]+><figure><img .+?</figure></li>", options: .caseInsensitive)
        static let gutenbergGalleryListItem = try! NSRegularExpression(pattern: "<li[^>]+gallery-item[^>]+>(<figure><img .+?</figure>)</li>", options: .caseInsensitive)
    }

    /// Removes forbidden HTML tags from the specified string.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func removeForbiddenTags(_ string: String) -> String {
        guard !string.isEmpty else {
            return string
        }
        var content = string

        content = RegEx.styleTags.stringByReplacingMatches(in: content,
                                                           options: .reportCompletion,
                                                           range: NSRange(location: 0, length: content.utf16.count),
                                                           withTemplate: "")

        content = RegEx.scriptTags.stringByReplacingMatches(in: content,
                                                            options: .reportCompletion,
                                                            range: NSRange(location: 0, length: content.utf16.count),
                                                            withTemplate: "")

        content = RegEx.gutenbergComments.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.utf16.count),
                                                                   withTemplate: "")

        return content
    }

    /// Converts DIV tags to P tags and removes duplicate or redundant tags.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func normalizeParagraphs(_ string: String) -> String {
        guard !string.isEmpty else {
            return string
        }
        var content = string
        let openPTag = "<p>"
        let closePTag = "</p>"

        // Convert div tags to p tags
        content = RegEx.divTagsStart.stringByReplacingMatches(in: content,
                                                              options: .reportCompletion,
                                                              range: NSRange(location: 0, length: content.utf16.count),
                                                              withTemplate: openPTag)

        content = RegEx.divTagsEnd.stringByReplacingMatches(in: content,
                                                            options: .reportCompletion,
                                                            range: NSRange(location: 0, length: content.utf16.count),
                                                            withTemplate: closePTag)

        // Remove duplicate/redundant p tags.
        content = RegEx.pTagsStart.stringByReplacingMatches(in: content,
                                                            options: .reportCompletion,
                                                            range: NSRange(location: 0, length: content.utf16.count),
                                                            withTemplate: openPTag)

        content = RegEx.pTagsEnd.stringByReplacingMatches(in: content,
                                                          options: .reportCompletion,
                                                          range: NSRange(location: 0, length: content.utf16.count),
                                                          withTemplate: closePTag)

        content = filterNewLines(content)

        return content
    }

    @objc public class func filterNewLines(_ string: String) -> String {
        var content = string

        var ranges = [NSRange]()
        // We don't want to remove new lines from preformatted tag blocks,
        // so get the ranges of such blocks.
        let matches = RegEx.preTags.matches(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.utf16.count))
        if matches.isEmpty {

            // No blocks found, so we'll parse the whole string.
            ranges.append(NSRange(location: 0, length: content.utf16.count))
        } else {

            // One or more preformatted blocks found, we don't want to remove new lines
            // from them so get the inverse of the preformatted ranges.
            var location = 0
            var length = 0
            for match in matches {
                length = match.range.location - location

                let range = NSRange(location: location, length: length)
                ranges.append(range)
                location = match.range.location + match.range.length
            }

            length = content.utf16.count - location
            ranges.append(NSRange(location: location, length: length))
        }

        // Now remove the new lines from the computed ranges, and return the edited string.
        for range in ranges.reversed() {
            content = RegEx.newLines.stringByReplacingMatches(in: content,
                                                              options: .reportCompletion,
                                                              range: range,
                                                              withTemplate: "")
        }

        return content
    }

    /// Removes inline style attributes from the specified content string.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func removeInlineStyles(_ string: String) -> String {
        guard !string.isEmpty else {
            return string
        }
        var content = string

        content = RegEx.styleAttr.stringByReplacingMatches(in: content,
                                                           options: .reportCompletion,
                                                           range: NSRange(location: 0, length: content.utf16.count),
                                                           withTemplate: "")

        return content
    }

    /// Parses the specified string for the value of the specified attribute.
    ///
    /// - Parameters:
    ///     - attribute: The attribute whose value should be retrieved.
    ///     - element: The source string to parse.
    ///
    /// - Returns: The value for the attribute or an empty string..
    ///
    @objc public class func parseValueForAttribute(_ attribute: String, inElement element: String) -> String {
        // Match the attribute name on a word boundary (so "rc" does not match inside "src")
        // and capture its double-quoted value. A missing closing quote fails to match, so there
        // is no out-of-bounds range to crash on.
        let escaped = NSRegularExpression.escapedPattern(for: attribute)
        guard let regex = try? NSRegularExpression(pattern: "(?<![\\w-])\(escaped)=\"([^\"]*)\"") else {
            return ""
        }
        let range = NSRange(element.startIndex..., in: element)
        guard let match = regex.firstMatch(in: element, range: range),
            let valueRange = Range(match.range(at: 1), in: element)
        else {
            return ""
        }
        return String(element[valueRange])
    }

    /// Removes any trailing BR tags from the end of the specified string.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func removeTrailingBreakTags(_ string: String) -> String {
        guard !string.isEmpty else {
            return string
        }

        var content = string.trim()
        let matches = RegEx.trailingBRTags.matches(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.utf16.count))
        if let match = matches.first, let matchRange = Range(match.range, in: content) {
            content = String(content[..<matchRange.lowerBound])
        }

        return content
    }

    /// Removes unordered list markup from Gutenberg gallery images.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func formatGutenbergGallery(_ string: String) -> String {
        let mString = NSMutableString(string: string)

        // First, remove the gallery UL tags.
        var matches = RegEx.gutenbergGalleryList.matches(in: mString as String, options: [], range: NSRange(location: 0, length: mString.length))
        for match in matches.reversed() {
            if match.numberOfRanges < 2 {
                continue
            }
            mString.replaceCharacters(in: match.range(at: 1), with: "")
        }

        // Now discard the list item markup
        matches = RegEx.gutenbergGalleryListItem.matches(in: mString as String, options: [], range: NSRange(location: 0, length: mString.length))
        for match in matches.reversed() {
            if match.numberOfRanges < 2 {
                continue
            }
            let image = mString.substring(with: match.range(at: 1))
            mString.replaceCharacters(in: match.range, with: image)
        }

        return mString as String
    }

    /// Format video tags to ensure they have the desired markup.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func formatVideoTags(_ string: String) -> String {
        let mString = NSMutableString(string: string)

        // Find video tags.
        let matches = RegEx.videoTags.matches(in: mString as String, options: [], range: NSRange(location: 0, length: mString.length))

        // For each video tag, check for controls attribute
        for match in matches.reversed() {
            let tag = mString.substring(with: match.range) as NSString
            let controls = "\\scontrols(?![\\w-])"
            if tag.range(of: controls, options: [.regularExpression, .caseInsensitive]).location == NSNotFound {
                // Insert `controls` after the `<video` opening, preserving the tag's casing.
                mString.insert(" controls", at: match.range.location + 6)
            }
        }

        return mString as String
    }
}
