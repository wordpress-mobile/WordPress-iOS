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
        static let styleTags = try! NSRegularExpression(pattern: "<style[^>]*?>[\\s\\S]*?</style>", options: .caseInsensitive)
        static let scriptTags = try! NSRegularExpression(pattern: "<script[^>]*?>[\\s\\S]*?</script>", options: .caseInsensitive)
        static let tableTags = try! NSRegularExpression(pattern: "<table[^>]*?>[\\s\\S]*?</table>", options: .caseInsensitive)

        // Normalizaing Paragraphs
        static let divTagsStart = try! NSRegularExpression(pattern: "<div[^>]*>", options: .caseInsensitive)
        static let divTagsEnd = try! NSRegularExpression(pattern: "</div>", options: .caseInsensitive)
        static let pTagsStart = try! NSRegularExpression(pattern: "<p[^>]*>\\s*<p[^>]*>", options: .caseInsensitive)
        static let pTagsEnd = try! NSRegularExpression(pattern: "</p>\\s*</p>", options: .caseInsensitive)

        // Inline Styles
        static let styleAttr = try! NSRegularExpression(pattern: "\\s*style=\"[^\"]*\"", options: .caseInsensitive)

        // Gallery Images
        static let galleryImgTags = try! NSRegularExpression(pattern: "<img[^>]*data-orig-file[^>]*/>", options: .caseInsensitive)
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
    class func formatContentString(_ string: String, isPrivateStie isPrivate: Bool) -> String {
        guard string.characters.count > 0 else {
            return string
        }

        var content = string
        content = removeForbiddenTags(content)
        content = normalizeParagraphs(content)
        content = removeInlineStyles(content)
        content = (content as NSString).replacingHTMLEmoticonsWithEmoji() as String
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
    class func removeForbiddenTags(_ string: String) -> String {
        guard string.characters.count > 0 else {
            return string
        }
        var content = string

        content = RegEx.styleTags.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: "")

        content = RegEx.scriptTags.stringByReplacingMatches(in: content,
                                                                    options: .reportCompletion,
                                                                    range: NSRange(location: 0, length: content.characters.count),
                                                                    withTemplate: "")

        content = RegEx.tableTags.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
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
    class func normalizeParagraphs(_ string: String) -> String {
        guard string.characters.count > 0 else {
            return string
        }
        var content = string
        let openPTag = "<p>"
        let closePTag = "</p>"

         // Convert div tags to p tags
        content = RegEx.divTagsStart.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: openPTag)

        content = RegEx.divTagsEnd.stringByReplacingMatches(in: content,
                                                                    options: .reportCompletion,
                                                                    range: NSRange(location: 0, length: content.characters.count),
                                                                    withTemplate: closePTag)

        // Remove duplicate/redundant p tags.
        content = RegEx.pTagsStart.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: openPTag)

        content = RegEx.pTagsEnd.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.characters.count),
                                                                   withTemplate: closePTag)

        return content
    }


    /// Removes inline style attributes from the specified content string.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    class func removeInlineStyles(_ string: String) -> String {
        guard string.characters.count > 0 else {
            return string
        }
        var content = string

        content = RegEx.styleAttr.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
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
    class func resizeGalleryImageURL(_ string: String, isPrivateSite isPrivate: Bool) -> String {
        guard string.characters.count > 0 else {
            return string
        }

        guard let window = UIApplication.shared.keyWindow else {
            return string
        }

        let imageSize = window.frame.size
        let scale = UIScreen.main.scale
        let scaledSize = imageSize.applying(CGAffineTransform(scaleX: scale, y: scale))

        let mContent = NSMutableString(string: string)

        let matches = RegEx.galleryImgTags.matches(in: mContent as String, options: [], range: NSRange(location: 0, length: mContent.length))

        for match in matches.reversed() {
            let imgElementStr = mContent.substring(with: match.range)
            let srcImgURLStr = parseValueForAttribute("src", inElement: imgElementStr)
            let originalImgURLStr = parseValueForAttribute("data-orig-file", inElement: imgElementStr)

            guard let originalURL = URL(string: originalImgURLStr) else {
                continue
            }

            var modifiedURL: URL
            if isPrivate {
                modifiedURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: originalURL)
            } else {
                modifiedURL = PhotonImageURLHelper.photonURL(with: imageSize, forImageURL: originalURL)
            }

            guard modifiedURL.absoluteString.isEmpty() == false else {
                continue
            }

            let mImageStr = NSMutableString(string: imgElementStr)
            mImageStr.replaceOccurrences(of: srcImgURLStr,
                                         with: modifiedURL.absoluteString,
                                         options: .literal,
                                         range: NSRange(location: 0, length: imgElementStr.characters.count))

            mContent.replaceCharacters(in: match.range, with: mImageStr as String)
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
    class func parseValueForAttribute(_ attribute: String, inElement element: String) -> String {
        let elementStr = element as NSString
        var value = ""
        let attrStr = "\(attribute)=\""
        let attrRange = elementStr.range(of: attrStr)

        if attrRange.location != NSNotFound {
            let location = attrRange.location + attrRange.length
            let length = elementStr.length - location
            let ending = elementStr.range(of: "\"", options: .caseInsensitive, range: NSRange(location: location, length: length))
            value = elementStr.substring(with: NSRange(location: location, length: ending.location - location))
        }

        return value
    }
}
