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

    lazy var imgPostMediaUploadProcessor = HTMLProcessor(for: "img", replacer: { (img) in
        guard let imgClassAttributeValue = img.attributes["class"]?.value,
            case let .string(imgClass) = imgClassAttributeValue else {
                return nil
        }

        let classAttributes = imgClass.components(separatedBy: " ")

        guard let imageIDAttribute = classAttributes.filter({ (value) -> Bool in
            value.hasPrefix(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute)
        }).first else {
            return nil
        }

        let imageIDString = String(imageIDAttribute.dropFirst(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute.count))
        let imgUploadID = Int32(imageIDString)

        guard imgUploadID == self.mediaUploadID else {
            return nil
        }

        let newImgClassAttributes = imgClass.replacingOccurrences(of: imageIDAttribute, with: GutenbergImgUploadProcessor.imgClassIDPrefixAttribute + String(self.serverMediaID))

        var attributes = img.attributes
        attributes.set(.string(self.remoteURLString), forKey: "src")
        attributes.set(.string(newImgClassAttributes), forKey: "class")

        var html = "<img "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += "/>"
        return html
    })

    lazy var imgBlockProcessor = GutenbergBlockProcessor(for: "wp:image", replacer: { imgBlock in
        guard let mediaID = imgBlock.attributes["id"] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- wp:image "
        var attributes = imgBlock.attributes
        attributes["id"] = self.serverMediaID
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"
        block += self.imgPostMediaUploadProcessor.process(imgBlock.content)
        block += "<!-- /wp:image -->"
        return block
    })

    lazy var mediaTextBlockProcessor = GutenbergBlockProcessor(for: "wp:media-text", replacer: { imgBlock in
        guard let mediaID = imgBlock.attributes["mediaId"] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- wp:media-text "
        var attributes = imgBlock.attributes
        attributes["mediaId"] = self.serverMediaID
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
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
