import Foundation
import Aztec

class GutenbergVideoUploadProcessor: Processor {

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int
    let localURLString: String?

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String, localURLString: String?) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
        self.localURLString = localURLString
    }

    lazy var videoHtmlProcessor = HTMLProcessor(for: "video", replacer: { (video) in
        var attributes = video.attributes
        guard let originalSrcValue = attributes["src"]?.value,
            case let .string(originalSrc) = originalSrcValue,
            let srcURL = URL(string: originalSrc),
            let mediaUploadID = srcURL.lastPathComponent.split(separator: ".").first,
            mediaUploadID == "\(self.mediaUploadID)" else {
            return nil
        }

        attributes.set(.string(self.remoteURLString), forKey: "src")

        var html = "<video "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += "></video>"
        return html
    })


    func process(_ text: String) -> String {
        var result = videoHtmlProcessor.process(text)
        result = result.replacingOccurrences(of: "wp:video {\"id\":\(String(mediaUploadID))", with: "wp:video {\"id\":\(String(serverMediaID))")
        result = result.replacingOccurrences(of: "wp:media-text {\"mediaId\":\(String(mediaUploadID))", with: "wp:media-text {\"mediaId\":\(String(serverMediaID))")
        return result
    }

}
