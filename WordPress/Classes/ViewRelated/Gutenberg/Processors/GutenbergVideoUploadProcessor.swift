import Foundation
import Aztec

class GutenbergVideoUploadProcessor: Processor {

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    lazy var videoHtmlProcessor = HTMLProcessor(for: "video", replacer: { (video) in
        var attributes = video.attributes
        attributes.set(.string(self.remoteURLString), forKey: "src")

        var html = "<video "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += "></video>"
        return html
    })


    func process(_ text: String) -> String {
        var result = videoHtmlProcessor.process(text)
        result = result.replacingOccurrences(of: "wp:video {\"id\":\(String(mediaUploadID))}", with: "wp:video {\"id\":\(String(serverMediaID))}")
        return result
    }

}
