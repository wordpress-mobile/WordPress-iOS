import Foundation

/// Contains methods for formatting post or comment content for display.
///
@objc class RichContentFormatter: NSObject
{

    /// Encapsulates regex instances used in class methods.
    ///
    struct RegEx
    {
        // Forbidden tags
        static let styleTags = try! NSRegularExpression(pattern: "<style[^>]*?>[\\s\\S]*?</style>", options: .CaseInsensitive)
        static let scriptTags = try! NSRegularExpression(pattern: "<script[^>]*?>[\\s\\S]*?</script>", options: .CaseInsensitive)
        static let tableTags = try! NSRegularExpression(pattern: "<table[^>]*?>[\\s\\S]*?</table>", options: .CaseInsensitive)

        // Normalizaing Paragraphs
        static let divTagsStart = try! NSRegularExpression(pattern: "<div[^>]*>", options: .CaseInsensitive)
        static let divTagsEnd = try! NSRegularExpression(pattern: "</div>", options: .CaseInsensitive)
        static let pTagsStart = try! NSRegularExpression(pattern: "<p[^>]*>\\s*<p[^>]*>", options: .CaseInsensitive)
        static let pTagsEnd = try! NSRegularExpression(pattern: "</p>\\s*</p>", options: .CaseInsensitive)
        static let newLines = try! NSRegularExpression(pattern: "\\n", options: .CaseInsensitive)

        // Inline Styles
        static let styleAttr = try! NSRegularExpression(pattern: "\\s*style=\"[^\"]*\"", options: .CaseInsensitive)

        // Gallery Images
        static let galleryImgTags = try! NSRegularExpression(pattern: "<img[^>]*data-orig-file[^>]*/>", options: .CaseInsensitive)
    }


    /// Formats the specified content string for display. Forbidden HTML tags are
    /// removed, paragraphs are normalized, etc.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///     - isPrivate: Whether the content is from a private blog.
    ///
    /// - Returns: The formatted string.
    ///
    class func formatContentString(string: String, isPrivateStie isPrivate: Bool) -> String {
        guard string.characters.count > 0 else {
            return string
        }

        var content = string
        content = removeForbiddenTags(content)
        content = normalizeParagraphs(content)
        content = removeInlineStyles(content)
        content = (content as NSString).stringByReplacingHTMLEmoticonsWithEmoji() as String
        content = resizeGalleryImageURL(content, isPrivateSite: isPrivate)

        return content
    }


    /// Removes forbidden HTML tags from the specified string.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    class func removeForbiddenTags(string: String) -> String {
        guard string.characters.count > 0 else {
            return string
        }
        var content = string

        content = RegEx.styleTags.stringByReplacingMatchesInString(content,
                                                                   options: .ReportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: "")

        content = RegEx.scriptTags.stringByReplacingMatchesInString(content,
                                                                    options: .ReportCompletion,
                                                                    range: NSRange(location: 0, length: content.characters.count),
                                                                    withTemplate: "")

        content = RegEx.tableTags.stringByReplacingMatchesInString(content,
                                                                   options: .ReportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
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
    class func normalizeParagraphs(string: String) -> String {
        guard string.characters.count > 0 else {
            return string
        }
        var content = string
        let openPTag = "<p>"
        let closePTag = "</p>"

         // Convert div tags to p tags
        content = RegEx.divTagsStart.stringByReplacingMatchesInString(content,
                                                                   options: .ReportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: openPTag)

        content = RegEx.divTagsEnd.stringByReplacingMatchesInString(content,
                                                                    options: .ReportCompletion,
                                                                    range: NSRange(location: 0, length: content.characters.count),
                                                                    withTemplate: closePTag)

        // Remove duplicate/redundant p tags.
        content = RegEx.pTagsStart.stringByReplacingMatchesInString(content,
                                                                   options: .ReportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: openPTag)

        content = RegEx.pTagsEnd.stringByReplacingMatchesInString(content,
                                                                   options: .ReportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: closePTag)

        content = RegEx.newLines.stringByReplacingMatchesInString(content,
                                                                  options: .ReportCompletion,
                                                                  range: NSRange(location: 0, length: content.characters.count),
                                                                  withTemplate: "")

        return content
    }


    /// Removes inline style attributes from the specified content string.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    class func removeInlineStyles(string: String) -> String {
        guard string.characters.count > 0 else {
            return string
        }
        var content = string

        content = RegEx.styleAttr.stringByReplacingMatchesInString(content,
                                                                   options: .ReportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: "")

        return content
    }


    /// Mutates gallery image URLs to be correctly sized.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///     - isPrivate: Whether the content is from a private blog.
    ///
    /// - Returns: The formatted string.
    ///
    class func resizeGalleryImageURL(string: String, isPrivateSite isPrivate: Bool) -> String {
        guard string.characters.count > 0 else {
            return string
        }

        guard let window = UIApplication.sharedApplication().keyWindow else {
            return string
        }

        let imageSize = window.frame.size
        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeApplyAffineTransform(imageSize, CGAffineTransformMakeScale(scale, scale))

        let mContent = NSMutableString(string: string)

        let matches = RegEx.galleryImgTags.matchesInString(mContent as String, options: [], range: NSRange(location: 0, length: mContent.length))

        for match in matches.reverse() {
            let imgElementStr = mContent.substringWithRange(match.range)
            let srcImgURLStr = parseValueForAttribute("src", inElement: imgElementStr)
            let originalImgURLStr = parseValueForAttribute("data-orig-file", inElement: imgElementStr)

            guard let originalURL = NSURL(string: originalImgURLStr) else {
                continue
            }

            var modifiedURL: NSURL
            if isPrivate {
                modifiedURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: originalURL)
            } else {
                modifiedURL = PhotonImageURLHelper.photonURLWithSize(imageSize, forImageURL: originalURL)
            }

            guard let modifiedURLStr = modifiedURL.absoluteString else {
                continue
            }

            let mImageStr = NSMutableString(string: imgElementStr)
            mImageStr.replaceOccurrencesOfString(srcImgURLStr,
                                                 withString: modifiedURLStr,
                                                 options: .LiteralSearch,
                                                 range: NSRange(location: 0, length: imgElementStr.characters.count))

            mContent.replaceCharactersInRange(match.range, withString: mImageStr as String)
        }

        return mContent as String
    }


    /// Parses the specified string for the value of the specified attribute.
    ///
    /// - Parameters:
    ///     - attribute: The attribute whose value should be retrieved.
    ///     - element: The source string to parse.
    ///
    /// - Returns: The value for the attribute or an empty string..
    ///
    class func parseValueForAttribute(attribute: String, inElement element: String) -> String {
        let elementStr = element as NSString
        var value = ""
        let attrStr = "\(attribute)=\""
        let attrRange = elementStr.rangeOfString(attrStr)

        if attrRange.location != NSNotFound {
            let location = attrRange.location + attrRange.length
            let length = elementStr.length - location
            let ending = elementStr.rangeOfString("\"", options: .CaseInsensitiveSearch, range: NSRange(location: location, length: length))
            value = elementStr.substringWithRange(NSRange(location: location, length: ending.location - location))
        }

        return value
    }
}
