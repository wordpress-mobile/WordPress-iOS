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

    func presentPicker(origin: UIViewController, filters: [Gutenberg.MediaType], multipleSelection: Bool, callback: @escaping MediaPickerDidPickMediaCallback) {
        let uttypeFilters = filters.compactMap { $0.typeIdentifier }
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
        GutenbergMediaPickerHelper.insertOnBlock(with: urls,
                                                 mediaInserter: mediaInserter,
                                                 source: .otherApps,
                                                 mediaPickerCallback: mediaPickerCallback)
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
