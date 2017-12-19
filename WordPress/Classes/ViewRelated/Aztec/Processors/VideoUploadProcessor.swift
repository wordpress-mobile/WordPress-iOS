import Foundation
import Aztec

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
        guard let uploadID = shortcode.attributes.named[MediaAttachment.uploadKey], self.mediaUploadID == uploadID else {
            return nil
        }
        var html = ""
        if let videoPressGUID = self.videoPressID {
            html = "[wpvideo "
            html += videoPressGUID
            html += " ]"
        } else {
            html = "[video "
            var updatedAttributes = shortcode.attributes.named
            updatedAttributes["src"] = self.remoteURLString
            //remove the uploadKey
            updatedAttributes[MediaAttachment.uploadKey] = nil

            for (name, value) in updatedAttributes {
                html += "\(name)=\"\(value)\" "
            }
            for value in shortcode.attributes.unamed {
                html += "\(value) "
            }

            html += "]"
        }

        return html
    })

    func process(_ text: String) -> String {
        return videoPostMediaUploadProcessor.process(text)
    }
}
