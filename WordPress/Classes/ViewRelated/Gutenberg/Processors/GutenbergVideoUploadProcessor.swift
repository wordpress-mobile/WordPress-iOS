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

    private struct VideoBlockKeys {
        static var name = "wp:video"
        static var id = "id"
    }

    lazy var videoBlockProcessor = GutenbergBlockProcessor(for: VideoBlockKeys.name, replacer: { videoBlock in
        guard let mediaID = videoBlock.attributes[VideoBlockKeys.id] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- \(VideoBlockKeys.name) "
        var attributes = videoBlock.attributes
        attributes[VideoBlockKeys.id] = self.serverMediaID
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"
        block += self.videoHtmlProcessor.process(videoBlock.content)
        block += "<!-- /\(VideoBlockKeys.name) -->"
        return block
    })

    private struct MediaTextBlockKeys {
        static var name = "wp:media-text"
        static var id = "mediaId"
    }

    lazy var mediaTextVideoBlockProcessor = GutenbergBlockProcessor(for: MediaTextBlockKeys.name, replacer: { videoBlock in
        guard let mediaID = videoBlock.attributes[MediaTextBlockKeys.id] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- \(MediaTextBlockKeys.name) "
        var attributes = videoBlock.attributes
        attributes[MediaTextBlockKeys.id] = self.serverMediaID
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"
        block += self.videoHtmlProcessor.process(videoBlock.content)
        block += "<!-- /\(MediaTextBlockKeys.name) -->"
        return block
    })


    func process(_ text: String) -> String {
        var result = videoBlockProcessor.process(text)
        result = mediaTextVideoBlockProcessor.process(result)
        return result
    }

}
