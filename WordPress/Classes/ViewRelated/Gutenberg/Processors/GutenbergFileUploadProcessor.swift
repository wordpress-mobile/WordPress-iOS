import Foundation
import Aztec

class GutenbergFileUploadProcessor: Processor {
    private struct FileBlockKeys {
        static var name = "wp:file"
        static var id = "id"
        static var href = "href"
    }

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    lazy var fileHtmlProcessor = HTMLProcessor(for: "a", replacer: { (file) in
        var attributes = file.attributes

        attributes.set(.string(self.remoteURLString), forKey: FileBlockKeys.href)

        var html = "<a "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(attributes)
        html += ">\(file.content ?? "")</a>"
        return html
    })

    lazy var fileBlockProcessor = GutenbergBlockProcessor(for: FileBlockKeys.name, replacer: { fileBlock in
        guard let mediaID = fileBlock.attributes[FileBlockKeys.id] as? Int,
            mediaID == self.mediaUploadID else {
                return nil
        }
        var block = "<!-- \(FileBlockKeys.name) "
        var attributes = fileBlock.attributes
        attributes[FileBlockKeys.id] = self.serverMediaID
        attributes[FileBlockKeys.href] = self.remoteURLString
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"
        block += self.fileHtmlProcessor.process(fileBlock.content)
        block += "<!-- /\(FileBlockKeys.name) -->"
        return block
    })

    func process(_ text: String) -> String {
        return fileBlockProcessor.process(text)
    }
}
