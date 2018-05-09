import Foundation
import Aztec

class ImgUploadProcessor: Processor {

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

    lazy var imgPostMediaUploadProcessor = HTMLProcessor(tag: "img", replacer: { (img) in
        guard let imgUploadID = img.attributes.named[MediaAttachment.uploadKey], self.mediaUploadID == imgUploadID else {
            return nil
        }
        var updatedAttributes = img.attributes.named
        updatedAttributes["src"] = self.remoteURLString
        if let width = self.width {
            updatedAttributes["width"] = "\(width)"
        }
        if let height = self.height {
            updatedAttributes["height"] = "\(height)"
        }
        //remove the uploadKey
        updatedAttributes[MediaAttachment.uploadKey] = nil
        var html = "<img "
        for (name, value) in updatedAttributes {
            html += "\(name)=\"\(value)\" "
        }
        for value in img.attributes.unamed {
            html += "\(value) "
        }

        html += ">"
        return html
    })

    func process(_ text: String) -> String {
        return imgPostMediaUploadProcessor.process(text)
    }
}
