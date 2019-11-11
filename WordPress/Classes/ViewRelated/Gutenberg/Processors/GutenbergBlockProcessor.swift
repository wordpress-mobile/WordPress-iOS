import Foundation
import Aztec

/// Struct to represent a Gutenberg element
///
public struct GutenbergBlock {
    public let name: String
    public let attributes: [String: Any]
    public let content: String
}

/// A class that processes a string and replace the designated shortcode for the replacement provided strings
///
public class GutenbergBlockProcessor: Processor {

    /// Whenever an HTML is found by the processor, this closure will be executed so that elements can be customized.
    ///
    public typealias Replacer = (GutenbergBlock) -> String?

    // MARK: - Basic Info

    let name: String

    // MARK: - Regex

    private enum CaptureGroups: Int {
        case all = 0
        case name
        case attributes
        case content

        static let allValues: [CaptureGroups] = [.all, .name, .attributes, .content]
    }

    /// Regular expression to detect attributes
    /// Capture groups:
    ///
    /// 1. The block id
    /// 2. The block attributes
    ///
    private lazy var gutenbergBlockRegexProcessor: RegexProcessor = { [weak self]() in
        let pattern = "\\<!--[ ]?(\(name))([\\s\\S]*?)-->([\\s\\S]*?)<!-- \\/\(name) -->"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        return RegexProcessor(regex: regex) { (match: NSTextCheckingResult, text: String) -> String? in
            return self?.process(match: match, text: text)
        }
    }()

    // MARK: - Parsing & processing properties
    private let replacer: Replacer

    // MARK: - Initializers

    public init(for blockName: String, replacer: @escaping Replacer) {
        self.name = blockName
        self.replacer = replacer
    }

    // MARK: - Processing

    public func process(_ text: String) -> String {
        return gutenbergBlockRegexProcessor.process(text)
    }
}

// MARK: - Regex Match Processing Logic

private extension GutenbergBlockProcessor {
    /// Processes an HTML Element regex match.
    ///
    func process(match: NSTextCheckingResult, text: String) -> String? {

        guard match.numberOfRanges == CaptureGroups.allValues.count else {
            return nil
        }

        let attributes = readAttributes(from: match, in: text)
        let content = readContent(from: match, in: text)
        let block = GutenbergBlock(name: name, attributes: attributes, content: content)

        return replacer(block)
    }

    // MARK: - Regex Match Processing Logic

    /// Obtains the attributes from an block match.
    ///
    private func readAttributes(from match: NSTextCheckingResult, in text: String) -> [String: Any] {
        guard let attributesText = match.captureGroup(in: CaptureGroups.attributes.rawValue, text: text),
            let data = attributesText.data(using: .utf8 ),
            let json = try? JSONSerialization.jsonObject(with: data , options: .allowFragments),
            let jsonDictionary = json as? [String: Any] else {
                return [:]
        }

        return jsonDictionary
    }

    /// Obtains the attributes from an block match.
    ///
    private func readContent(from match: NSTextCheckingResult, in text: String) -> String {
        guard let content = match.captureGroup(in: CaptureGroups.content.rawValue, text: text) else {
            return ""
        }

        return content
    }
}
