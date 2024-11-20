import Foundation
import SwiftSoup

public class GutenbergParsedBlock {
    public let name: String
    public var elements: Elements
    public var blocks: [GutenbergParsedBlock]
    public weak var parentBlock: GutenbergParsedBlock?
    public let isCloseTag: Bool

    public var attributes: [String: Any] {
        get {
            guard let data = self.attributesData.data(using: .utf8 ),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                  let attributes = jsonObject as? [String: Any]
            else {
                return [:]
            }
            return attributes
        }

        set(newValue) {
            guard let data = try? JSONSerialization.data(withJSONObject: newValue, options: .sortedKeys),
                  let attributes = String(data: data, encoding: .utf8) else {
                return
            }
            self.attributesData = attributes
            // Update comment tag data with new attributes
            try! self.comment.attr("comment", " \(self.name) \(attributes) ")
        }
    }

    public var content: String {
        get {
            (try? elements.outerHtml()) ?? ""
        }
    }

    private var comment: SwiftSoup.Comment
    private var attributesData: String

    public init?(comment: SwiftSoup.Comment, parentBlock: GutenbergParsedBlock? = nil) {
        let data = comment.getData().trim()
        if let separatorRange = data.range(of: " ") {
            self.name = String(data[data.startIndex..<separatorRange.lowerBound])
            self.attributesData = String(data[separatorRange.upperBound..<data.endIndex])
        }
        else {
            self.name = data
            self.attributesData = ""
        }
        self.comment = comment
        self.elements = SwiftSoup.Elements()
        self.blocks = []
        self.isCloseTag = self.name.hasPrefix("/")
        if !self.isCloseTag {
            self.parentBlock = parentBlock
            parentBlock?.blocks.append(self)
        }
    }
}

/// Parses content generated in the Gutenberg editor to allow modifications.
///
/// # Parse content
///
/// ```
/// let block = """
/// <!-- wp:block {"id":1} -->
/// <div class="wp-block"><p>Hello world!</p></div>
/// <!-- /wp:block -->
/// """
/// let parser = GutenbergContentParser(for: block)
/// ```
///
/// # Get blocks
///
/// ```
/// let galleryBlocks = parser.blocks.filter { $0.name == "wp:gallery" }
/// let nestedImageBlocks = galleryBlocks[0].blocks.filter { $0.name == "wp:image" }
/// ```
///
/// > Note: All parsed blocks are in the list, including nested blocks.
///
/// ```
/// let allImageBlocks = parser.blocks.filter { $0.name == "wp:gallery" }
/// ```
///
/// # Modify an attribute
///
/// ```
/// let block = parser.blocks[0]
/// block.attributes["newId"] = 1001
/// ```
///
/// # Modify HTML
///
/// ```
/// let block = parser.blocks[0]
/// try! block.elements.select("img").first()?.attr("src", "remote-url")
/// ```
///
/// More information about querying HTML can be found in [SwiftSoap documentation](https://github.com/scinfu/SwiftSoup?tab=readme-ov-file#use-selector-syntax-to-find-elements).
///
/// # Generate HTML content
///
/// ```
/// let contentHTML = parser.html()
/// ```
///
public class GutenbergContentParser {
    public var blocks: [GutenbergParsedBlock]

    private let htmlDocument: Document?

    public init(for content: String) {
        self.htmlDocument = try? SwiftSoup.parseBodyFragment(content).outputSettings(OutputSettings().prettyPrint(pretty: false))
        self.blocks = []

        guard let htmlContent = self.htmlDocument?.body() else {
            return
        }
        traverseChildNodes(element: htmlContent)
    }

    public func html() -> String {
        return (try? self.htmlDocument?.body()?.html()) ?? ""
    }

    private func traverseChildNodes(element: Element, parentBlock: GutenbergParsedBlock? = nil) {
        var currentBlock: GutenbergParsedBlock?
        element.getChildNodes().forEach { node in
            switch node {
            // Convert comment tag into block
            case let comment as SwiftSoup.Comment:
                guard let block = GutenbergParsedBlock(comment: comment, parentBlock: parentBlock) else {
                    return
                }

                // Identify close tag
                if let currrentBlock = currentBlock, block.name == "/\(currrentBlock.name)" {
                    currentBlock = nil
                    return
                }

                self.blocks.append(block)
                currentBlock = block
            // Insert HTML elements into block being processed
            case let element as SwiftSoup.Element:
                if let currentBlock {
                    currentBlock.elements.add(element)
                }
                if element.childNodeSize() > 0 {
                    traverseChildNodes(element: element, parentBlock: currentBlock ?? parentBlock)
                }
            default: break
            }
        }
    }
}
