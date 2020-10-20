import Gutenberg
import MobileCoreServices

class GutenbergFilesAppMediaSource: NSObject {
    private var mediaPickerCallback: MediaPickerDidPickMediaCallback?
    private let mediaInserter: GutenbergMediaInserterHelper
    private unowned var gutenberg: Gutenberg

    init(gutenberg: Gutenberg, mediaInserter: GutenbergMediaInserterHelper) {
        self.mediaInserter = mediaInserter
        self.gutenberg = gutenberg
    }

    func presentPicker(origin: UIViewController, filters: [Gutenberg.MediaType], allowedTypesOnBlog: [String], multipleSelection: Bool, callback: @escaping MediaPickerDidPickMediaCallback) {

        let uttypeFilters = filters.contains(.other) ? allowedTypesOnBlog : filters.compactMap { $0.typeIdentifier }

        mediaPickerCallback = callback
        let docPicker = UIDocumentPickerViewController(documentTypes: uttypeFilters, in: .import)
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = multipleSelection

        origin.present(docPicker, animated: true)
    }
}

extension GutenbergFilesAppMediaSource: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        defer {
            mediaPickerCallback = nil
        }
        if urls.count == 0 {
            mediaPickerCallback?(nil)
        } else {
            insertOnBlock(with: urls)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        mediaPickerCallback?(nil)
        mediaPickerCallback = nil
    }

    func insertOnBlock(with urls: [URL]) {
        guard let callback = mediaPickerCallback else {
            return assertionFailure("Image picked without callback")
        }

        let mediaInfo = urls.compactMap({ (url) -> MediaInfo? in
            guard let media = mediaInserter.insert(exportableAsset: url as NSURL, source: .otherApps) else {
                return nil
            }
            let mediaUploadID = media.gutenbergUploadID
            return MediaInfo(id: mediaUploadID, url: url.absoluteString, type: media.mediaTypeString, title: url.lastPathComponent)
        })

        callback(mediaInfo)
    }
}

extension Gutenberg.MediaType {
    var typeIdentifier: String? {
        switch self {
        case .image:
            return String(kUTTypeImage)
        case .video:
            return String(kUTTypeMovie)
        case .audio:
            return String(kUTTypeAudio)
        case .other:
            return nil
        }
    }
}
