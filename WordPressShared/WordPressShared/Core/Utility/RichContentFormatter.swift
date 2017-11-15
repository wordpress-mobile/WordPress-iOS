import Foundation

/// Contains methods for formatting post or comment content for display.
///
@objc public class RichContentFormatter: NSObject {

    /// Encapsulates regex instances used in class methods.
    ///
    public struct RegEx {
        // Forbidden tags
        static let styleTags = try! NSRegularExpression(pattern: "<style[^>]*?>[\\s\\S]*?</style>", options: .caseInsensitive)
        static let scriptTags = try! NSRegularExpression(pattern: "<script[^>]*?>[\\s\\S]*?</script>", options: .caseInsensitive)
        static let tableTags = try! NSRegularExpression(pattern: "<table[^>]*?>[\\s\\S]*?</table>", options: .caseInsensitive)

        // Normalizaing Paragraphs
        static let divTagsStart = try! NSRegularExpression(pattern: "<div[^>]*>", options: .caseInsensitive)
        static let divTagsEnd = try! NSRegularExpression(pattern: "</div>", options: .caseInsensitive)
        static let pTagsStart = try! NSRegularExpression(pattern: "<p[^>]*>\\s*<p[^>]*>", options: .caseInsensitive)
        static let pTagsEnd = try! NSRegularExpression(pattern: "</p>\\s*</p>", options: .caseInsensitive)
        static let newLines = try! NSRegularExpression(pattern: "\\n", options: .caseInsensitive)
        static let preTags = try! NSRegularExpression(pattern: "<pre[^>]*>[\\s\\S]*?</pre>", options: .caseInsensitive)

        // Inline Styles
        static let styleAttr = try! NSRegularExpression(pattern: "\\s*style=\"[^\"]*\"", options: .caseInsensitive)

        // Gallery Images
        static let galleryImgTags = try! NSRegularExpression(pattern: "<img[^>]*data-orig-file[^>]*/>", options: .caseInsensitive)
        static let galleryStartIdentifier = "WPGalleryStartIdentifier"
        static let galleryEndIdentifier = "WPGalleryEndIdentifier"
        static let galleryDivStart = try! NSRegularExpression(pattern: "<div[^>]*?\(galleryStartIdentifier)[^>]*?>", options: .caseInsensitive)
        static let galleryDivEnd = try! NSRegularExpression(pattern: "</div[^>]*?\(galleryEndIdentifier)[^>]*?>", options: .caseInsensitive)

        // Trailing BR Tags
        static let trailingBRTags = try! NSRegularExpression(pattern: "(\\s*<br\\s*(/?)\\s*>\\s*)+$", options: .caseInsensitive)
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
    public class func formatContentString(_ string: String, isPrivateSite isPrivate: Bool) -> String {
        guard string.count > 0 else {
            return string
        }

        var content = string
        content = removeForbiddenTags(content)
        content = normalizeGallery(content)
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
    public class func removeForbiddenTags(_ string: String) -> String {
        guard string.count > 0 else {
            return string
        }
        var content = string

        content = RegEx.styleTags.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.count),
                                                                   withTemplate: "")

        content = RegEx.scriptTags.stringByReplacingMatches(in: content,
                                                                    options: .reportCompletion,
                                                                    range: NSRange(location: 0, length: content.count),
                                                                    withTemplate: "")

        content = RegEx.tableTags.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.count),
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
    public class func normalizeParagraphs(_ string: String) -> String {
        guard string.count > 0 else {
            return string
        }
        var content = string
        let openPTag = "<p>"
        let closePTag = "</p>"

         // Convert div tags to p tags
        content = RegEx.divTagsStart.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.count),
                                                                   withTemplate: openPTag)

        content = RegEx.divTagsEnd.stringByReplacingMatches(in: content,
                                                                    options: .reportCompletion,
                                                                    range: NSRange(location: 0, length: content.count),
                                                                    withTemplate: closePTag)

        // Remove duplicate/redundant p tags.
        content = RegEx.pTagsStart.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.count),
                                                                   withTemplate: openPTag)

        content = RegEx.pTagsEnd.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.count),
                                                                   withTemplate: closePTag)

        content = filterNewLines(content)

        return content
    }

    
    /// Converts DIV with class gallery class to gallery tags
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    public class func normalizeGallery(_ string : String) -> String {
        
        guard string.count > 0 else {
            return string
        }
        
        //Types of WP Galleries
        let iconGallery = "class='gallery"
        let tiledGallery = "class=\"tiled-gallery"
        
        //Gallery Tag for identification
        let galleryStart = "<gallery>"
        let galleryEnd = "</gallery>"
        
        var content = string
        
        //Scan and Insert Indentifier for Gallery Start and End
        content = scanForGalleryBy(galleryType: iconGallery, inString: content)
        content = scanForGalleryBy(galleryType: tiledGallery, inString: content)
        
        //Replace Div with Gallery tag
        content = RegEx.galleryDivStart.stringByReplacingMatches(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.count), withTemplate: galleryStart)
        content = RegEx.galleryDivEnd.stringByReplacingMatches(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.count), withTemplate: galleryEnd)
        
        return content
    }
    
    private class func scanForGalleryBy(galleryType : String, inString : String) -> String {
        
        let galleryScanner = Scanner(string: inString)
        galleryScanner.charactersToBeSkipped = nil
        
        let divStr = "div"
        
        var str = ""
        var tempStr: NSString? = ""
        
        var divCounter = 0
        var galleriesFound : Int = 0
        
        while !galleryScanner.isAtEnd {
            
            if galleriesFound <= 0 {
                //check for gallery
                galleryScanner.scanUpTo(galleryType, into: &tempStr)
                
                if let tempStr = tempStr {
                    str += tempStr as String
                }
                
                tempStr = ""
                if galleryScanner.isAtEnd {
                    break //nothing to see here
                } else {
                    galleriesFound += 1
                    divCounter += 1
                }
                
                str += galleryType
                str += RegEx.galleryStartIdentifier
                galleryScanner.scanLocation += Int(galleryType.count)
                
            } else {
                
                //gallery found, proceed to find divs
                galleryScanner.scanUpTo(divStr, into: &tempStr)
                
                if let tempStr = tempStr {
                    str += tempStr as String
                }
                
                tempStr = ""
                if galleryScanner.isAtEnd {
                    break //nothing to see here
                }
                
                if str.last == "/" {
                    divCounter -= 1
                } else if str.last == "<" {
                    divCounter += 1
                }
                
                galleryScanner.scanLocation += divStr.count
                str += divStr
                
                if divCounter == 0 {
                    galleriesFound -= 1
                    str += RegEx.galleryEndIdentifier
                }
            }
        }
        
        return str
    }
    
    public class func filterNewLines(_ string: String) -> String {
        var content = string

        var ranges = [NSRange]()
        // We don't want to remove new lines from preformatted tag blocks,
        // so get the ranges of such blocks.
        let matches = RegEx.preTags.matches(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.count))
        if matches.count == 0 {

            // No blocks found, so we'll parse the whole string.
            ranges.append(NSRange(location: 0, length: content.count))

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

            length = content.count - location
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
    public class func removeInlineStyles(_ string: String) -> String {
        guard string.count > 0 else {
            return string
        }
        var content = string

        content = RegEx.styleAttr.stringByReplacingMatches(in: content,
                                                                   options: .reportCompletion,
                                                                   range: NSRange(location: 0, length: content.count),
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
    public class func resizeGalleryImageURL(_ string: String, isPrivateSite isPrivate: Bool) -> String {
        guard string.count > 0 else {
            return string
        }

        let imageSize = UIScreen.main.bounds.size
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
                                         range: NSRange(location: 0, length: imgElementStr.count))

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
    public class func parseValueForAttribute(_ attribute: String, inElement element: String) -> String {
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


    /// Removes any trailing BR tags from the end of the specified string.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///
    /// - Returns: The formatted string.
    ///
    public class func removeTrailingBreakTags(_ string: String) -> String {
        guard string.count > 0 else {
            return string
        }
        var content = string.trim()
        let matches = RegEx.trailingBRTags.matches(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.count))
        if let match = matches.first {
            let index = content.index(content.startIndex, offsetBy: match.range.location)
            content = content.substring(to: index)
        }

        return content
    }
}
