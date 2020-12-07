import Foundation
import Aztec

class GutenbergAudioUploadProcessor: Processor {
    private struct AudioBlockKeys {
        static let name = "wp:audio"
        static let id = "id"
        static let src = "src"
    }

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    lazy var fileHtmlProcessor = HTMLProcessor(for: "audio", replacer: { (audio) in
        var attributes = audio.attributes

        attributes.set(.string(self.remoteURLString), forKey: AudioBlockKeys.src)

        var html = "<audio "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += "></audio>"
        return html
    })

    lazy var fileBlockProcessor = GutenbergBlockProcessor(for: AudioBlockKeys.name, replacer: { fileBlock in
        guard let mediaID = fileBlock.attributes[AudioBlockKeys.id] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- \(AudioBlockKeys.name) "
        var attributes = fileBlock.attributes
        attributes[AudioBlockKeys.id] = self.serverMediaID
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"
        block += self.fileHtmlProcessor.process(fileBlock.content)
        block += "<!-- /\(AudioBlockKeys.name) -->"
        return block
    })

    func process(_ text: String) -> String {
        return fileBlockProcessor.process(text)
    }
}
