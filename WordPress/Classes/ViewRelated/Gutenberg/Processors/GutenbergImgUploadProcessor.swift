import Foundation
import Aztec

class GutenbergImgUploadProcessor: Processor {

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int
    static let imgClassIDPrefixAttribute = "wp-image-"

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    lazy var imgPostMediaUploadProcessor = HTMLProcessor(for: "img", replacer: { (img: HTMLElement) in
        var attributes: [ShortcodeAttribute] = img.attributes

        guard
            let imgClassAttributeValue = attributes["class"]?.value,
            case let .string(imgClass) = imgClassAttributeValue else {
                return nil
        }

        let classAttributes: [String] = imgClass.components(separatedBy: " ")

        let filteredAttributes: [String] = classAttributes.filter { (value: String) -> Bool in
            return value.hasPrefix(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute)
        }

        guard let imageIDAttribute: String = filteredAttributes.first else {
            return nil
        }

        let imageIDString: String = String(imageIDAttribute.dropFirst(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute.count))
        let imgUploadID = Int32(imageIDString)

        guard imgUploadID == self.mediaUploadID else {
            return nil
        }

        let newImgClassAttributes: String = imgClass.replacingOccurrences(of: imageIDAttribute, with: GutenbergImgUploadProcessor.imgClassIDPrefixAttribute + String(self.serverMediaID))

        attributes.set(.string(self.remoteURLString), forKey: "src")
        attributes.set(.string(newImgClassAttributes), forKey: "class")

        let attributeSerializer: ShortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        let attribute: String = attributeSerializer.serialize(attributes)
        let html: String = String(format: "%@%@%@", "<img ", attribute, "/>")
        return html
    })

    lazy var imgBlockProcessor = GutenbergBlockProcessor(for: "wp:image", replacer: { (imgBlock: GutenbergBlock) in
        guard let mediaID: Int = imgBlock.attributes["id"] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block: String = "<!-- wp:image "
        var attributes: [String: Any] = imgBlock.attributes
        attributes["id"] = self.serverMediaID
        if let jsonData: Data = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString: String = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"
        block += self.imgPostMediaUploadProcessor.process(imgBlock.content)
        block += "<!-- /wp:image -->"
        return block
    })

    lazy var mediaTextBlockProcessor = GutenbergBlockProcessor(for: "wp:media-text", replacer: { (imgBlock: GutenbergBlock) in
        guard let mediaID: Int = imgBlock.attributes["mediaId"] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block: String = "<!-- wp:media-text "
        var attributes: [String: Any] = imgBlock.attributes
        attributes["mediaId"] = self.serverMediaID

        if let jsonData: Data = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString: String = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"
        block += self.imgPostMediaUploadProcessor.process(imgBlock.content)
        block += "<!-- /wp:media-text -->"
        return block
    })

    func process(_ text: String) -> String {
        var result = imgBlockProcessor.process(text)
        result = mediaTextBlockProcessor.process(result)
        return result
    }
}
