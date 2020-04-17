import Foundation
import Aztec

/// Struct to represent a Gutenberg block element
///
public struct GutenbergBlock {
    public let name: String
    public let attributes: [String: Any]
    public let content: String
}

/// A class that processes a Gutenberg post content and replaces the designated Gutenberg block for the replacement provided strings.
///
public class GutenbergBlockProcessor: Processor {

    /// Whenever a Guntenberg block  is found by the processor, this closure will be executed so that elements can be customized.
    ///
    public typealias Replacer = (GutenbergBlock) -> String?

    let name: String

    private enum CaptureGroups: Int {
        case all = 0
        case name
        case attributes

        static let allValues: [CaptureGroups] = [.all, .name, .attributes]
    }

    // MARK: - Parsing & processing properties
    private let replacer: Replacer

    // MARK: - Initializers

    public init(for blockName: String, replacer: @escaping Replacer) {
        self.name = blockName
        self.replacer = replacer
    }

    /// Regular expression to detect attributes of the opening tag of a block
    /// Capture groups:
    ///
    /// 1. The block id
    /// 2. The block attributes
    ///
    var openTagRegex: NSRegularExpression {
        let pattern = "\\<!--[ ]?(\(name))([\\s\\S]*?)-->"
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }

    /// Regular expression to detect the closing tag of a block
    ///
    var closingTagRegex: NSRegularExpression {
        let pattern = "\\<!-- \\/\(name) -->"
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }

    // MARK: - Processing

    /// Processes the block and for any needed replacements from a given opening tag match.
    ///     - Parameters:
    ///         - text: The string that the following parameter is found in.
    ///     - Returns: The resulting string after the necessary replacements have occured
    ///
    public func process(_ text: String) -> String {
        let matches = openTagRegex.matches(in: text, options: [], range: text.utf16NSRange(from: text.startIndex ..< text.endIndex))
        var replacements = [(NSRange, String)]()

        var lastReplacementBound = 0
        for match in matches {
            if match.range.lowerBound >= lastReplacementBound, let replacement = process(match, in: text) {
                replacements.append(replacement)
                lastReplacementBound = replacement.0.upperBound
            }
        }
        let resultText = replace(replacements, in: text)
        return resultText
    }

    /// Replaces the
    ///     - Parameters:
    ///         - replacements: An array of tuples representing first a range of text that needs to be replaced then the string to replace
    ///         - text: The string to perform the replacements on
    ///
    func replace(_ replacements: [(NSRange, String)], in text: String) -> String {
        let mutableString = NSMutableString(string: text)
        var offset = 0
        for (range, replacement) in replacements {
            let lengthBefore = mutableString.length
            let offsetRange = NSRange(location: range.location + offset, length: range.length)
            mutableString.replaceCharacters(in: offsetRange, with: replacement)
            let lengthAfter = mutableString.length
            offset += (lengthAfter - lengthBefore)
        }
        return mutableString as String
    }
}
// MARK: - Regex Match Processing Logic

private extension GutenbergBlockProcessor {
    /// Processes the block and for any needed replacements from a given opening tag match.
    ///     - Parameters:
    ///         - match: The match reperesenting an opening block tag
    ///         - text: The string that the following parameter is found in.
    ///     - Returns: Any necessary replacements within the provided string
    ///
    private func process(_ match: NSTextCheckingResult, in text: String) -> (NSRange, String)? {

        var result: (NSRange, String)? = nil
        if let closingRange = locateClosingTag(forMatch: match, in: text) {
            let attributes = readAttributes(from: match, in: text)
            let content = readContent(from: match, withClosingRange: closingRange, in: text)
            let parsedContent = process(content) // Recurrsively parse nested blocks and process those seperatly
            let block = GutenbergBlock(name: name, attributes: attributes, content: parsedContent)

            if let replacement = replacer(block) {
                let length = closingRange.upperBound - match.range.lowerBound
                let range = NSRange(location: match.range.lowerBound, length: length)
                result = (range, replacement)
            }
        }

        return result
    }

    /// Determines the location of the closing block tag for the matching open tag
    ///     - Parameters:
    ///         - openTag: The match reperesenting an opening block tag
    ///         - text: The string that the following parameter is found in.
    ///     - Returns: The Range of the closing tag for the block
    ///
    func locateClosingTag(forMatch openTag: NSTextCheckingResult, in text: String) -> NSRange? {
        guard let index = text.indexFromLocation(openTag.range.upperBound) else {
            return nil
        }

        let matches = closingTagRegex.matches(in: text, options: [], range: text.utf16NSRange(from: index ..< text.endIndex))

        for match in matches {
            let content = readContent(from: openTag, withClosingRange: match.range, in: text)

            if tagsAreBalanced(in: content) {
                return match.range
            }
        }

        return nil
    }

    /// Determines if there are an equal number of opening and closing block tags in the provided text.
    ///     - Parameters:
    ///         - text: The string to test assumes that a block with an even number represents a valid block sequence.
    ///     - Returns: A boolean where true represents an equal number of opening and closing block tags of the desired type
    ///
    func tagsAreBalanced(in text: String) -> Bool {

        let range = text.utf16NSRange(from: text.startIndex ..< text.endIndex)
        let openTags = openTagRegex.matches(in: text, options: [], range: range)
        let closingTags = closingTagRegex.matches(in: text, options: [], range: range)

        return openTags.count == closingTags.count
    }

    /// Obtains the block attributes from a regex match.
    ///     - Parameters:
    ///         - match: The `NSTextCheckingResult` from a successful regex detection of an opening block tag
    ///         - text: The string that the following parameter is found in.
    ///     - Returns: A JSON dictionary of the block attributes
    ///
    func readAttributes(from match: NSTextCheckingResult, in text: String) -> [String: Any] {
        guard let attributesText = match.captureGroup(in: CaptureGroups.attributes.rawValue, text: text),
            let data = attributesText.data(using: .utf8 ),
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
            let jsonDictionary = json as? [String: Any] else {
                return [:]
        }

        return jsonDictionary
    }

    /// Obtains the block content from a regex match and range.
    ///     - Parameters:
    ///         - match: The `NSTextCheckingResult` from a successful regex detection of an opening block tag
    ///         - closingRange: The `NSRange` of the closing block tag
    ///         - text: The string that the following parameters are found in.
    ///     - Returns: The content between the opening and closing tags of a block
    ///
    func readContent(from match: NSTextCheckingResult, withClosingRange closingRange: NSRange, in text: String) -> String {
        guard let index = text.indexFromLocation(match.range.upperBound) else {
            return ""
        }

        guard let closingBound = text.indexFromLocation(closingRange.lowerBound) else {
            return ""
        }

        return String(text[index..<closingBound])
    }
}
