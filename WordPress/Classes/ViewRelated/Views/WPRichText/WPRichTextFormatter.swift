import Foundation
import UIKit


/// Responsible for taking an HTML formatted string and parsing/reformatting certain
/// HTML tags that require special handling before the text is shown in a UITextView.
///
class WPRichTextFormatter
{

    typealias ParsedSource = (parsedString:String, attachments:[WPTextAttachment])
    static let blockquoteIdentifier = "WPBLOCKQUOTEIDENTIFIER"
    let blockquoteIndentation = CGFloat(20.0)

    /// An array of HTMLTagProcessors
    ///
    lazy var tags:[HtmlTagProcessor] = {
        return [
            BlockquoteTagProcessor(),
            ListTagProcessor(tagName: "ol", includesEndTag: true),
            ListTagProcessor(tagName: "ul", includesEndTag: true),
            AttachmentTagProcessor(tagName: "img", includesEndTag: false),
            AttachmentTagProcessor(tagName: "iframe", includesEndTag: true),
            AttachmentTagProcessor(tagName: "video", includesEndTag: true),
            AttachmentTagProcessor(tagName: "audio", includesEndTag: true),
            AttachmentTagProcessor(tagName: "embed", includesEndTag: false),
        ]
    }()

    /// An array of tag names that the formatter can process.
    ///
    lazy var tagNames:[String] = {
        return self.tags.map { tag -> String in
            return tag.tagName
        }
    }()


    /// Converts the specified HTML formatted string to an NSAttributedString.
    ///
    /// - Parameters:
    ///     - string: The string to convert to an NSAttributedString.
    ///     - defaultDocumentAttributes: Any default document attributes that should be applied to the attributed string.
    ///
    /// - Returns: An NSAttributedString optional.
    ///
    func attributedStringFromHTMLString(string:String, defaultDocumentAttributes:[String : AnyObject]?) throws -> NSAttributedString? {
        // Process the html in the string. Replace attachment tags with placeholders, etc.
        let parsed = processAndExtractTags(string)
        let parsedString = parsed.parsedString
        let attachments = parsed.attachments

        // Now create an attributed string from the processed html
        guard let data = parsedString.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }

        var options: [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding,
            ]

        if let defaultDocumentAttributes = defaultDocumentAttributes {
            options[NSDefaultAttributesDocumentAttribute] = defaultDocumentAttributes
        }

        var attrString = try NSMutableAttributedString(data: data, options: options, documentAttributes: nil)

        // Fix blockquote indentation and remove blockquote markers.
        attrString = fixBlockquoteIndentation(attrString)

        // Replace attachment identifiers with the actual attachments.
        for attachment in attachments {
            let str = attrString.string as NSString
            let range = str.rangeOfString(attachment.identifier)
            let attributes = attrString.attributesAtIndex(range.location, effectiveRange: nil)

            let attachmentString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: attachmentString.length))

            attrString.replaceCharactersInRange(range, withAttributedString: attachmentString)
        }

        return NSAttributedString(attributedString: attrString)
    }


    /// Converting an HTML formatted string to an NSAttributedString results in
    /// blockquotes being ignored. This method finds the blockquote markers
    /// in the supplied NSAttributedString, reapplies indentation to the blockquote's
    /// paragraph, and removes the blockquote markers.
    ///
    /// - Parameters:
    ///     - attrString: The mutable attributed to modify.
    ///
    /// - Returns: The modified attribute string.
    ///
    func fixBlockquoteIndentation(attrString: NSMutableAttributedString) -> NSMutableAttributedString {

        let str = attrString.string
        let regex = try! NSRegularExpression(pattern: self.dynamicType.blockquoteIdentifier, options: .CaseInsensitive)
        let matches = regex.matchesInString(str, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, str.characters.count))

        for match: NSTextCheckingResult in matches.reverse() {

            // Indent the blockquote
            // Note that the marker is not guarenteed to have the exact same paragraph style as the quoted text it marks.
            // To compensate, we make our index match the first character of the quote text rather than the marker itself.
            let index = match.range.location + match.range.length + 1
            var effectiveRange = NSRange()
            let pStyle = attrString.attribute(NSParagraphStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange) as? NSParagraphStyle ?? NSParagraphStyle.defaultParagraphStyle()

            let mParaStyle = NSMutableParagraphStyle()
            mParaStyle.setParagraphStyle(pStyle)
            mParaStyle.headIndent = blockquoteIndentation
            mParaStyle.firstLineHeadIndent = blockquoteIndentation

            attrString.addAttribute(NSParagraphStyleAttributeName, value: mParaStyle, range: effectiveRange)

            // Delete the marker
            attrString.deleteCharactersInRange(match.range)
        }

        return attrString
    }


    /// Processes the supplied string, scanning for HTML tags that need special
    /// handling.
    ///
    /// - Parameters:
    ///     - string: The string to process.
    ///
    /// - Returns: An instance of ParsedSource containing the modified string and any attachments.
    ///
    func processAndExtractTags(string: String) -> ParsedSource {
        var attachments = [WPTextAttachment]()

        guard string.characters.count > 0 else {
            return (string, attachments)
        }

        var processedString = ""
        let scanner = NSScanner(string: string)
        scanner.charactersToBeSkipped = nil

        // Scan for tags we need to flag or replace appending scanned substrings
        // to `parsedString`
        while !scanner.atEnd {

            var tempString: NSString? = ""

            // Scan up to the first tag after the current scanLocation
            scanner.scanUpToString("<", intoString: &tempString)
            processedString += tempString! as String

            // The scanner will scan to the end of the string if a tag isn't found.
            if scanner.atEnd {
                // We're done actually.
                break
            }

            // Scan to get the name of the tag and advance one character to
            // omit the opening <.
            let tagStartLocation = scanner.scanLocation
            var tagName: NSString? = ""
            let charSet = NSCharacterSet(charactersInString: " >")
            scanner.scanLocation += 1
            scanner.scanUpToCharactersFromSet(charSet, intoString: &tagName)
            scanner.scanLocation = tagStartLocation

            // Process tags of interest.
            if let tag = processorForTagName(tagName as! String) {

                let (string, attachment) = tag.process(scanner)
                processedString += string

                if let attachment = attachment {
                    attachments.append(attachment)
                }

            } else {
                // We're not handling this tag. Advance the scanner one character
                // and append the "<" to our parsed string. This prevents
                // the tag from being re-scanned on the next pass.
                processedString += "<"
                scanner.scanLocation += 1
            }
        }

        return (processedString, attachments)
    }


    /// Returns the html processor that handles the specified tag.
    ///
    /// - Parameters:
    ///     - tagName: The name of an HTML tag.
    ///
    /// - Returns: An HtmlTagProcessor optional.
    ///
    func processorForTagName(tagName: String) -> HtmlTagProcessor? {
        return tags.filter({ (item) -> Bool in
            item.tagName == tagName
        }).first
    }

}


/// A base class for processing HTML tags.  Logic for specific tags
/// should be implemented in subclasses of this class.
///
class HtmlTagProcessor
{
    let tagName: String
    let includesEndTag: Bool

    init(tagName: String, includesEndTag: Bool) {
        self.tagName = tagName
        self.includesEndTag = includesEndTag
    }


    /// Tells the passed scanner object to extract the tag represented by
    /// the `tagName` property.
    /// Note: Proper usage *requires* that scanner.scanLocation be at the beginning of the specified tag
    ///
    /// - Parameters:
    ///     - scanner: An instance of NSScanner
    ///
    /// - Returns: A tuple: (Bool, String) where the Bool represents success and the string is the parsed HTML.
    ///
    func extractTag(scanner: NSScanner) -> (Bool, String) {
        var parsedString = ""
        var tempString: NSString? = ""
        var success = false
        let endTag = includesEndTag ? "</\(tagName)>" : ">"

        scanner.scanUpToString(endTag, intoString: &tempString)
        parsedString += tempString! as String

        if !scanner.atEnd {
            success = true

            // Add the closing tag since it wasn't included in the scanned string.
            parsedString += endTag

            // Advance the scanner to account for the closing tag.
            scanner.scanLocation += endTag.characters.count
        }

        return (success, parsedString)
    }


    /// Subclasses should override this method to process the HTML extracted via
    /// the extractTag method.
    ///
    /// - Parameters:
    ///     - scanner: An NSScanner instance.
    ///
    /// - Returns: A (String, WPTextAttachment?) tuple where the string is either
    /// a placeholder for the WPTextAttachment instance, or the modified extracted HTML.
    ///
    func process(scanner: NSScanner) -> (String, WPTextAttachment?) {
        return ("", nil)
    }

}


/// Encapsulates the logic for processing blockquote tags.
///
class BlockquoteTagProcessor: HtmlTagProcessor
{

    init() {
        super.init(tagName: "blockquote", includesEndTag: true)
    }


    /// Inserts markers identifiying a blockquote paragraph.
    ///
    override func process(scanner: NSScanner) -> (String, WPTextAttachment?) {
        var (matched, parsedString) = extractTag(scanner)

        // No matches? Just bail.
        if !matched {
            return (parsedString, nil)
        }

        // If the blockquote contains no paragraphs just insert the marker after
        // the tag.
        if !parsedString.containsString("<p>") {
            var str = parsedString as NSString
            let location = "<\(tagName)>".characters.count
            str = str.stringByReplacingCharactersInRange(NSRange(location: location, length: 0), withString: WPRichTextFormatter.blockquoteIdentifier)
            parsedString = str as String
            return (parsedString, nil)
        }

        // For each paragraph contained by the blockquote, insert a marker
        // after the opening paragraph tag.
        let marker = "<p>" + WPRichTextFormatter.blockquoteIdentifier
        var str = ""
        var tempStr: NSString? = ""
        let paragraphScanner = NSScanner(string: parsedString)
        paragraphScanner.charactersToBeSkipped = nil

        while !paragraphScanner.atEnd {
            paragraphScanner.scanUpToString("<p>", intoString: &tempStr)

            str += tempStr as! String
            tempStr = ""
            if paragraphScanner.atEnd {
                break
            }

            paragraphScanner.scanLocation += 3
            str += marker
        }
        parsedString = str

        return (parsedString, nil)
    }
}


/// Handles processing list tags. Basically we just want to
/// correct the line spacing following a list. Appending
/// a <br> does the trick.
///
class ListTagProcessor: HtmlTagProcessor
{
    override func process(scanner: NSScanner) -> (String, WPTextAttachment?) {
        var (matched, parsedString) = extractTag(scanner)

        // No matches? Just bail.
        if !matched {
            return (parsedString, nil)
        }

        parsedString = parsedString + "<br>"

        return (parsedString, nil)
    }
}


/// Handles processing tags representing external content, i.e. attachments.
/// The HTML for the attachment is extracted and replaced with a string marker.
///
class AttachmentTagProcessor: HtmlTagProcessor
{
    let textAttachmentIdentifier = "WPTEXTATTACHMENTIDENTIFIER"
    static let attributeRegex = try! NSRegularExpression(pattern: "([a-zA-Z-]+)=(?:\"|')([^\"']+)(?:\"|')", options: .CaseInsensitive)

    /// Replaces extracted tags with markers.
    ///
    override func process(scanner: NSScanner) -> (String, WPTextAttachment?) {
        let (matched, parsedString) = extractTag(scanner)

        if !matched {
            return (parsedString, nil)
        }

        let identifier = textAttachmentIdentifier + tagName + String(scanner.scanLocation)
        let attachment = attachmentForHtml(parsedString, identifier: identifier)

        return (identifier, attachment)
    }


    /// Createa a WPTextAttachment instance representing the specified HTML string.
    ///
    /// - Parameters:
    ///     - html: The html string.
    ///     - identifier: The string identifier for the attachment.
    ///
    func attachmentForHtml(html: String, identifier: String) -> WPTextAttachment? {

        let attrs = attributesFromTag(html)

        var src = attrs["src"] ?? ""
        src = src.stringByDecodingXMLCharacters()
        let textAttachment = WPTextAttachment(tagName: tagName, identifier: identifier, src: src)
        textAttachment.attributes = attrs
        textAttachment.html = html

        if let widthStr = attrs["width"] {
            if widthStr.containsString("%") {
                textAttachment.width = CGFloat.max
            } else if let width = Float(widthStr) {
                textAttachment.width = CGFloat(width)
            }
        }

        if let heightStr = attrs["height"],
            let height = Float(heightStr) {
            textAttachment.height = CGFloat(height)
        }

        return textAttachment
    }


    /// Parses attributes from the specified html tag.  If the tag has child tags
    /// only the parent tag is considered.
    ///
    /// - Parameters:
    ///     - html: The HTML formatted string.
    ///
    /// - Returns: A [String: String] dicitionary of attributes.
    ///
    func attributesFromTag(html: String) -> [String: String] {
        let scanner = NSScanner(string: html)
        var attrs = [String: String]()

        // For most attachments we're only interested in the attributes in the opening tag.
        // We can skip a closing tag and any child elements.
        var tag: NSString? = ""
        scanner.scanUpToString(">", intoString: &tag)

        let regex = self.dynamicType.attributeRegex

        let matches = regex.matchesInString(tag as! String, options: .ReportCompletion, range: NSRange(location: 0, length: tag!.length))
        for match in matches {
            let keyRange = match.rangeAtIndex(1)
            let valueRange = match.rangeAtIndex(2)

            let key = tag!.substringWithRange(keyRange)
            let value = tag!.substringWithRange(valueRange)

            attrs.updateValue(value, forKey: key)
        }

        return attrs
    }

}
