import Foundation
import SwiftSoup

public class GutenbergParsedBlock {
    public let name: String
    public var comment: SwiftSoup.Comment
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

    private var attributesData: String

    public var content: String {
        get {
            (try? elements.outerHtml()) ?? ""
        }
    }

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

public class GutenbergContentParser {
    public var originalContent: String
    public let htmlDocument: Document?
    public var blocks: [GutenbergParsedBlock]

    public init(for content: String) {
        self.originalContent = content
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
                if let currentBlock = currentBlock {
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
