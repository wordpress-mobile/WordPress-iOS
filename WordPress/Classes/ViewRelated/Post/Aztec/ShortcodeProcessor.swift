import Foundation
import Aztec
/// Struct to represent a WordPress shortcode
/// More details here: https://codex.wordpress.org/Shortcode and here: https://en.support.wordpress.com/shortcodes/
///
public struct Shortcode {
    public enum TagType {
        case selfClosing
        case closed
        case single
    }

    public let tag: String
    public let attributes: HTMLAttributes
    public let type: TagType
    public let content: String?
}

/// A class that processes a string and replace the designated shortcode for the replacement provided strings
///
open class ShortcodeProcessor: RegexProcessor {

    public typealias ShortcodeReplacer = (Shortcode) -> String

    let tag: String

    /// Regular expression to detect attributes
    /// Capture groups:
    ///
    /// 1. An extra `[` to allow for escaping shortcodes with double `[[]]`
    /// 2. The shortcode name
    /// 3. The shortcode argument list
    /// 4. The self closing `/`
    /// 5. The content of a shortcode when it wraps some content.
    /// 6. The closing tag.
    /// 7. An extra `]` to allow for escaping shortcodes with double `[[]]`
    ///
    static func makeShortcodeRegex(tag: String) -> NSRegularExpression {
        let pattern = "\\[(\\[?)(\(tag))(?![\\w-])([^\\]\\/]*(?:\\/(?!\\])[^\\]\\/]*)*?)(?:(\\/)\\]|\\](?:([^\\[]*(?:\\[(?!\\/\\2\\])[^\\[]*)*)(\\[\\/\\2\\]))?)(\\]?)"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex
    }

    enum CaptureGroups: Int {
        case all = 0
        case extraOpen
        case name
        case arguments
        case selfClosingElement
        case content
        case closingTag
        case extraClose

        static let allValues = [.all, extraOpen, .name, .arguments, .selfClosingElement, .content, .closingTag, .extraClose]
    }

    public init(tag: String, replacer: @escaping ShortcodeReplacer) {
        self.tag = tag
        let regex = ShortcodeProcessor.makeShortcodeRegex(tag: tag)
        let regexReplacer = { (match: NSTextCheckingResult, text: String) -> String? in
            guard match.numberOfRanges == CaptureGroups.allValues.count else {
                return nil
            }
            var attributes = HTMLAttributes(named: [:], unamed: [])
            if let attributesText = match.captureGroup(in:CaptureGroups.arguments.rawValue, text: text) {
                attributes = HTMLAttributesParser.makeAttributes(in: attributesText)
            }

            var type: Shortcode.TagType = .single
            if match.captureGroup(in:CaptureGroups.selfClosingElement.rawValue, text: text) != nil {
                type = .selfClosing
            } else if match.captureGroup(in:CaptureGroups.closingTag.rawValue, text: text) != nil {
                type = .closed
            }

            let content: String? = match.captureGroup(in:CaptureGroups.content.rawValue, text: text)

            let shortcode = Shortcode(tag: tag, attributes: attributes, type: type, content: content)
            return replacer(shortcode)
        }
        
        super.init(regex: regex, replacer: regexReplacer)
    }
}
