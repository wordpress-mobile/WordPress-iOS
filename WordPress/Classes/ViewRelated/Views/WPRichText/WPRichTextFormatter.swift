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
    func attributedStringFromHTMLString(_ string:String, defaultDocumentAttributes:[String : AnyObject]?) throws -> NSAttributedString? {
        // Process the html in the string. Replace attachment tags with placeholders, etc.
        let parsed = processAndExtractTags(string)
        let parsedString = parsed.parsedString
        let attachments = parsed.attachments

        // Now create an attributed string from the processed html
        guard let data = parsedString.data(using: String.Encoding.utf8) else {
            return nil
        }

        var options: [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8 as AnyObject,
            ]

        if let defaultDocumentAttributes = defaultDocumentAttributes {
            options[NSDefaultAttributesDocumentAttribute] = defaultDocumentAttributes as AnyObject?
        }

        var attrString = try NSMutableAttributedString(data: data, options: options, documentAttributes: nil)

        // Fix blockquote indentation and remove blockquote markers.
        attrString = fixBlockquoteIndentation(attrString)

        // Replace attachment identifiers with the actual attachments.
        for attachment in attachments {
            let str = attrString.string as NSString
            let range = str.range(of: attachment.identifier)
            let attributes = attrString.attributes(at: range.location, effectiveRange: nil)

            let attachmentString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: attachmentString.length))

            attrString.replaceCharacters(in: range, with: attachmentString)
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
    func fixBlockquoteIndentation(_ attrString: NSMutableAttributedString) -> NSMutableAttributedString {

        let str = attrString.string
        let regex = try! NSRegularExpression(pattern: type(of: self).blockquoteIdentifier, options: .caseInsensitive)
        let matches = regex.matches(in: str, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, str.characters.count))

        for match: NSTextCheckingResult in matches.reversed() {

            // Indent the blockquote
            // Note that the marker is not guarenteed to have the exact same paragraph style as the quoted text it marks.
            // To compensate, we make our index match the first character of the quote text rather than the marker itself.
            let index = match.range.location + match.range.length + 1
            var effectiveRange = NSRange()
            let pStyle = attrString.attribute(NSParagraphStyleAttributeName, at: index, effectiveRange: &effectiveRange) as? NSParagraphStyle ?? NSParagraphStyle.default

            let mParaStyle = NSMutableParagraphStyle()
            mParaStyle.setParagraphStyle(pStyle)
            mParaStyle.headIndent = blockquoteIndentation
            mParaStyle.firstLineHeadIndent = blockquoteIndentation

            attrString.addAttribute(NSParagraphStyleAttributeName, value: mParaStyle, range: effectiveRange)

            // Delete the marker
            attrString.deleteCharacters(in: match.range)
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
    func processAndExtractTags(_ string: String) -> ParsedSource {
        var attachments = [WPTextAttachment]()

        guard string.characters.count > 0 else {
            return (string, attachments)
        }

        var processedString = ""
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil

        // Scan for tags we need to flag or replace appending scanned substrings
        // to `parsedString`
        while !scanner.isAtEnd {

            var tempString: NSString? = ""

            // Scan up to the first tag after the current scanLocation
            scanner.scanUpTo("<", into: &tempString)
            processedString += tempString! as String

            // The scanner will scan to the end of the string if a tag isn't found.
            if scanner.isAtEnd {
                // We're done actually.
                break
            }

            // Scan to get the name of the tag and advance one character to
            // omit the opening <.
            let tagStartLocation = scanner.scanLocation
            var tagName: NSString? = ""
            let charSet = CharacterSet(charactersIn: " >")
            scanner.scanLocation += 1
            scanner.scanUpToCharacters(from: charSet, into: &tagName)
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
    func processorForTagName(_ tagName: String) -> HtmlTagProcessor? {
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
    func extractTag(_ scanner: Scanner) -> (Bool, String) {
        var parsedString = ""
        var tempString: NSString? = ""
        var success = false
        let endTag = includesEndTag ? "</\(tagName)>" : ">"

        scanner.scanUpTo(endTag, into: &tempString)
        parsedString += tempString! as String

        if !scanner.isAtEnd {
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
    func process(_ scanner: Scanner) -> (String, WPTextAttachment?) {
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
    override func process(_ scanner: Scanner) -> (String, WPTextAttachment?) {
        var (matched, parsedString) = extractTag(scanner)

        // No matches? Just bail.
        if !matched {
            return (parsedString, nil)
        }

        // If the blockquote contains no paragraphs just insert the marker after
        // the tag.
        if !parsedString.contains("<p>") {
            var str = parsedString as NSString
            let location = "<\(tagName)>".characters.count
            str = str.replacingCharacters(in: NSRange(location: location, length: 0), with: WPRichTextFormatter.blockquoteIdentifier) as NSString
            parsedString = str as String
            return (parsedString, nil)
        }

        // For each paragraph contained by the blockquote, insert a marker
        // after the opening paragraph tag.
        let marker = "<p>" + WPRichTextFormatter.blockquoteIdentifier
        var str = ""
        var tempStr: NSString? = ""
        let paragraphScanner = Scanner(string: parsedString)
        paragraphScanner.charactersToBeSkipped = nil

        while !paragraphScanner.isAtEnd {
            paragraphScanner.scanUpTo("<p>", into: &tempStr)

            str += tempStr as! String
            tempStr = ""
            if paragraphScanner.isAtEnd {
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
    override func process(_ scanner: Scanner) -> (String, WPTextAttachment?) {
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

    /// Replaces extracted tags with markers.
    ///
    override func process(_ scanner: Scanner) -> (String, WPTextAttachment?) {
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
    func attachmentForHtml(_ html: String, identifier: String) -> WPTextAttachment? {

        let attrs = attributesFromTag(html)

        let src = attrs["src"] ?? ""
        let textAttachment = WPTextAttachment(tagName: tagName, identifier: identifier, src: src)
        textAttachment.attributes = attrs
        textAttachment.html = html

        if let widthStr = attrs["width"] {
            if widthStr.contains("%") {
                textAttachment.width = CGFloat.greatestFiniteMagnitude
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
    func attributesFromTag(_ html: String) -> [String: String] {
        var scanner = Scanner(string: html)
        let quoteCharacters = CharacterSet(charactersIn: "\"'")
        var attrs = [String: String]()

        // For most attachments we're only interested in the attributes in the opening tag.
        // We can skip a closing tag and any child elements.
        var tag: NSString? = ""
        scanner.scanUpTo(">", into: &tag)
        scanner = Scanner(string: tag as! String)
        scanner.charactersToBeSkipped = quoteCharacters
        let charSet = CharacterSet.whitespaces

        while !scanner.isAtEnd {
            var tempString: NSString? = ""
            scanner.scanUpToCharacters(from: charSet, into: &tempString)

            if let str = tempString, str.contains("=") {
                let attrScanner = Scanner(string: str as String)
                attrScanner.charactersToBeSkipped = quoteCharacters

                var key: NSString? = ""
                var value: NSString? = ""

                attrScanner.scanUpTo("=", into: &key)
                attrScanner.scanLocation += 1
                attrScanner.scanUpToCharacters(from: quoteCharacters, into: &value)

                attrs.updateValue(value as! String, forKey: key as! String)
            }

            if !scanner.isAtEnd {
                scanner.scanLocation += 1
            }

        }

        return attrs
    }

}
