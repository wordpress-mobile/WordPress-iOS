import Foundation

class GutenbergFileUploadProcessor: GutenbergProcessor {
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

    func processFileBlocks(_ blocks: [GutenbergParsedBlock]) {
        blocks.filter { $0.name == FileBlockKeys.name }.forEach { block in
            guard let mediaID = block.attributes[FileBlockKeys.id] as? Int,
                mediaID == self.mediaUploadID else {
                    return
            }

            // Update attributes
            block.attributes[FileBlockKeys.id] = self.serverMediaID
            block.attributes[FileBlockKeys.href] = self.remoteURLString

            // Update href of `a` tags
            let aTags = try? block.elements.select("a")
            aTags?.forEach { _ = try? $0.attr(FileBlockKeys.href, self.remoteURLString) }
        }
    }

    func process(_ blocks: [GutenbergParsedBlock]) {
        processFileBlocks(blocks)
    }
}
