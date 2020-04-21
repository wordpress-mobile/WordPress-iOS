import Gutenberg

class GutenbergTenorMediaPicker {
    private var tenor: TenorPicker?
    private var mediaPickerCallback: MediaPickerDidPickMediaCallback?
    private let mediaInserter: GutenbergMediaInserterHelper
    private unowned var gutenberg: Gutenberg
    private var multipleSelection = false

    init(gutenberg: Gutenberg, mediaInserter: GutenbergMediaInserterHelper) {
        self.mediaInserter = mediaInserter
        self.gutenberg = gutenberg
    }

    func presentPicker(origin: UIViewController, post: AbstractPost, multipleSelection: Bool, callback: @escaping MediaPickerDidPickMediaCallback) {
        let picker = TenorPicker()
        tenor = picker
        picker.allowMultipleSelection = true
        picker.delegate = self
        mediaPickerCallback = callback
        picker.presentPicker(origin: origin, blog: post.blog)
        self.multipleSelection = multipleSelection
    }
}

extension GutenbergTenorMediaPicker: TenorPickerDelegate {
    func tenorPicker(_ picker: TenorPicker, didFinishPicking assets: [TenorMedia]) {
        defer {
            mediaPickerCallback = nil
            tenor = nil
        }
        guard assets.isEmpty == false else {
            mediaPickerCallback?(nil)
            return
        }

        // For blocks that support multiple uploads this will upload all images.
        // If multiple uploads are not supported then it will seperate them out to Image Blocks.
        multipleSelection ? insertOnBlock(with: assets) : insertSingleImages(assets)
    }

    /// Adds the given image object to the requesting block and seperates multiple images to seperate image blocks
    /// - Parameter asset: Tenor Media object to add.
    func insertSingleImages(_ assets: [TenorMedia]) {
        // Append the first item via callback given by Gutenberg.
        if let firstItem = assets.first {
            insertOnBlock(with: [firstItem])
        }
        // Append the rest of images via `.appendMedia` event.
        // Ideally we would send all picked images via the given callback, but that seems to not be possible yet.
        appendOnNewBlocks(assets: assets.dropFirst())
    }

    /// Adds the given images  to the requesting block
    /// - Parameter assets: Tenor Media objects to add.
    func insertOnBlock(with assets: [TenorMedia]) {
        guard let callback = mediaPickerCallback else {
            return assertionFailure("Image picked without callback")
        }

        let mediaInfo = assets.compactMap { (asset) -> MediaInfo? in
            guard let media = self.mediaInserter.insert(exportableAsset: asset, source: .tenor) else {
                return nil
            }
            let mediaUploadID = media.gutenbergUploadID
            return MediaInfo(id: mediaUploadID, url: asset.URL.absoluteString, type: media.mediaTypeString)
        }

        callback(mediaInfo)
    }

    /// Create a new image block for each of the image objects in the slice.
    /// - Parameter assets: Tenor Media objects to append.
    func appendOnNewBlocks(assets: ArraySlice<TenorMedia>) {
        assets.forEach {
            if let media = self.mediaInserter.insert(exportableAsset: $0, source: .tenor) {
                self.gutenberg.appendMedia(id: media.gutenbergUploadID, url: $0.URL, type: .image)
            }
        }
    }
}
