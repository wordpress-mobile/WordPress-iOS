import Foundation
import Aztec

class GutenbergMediaFilesUploadProcessor: Processor {
    private struct FileBlockKeys {
        static var name = "wp:jetpack/story"
    }

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
    }

    lazy var mediaFilesProcessor = GutenbergBlockProcessor(for: FileBlockKeys.name, replacer: { block in

        guard let mediaFileAttributes = block.attributes["mediaFiles"] as? [[String: Any]] else {
            return nil
        }
        let mediaFiles = mediaFileAttributes.compactMap { attributes in
            return MediaFile.file(from: attributes)
        }

        let media: [MediaFile] = mediaFiles.map { mediaFile -> MediaFile in
            guard Int32(mediaFile.id) == self.mediaUploadID else {
                return mediaFile
            }

            guard let newURL = StoryPoster.filePath?.appendingPathComponent(String(self.serverMediaID)) else {
                return mediaFile
            }

            do {
                if let mediaURL = URL(string: mediaFile.url), FileManager.default.fileExists(atPath: newURL.path) == false {
                    try FileManager.default.moveItem(at: mediaURL, to: newURL)
                } else {
                    DDLogError("No Media File URL was present. This is a Stories error and should be investigated")
                }
            } catch let error {
                assertionFailure("Failed to move archived file: \(mediaFile.url) to new location: \(newURL) - \(error)")
            }

            let file = MediaFile(alt: mediaFile.alt,
                                  caption: mediaFile.caption,
                                  id: String(self.serverMediaID),
                                  link: mediaFile.link,
                                  mime: mediaFile.mime,
                                  type: mediaFile.type,
                                  url: self.remoteURLString)
            return file
        }

        let story = Story(mediaFiles: media)

        let encoder = JSONEncoder()
        do {
            let json = String(data: try encoder.encode(story), encoding: .utf8)
            if let json = json {
                return StoryBlock.wrap(json, includeFooter: true)
            } else {
                return nil
            }
        } catch let error {
            assertionFailure("Encoding story failed: \(error)")
            return nil
        }
    })

    func process(_ text: String) -> String {
        return mediaFilesProcessor.process(text)
    }
}
