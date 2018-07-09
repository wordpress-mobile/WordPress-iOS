import Foundation
import Aztec
import WordPressEditor

class VideoUploadProcessor: Processor {

    let mediaUploadID: String
    let remoteURLString: String
    let videoPressID: String?

    init(mediaUploadID: String, remoteURLString: String, videoPressID: String?) {
        self.mediaUploadID = mediaUploadID
        self.remoteURLString = remoteURLString
        self.videoPressID = videoPressID
    }

    lazy var videoPostMediaUploadProcessor = ShortcodeProcessor(tag: "video", replacer: { (shortcode) in
        guard let uploadValue = shortcode.attributes[MediaAttachment.uploadKey]?.value,
            case let .string(uploadID) = uploadValue,
            self.mediaUploadID == uploadID else {
            return nil
        }
        var html = ""
        if let videoPressGUID = self.videoPressID {
            html = "[wpvideo "
            html += videoPressGUID
            html += " ]"
        } else {
            html = "[video "
            var updatedAttributes = shortcode.attributes
            updatedAttributes.set(.string(self.remoteURLString), forKey: "src")
            //remove the uploadKey
            updatedAttributes.remove(key: MediaAttachment.uploadKey)

            let attributeSerializer = ShortcodeAttributeSerializer()
            html += attributeSerializer.serialize(updatedAttributes)

            html += "]"
        }

        return html
    })

    func process(_ text: String) -> String {
        return videoPostMediaUploadProcessor.process(text)
    }
}
