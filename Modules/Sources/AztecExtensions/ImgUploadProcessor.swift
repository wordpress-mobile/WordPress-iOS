import Foundation
import Aztec

public class ImgUploadProcessor: Processor {

    let mediaUploadID: String
    let width: Int?
    let height: Int?
    let remoteURLString: String

    public init(mediaUploadID: String, remoteURLString: String, width: Int?, height: Int?) {
        self.mediaUploadID = mediaUploadID
        self.remoteURLString = remoteURLString
        self.width = width
        self.height = height
    }

    lazy var imgPostMediaUploadProcessor = HTMLProcessor(for: "img", replacer: { (img) in
        guard let imgUploadValue = img.attributes[MediaAttachment.uploadKey]?.value,
            case let .string(imgUploadID) = imgUploadValue,
            self.mediaUploadID == imgUploadID else {
            return nil
        }
        var attributes = img.attributes
        attributes.set(.string(self.remoteURLString), forKey: "src")
        if let width = self.width {
            attributes.set(.string("\(width)"), forKey: "width")
        }
        if let height = self.height {
            attributes.set(.string("\(height)"), forKey: "height")
        }
        //remove the uploadKey
        attributes.remove(key: MediaAttachment.uploadKey)

        var html = "<img "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += ">"
        return html
    })

    public func process(_ text: String) -> String {
        return imgPostMediaUploadProcessor.process(text)
    }
}

extension MediaAttachment {
    static let uploadKey = "data-wp_upload_id"
}
