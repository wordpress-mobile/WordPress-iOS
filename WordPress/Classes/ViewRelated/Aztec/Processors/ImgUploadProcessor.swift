import Foundation
import Aztec

class ImgUploadProcessor: Processor {
    private struct Constants {
        static let type: String = "img"
        static let src: String = "src"
        static let width: String = "width"
        static let height: String = "height"
    }

    let mediaUploadID: String
    let width: Int?
    let height: Int?
    let remoteURLString: String

    init(mediaUploadID: String, remoteURLString: String, width: Int?, height: Int?) {
        self.mediaUploadID = mediaUploadID
        self.remoteURLString = remoteURLString
        self.width = width
        self.height = height
    }
    
    lazy var imgPostMediaUploadProcessor: HTMLProcessor = HTMLProcessor(for: Constants.type, replacer: { (img: HTMLElement) in
        let uploadKey: String = MediaAttachment.uploadKey

        guard
            let imgUploadValue = img.attributes[uploadKey]?.value,
            case let .string(imgUploadID) = imgUploadValue,
            self.mediaUploadID == imgUploadID
        else {
            return nil
        }

        var attributes: [ShortcodeAttribute] = img.attributes
        attributes.set(.string(self.remoteURLString), forKey: Constants.src)

        if let width: Int = self.width {
            attributes.set(.string("\(width)"), forKey: Constants.width)
        }
        if let height: Int = self.height {
            attributes.set(.string("\(height)"), forKey: Constants.height)
        }

        //remove the uploadKey
        attributes.remove(key: uploadKey)

        let attributeSerializer: ShortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        let attribute: String = attributeSerializer.serialize(attributes)
        let html: String = String(format: "%@%@%@", "<img ", attribute, ">")
        return html
    })

    func process(_ text: String) -> String {
        return imgPostMediaUploadProcessor.process(text)
    }
}
