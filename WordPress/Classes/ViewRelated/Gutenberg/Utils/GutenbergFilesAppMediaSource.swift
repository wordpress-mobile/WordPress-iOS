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
        mediaPickerCallback = callback
        let documentTypes = GutenbergFilesAppMediaSource.getDocumentTypes(filters: filters, allowedTypesOnBlog: allowedTypesOnBlog)
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: documentTypes.compactMap(UTType.init), asCopy: true)
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = multipleSelection
        origin.present(docPicker, animated: true)
    }

    static func getDocumentTypes(filters: [Gutenberg.MediaType], allowedTypesOnBlog: [String]) -> [String] {
        if filters.contains(.any) {
            return allowedTypesOnBlog
        } else {
            return filters.map { $0.filterTypesConformingTo(allTypes: allowedTypesOnBlog) }.reduce([], +)
        }
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

private extension Gutenberg.MediaType {
    func filterTypesConformingTo(allTypes: [String]) -> [String] {
        guard let type = typeIdentifier else {
            return []
        }
        return getTypesFrom(allTypes, conformingTo: type)
    }

    private func getTypesFrom(_ allTypes: [String], conformingTo requiredType: UTType) -> [String] {
        allTypes.filter {
            guard let allowedType = UTType($0) else {
                return false
            }
            // Sometimes the compared type could be a supertype
            // For example a self-hosted site without Jetpack may have "public.content" as allowedType
            // Although "public.audio" conforms to "public.content", it's not true the other way around
            if allowedType.isSupertype(of: requiredType) {
                return true
            }
            return allowedType.conforms(to: requiredType)
        }
    }

    private var typeIdentifier: UTType? {
        switch self {
        case .image:
            return UTType.image
        case .video:
            return UTType.movie
        case .audio:
            return UTType.audio
        case .other, .any: // needs to be specified by the blog's allowed types.
            return nil
        @unknown default:
            fatalError()
        }
    }
}
