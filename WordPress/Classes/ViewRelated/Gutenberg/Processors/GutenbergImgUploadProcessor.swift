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
        html += ">"
        return html
    })

    func process(_ text: String) -> String {
        var result = imgPostMediaUploadProcessor.process(text)
        result = result.replacingOccurrences(of: "wp:image {\"id\":\(String(mediaUploadID))", with: "wp:image {\"id\":\(String(serverMediaID))")
        result = result.replacingOccurrences(of: "wp:media-text {\"mediaId\":\(String(mediaUploadID))", with: "wp:media-text {\"mediaId\":\(String(serverMediaID))")
        return result
    }
}
