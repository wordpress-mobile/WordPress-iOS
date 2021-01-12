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
        let uttypeFilters = filters.contains(.any) ? allowedTypesOnBlog : allTypesFrom(allowedTypesOnBlog, conformingTo: filters)

        mediaPickerCallback = callback
        let docPicker = UIDocumentPickerViewController(documentTypes: uttypeFilters, in: .import)
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = multipleSelection

        origin.present(docPicker, animated: true)
    }

    private func allTypesFrom(_ allTypes: [String], conformingTo filters: [Gutenberg.MediaType]) -> [String] {
        return filters.map { $0.filterTypesConformingTo(allTypes: allTypes) }.reduce([], +)
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
    func filterTypesConformingTo(allTypes: [String]) -> [String] {
        guard let uttype = typeIdentifier else {
            return []
        }
        return getTypesFrom(allTypes, conformingTo: uttype)
    }

    private func getTypesFrom(_ allTypes: [String], conformingTo uttype: CFString) -> [String] {
        return allTypes.filter { UTTypeConformsTo($0 as CFString, uttype) }
    }

    private var typeIdentifier: CFString? {
        switch self {
        case .image:
            return kUTTypeImage
        case .video:
            return kUTTypeMovie
        case .audio:
            return kUTTypeAudio
        case .other, .any: // needs to be specified by the blog's allowed types.
            return nil
        }
    }
}
