import Foundation
import Aztec

class GutenbergCoverUploadProcessor: Processor {
    public typealias InnerBlockProcessor = (String) -> String?

    private struct CoverBlockKeys {
        static let name = "wp:cover"
        static let id = "id"
        static let url = "url"
    }

    private struct HTMLKeys {
        static let name = "div"
        static let styleComponents = "style"
        static let backgroundImage = "background-image:url"
    }

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    lazy var coverBlockProcessor = GutenbergBlockProcessor(for: CoverBlockKeys.name, replacer: { coverBlock in
        guard let mediaID = coverBlock.attributes[CoverBlockKeys.id] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- \(CoverBlockKeys.name) "

        var attributes = coverBlock.attributes
        attributes[CoverBlockKeys.id] = self.serverMediaID
        attributes[CoverBlockKeys.url] = self.remoteURLString

        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: [.sortedKeys]),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }

        block += " -->"
        block += self.htmlUploadProcessor.process(coverBlock.content)
        block += "<!-- /\(CoverBlockKeys.name) -->"
        return block
    })

    lazy var htmlUploadProcessor = HTMLProcessor(for: HTMLKeys.name, replacer: { (div) in

        guard let styleAttributeValue = div.attributes[HTMLKeys.styleComponents]?.value,
            case let .string(styleAttribute) = styleAttributeValue
            else {
                return nil
        }

        let range = styleAttribute.utf16NSRange(from: styleAttribute.startIndex ..< styleAttribute.endIndex)
        let matches = self.localBackgroundImageRegex.matches(in: styleAttribute,
                                                             options: [],
                                                             range: range)
        guard matches.count == 1 else {
            return nil
        }

        let style = "\(HTMLKeys.backgroundImage)(\(self.remoteURLString))"
        let updatedStyleAttribute = self.localBackgroundImageRegex.stringByReplacingMatches(in: styleAttribute,
                                                                                            options: [],
                                                                                            range: range,
                                                                                            withTemplate: style)

        var attributes = div.attributes
        attributes.set(.string(updatedStyleAttribute), forKey: HTMLKeys.styleComponents)

        let attributeSerializer = ShortcodeAttributeSerializer()
        var html = "<\(HTMLKeys.name) "
        html += attributeSerializer.serialize(attributes)
        html += ">"
        html += div.content ?? ""
        html += "</\(HTMLKeys.name)>"
        return html
    })

    private let localBackgroundImageRegex: NSRegularExpression = {
        let pattern = "background-image:[ ]?url\\(file:\\/\\/\\/.*\\)"
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()

    func process(_ text: String) -> String {
        return coverBlockProcessor.process(text)
    }
}
