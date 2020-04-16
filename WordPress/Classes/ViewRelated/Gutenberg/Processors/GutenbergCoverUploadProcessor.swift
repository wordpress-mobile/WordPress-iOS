import Foundation
import Aztec

class GutenbergCoverUploadProcessor: Processor {
    public typealias InnerBlockProcessor = (String) -> String?

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    lazy var coverBlockProcessor = GutenbergBlockProcessor(for: "wp:cover", replacer: { coverBlock in
        guard let mediaID = coverBlock.attributes["id"] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- wp:cover "

        var attributes = coverBlock.attributes
        attributes["id"] = self.serverMediaID
        attributes["url"] = self.remoteURLString

        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: [.sortedKeys]),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }

        block += " -->"
        block += self.htmlUploadProcessor.process(coverBlock.content)
        block += "<!-- /wp:cover -->"
        return block
    })

    lazy var htmlUploadProcessor = HTMLProcessor(for: "div", replacer: { (div) in

        guard let styleAttributeValue = div.attributes["style"]?.value,
            case let .string(styleAttribute) = styleAttributeValue,
            styleAttribute.hasPrefix("background-image:url(file:///") else {
                return nil
        }

        let style = "background-image:url(\(self.remoteURLString))"
        var attributes = div.attributes
        attributes.set(.string(style), forKey: "style")

        let attributeSerializer = ShortcodeAttributeSerializer()
        var html = "<div "
        html += attributeSerializer.serialize(attributes)
        html += ">"
        html += div.content ?? ""
        html += "</div>"
        return html
    })

    func process(_ text: String) -> String {
        return coverBlockProcessor.process(text)
    }
}
