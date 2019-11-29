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
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        origin.present(docPicker, animated: true)
    }
}

extension GutenbergFilesAppMediaSource: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        defer {
            mediaPickerCallback = nil
        }
        if let documentURL = urls.first {
            insertOnBlock(with: documentURL)
        } else {
            mediaPickerCallback?(nil)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        WPStyleGuide.configureNavigationAppearance()
        mediaPickerCallback?(nil)
        mediaPickerCallback = nil
    }

    /// Adds the given image object to the requesting Image Block
    /// - Parameter asset: Stock Media object to add.
    func insertOnBlock(with url: URL) {
        WPStyleGuide.configureNavigationAppearance()
        guard let callback = mediaPickerCallback else {
            return assertionFailure("Image picked without callback")
        }

        guard let media = self.mediaInserter.insert(exportableAsset: url as NSURL, source: .otherApps) else {
            return callback([])
        }

        let mediaUploadID = media.gutenbergUploadID
        callback([MediaInfo(id: mediaUploadID, url: url.absoluteString, type: media.mediaTypeString)])
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
