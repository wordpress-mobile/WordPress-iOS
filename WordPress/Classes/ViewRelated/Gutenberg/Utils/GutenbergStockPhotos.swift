import Gutenberg

class GutenbergStockPhotos {
    private var stockPhotos: StockPhotosPicker?
    private var mediaPickerCallback: MediaPickerDidPickMediaCallback?
    private let mediaInserter: GutenbergMediaInserterHelper
    private unowned var gutenberg: Gutenberg

    init(gutenberg: Gutenberg, mediaInserter: GutenbergMediaInserterHelper) {
        self.mediaInserter = mediaInserter
        self.gutenberg = gutenberg
    }

    func presentPicker(origin: UIViewController, post: AbstractPost, multipleSelection: Bool, callback: @escaping MediaPickerDidPickMediaCallback) {
        let picker = StockPhotosPicker()
        stockPhotos = picker
        // Forcing multiple selection while multipleSelection == false in JS side.
        picker.allowMultipleSelection = true //multipleSelection
        picker.delegate = self
        mediaPickerCallback = callback
        picker.presentPicker(origin: origin, blog: post.blog)
    }
}

extension GutenbergStockPhotos: StockPhotosPickerDelegate {
    func stockPhotosPicker(_ picker: StockPhotosPicker, didFinishPicking assets: [StockPhotosMedia]) {
        defer {
            mediaPickerCallback = nil
            stockPhotos = nil
        }
        guard assets.isEmpty == false else {
            mediaPickerCallback?(nil)
            return
        }

        // Append the first item via callback given by Gutenberg.
        if let firstItem = assets.first {
            insertOnBlock(with: firstItem)
        }
        // Append the rest of images via `.appendMedia` event.
        // Ideally we would send all picked images via the given callback, but that seems to not be possible yet.
        appendOnNewBlocks(assets: assets.dropFirst())
    }

    /// Adds the given image object to the requesting Image Block
    /// - Parameter asset: Stock Media object to add.
    func insertOnBlock(with asset: StockPhotosMedia) {
        guard let callback = mediaPickerCallback else {
            return assertionFailure("Image picked without callback")
        }

        guard let media = self.mediaInserter.insert(exportableAsset: asset, source: .giphy) else {
            callback([])
            return
        }
        let mediaUploadID = media.gutenbergUploadID
        callback([MediaInfo(id: mediaUploadID, url: asset.URL.absoluteString, type: media.mediaTypeString)])
    }


    /// Create a new image block for each of the image objects in the slice.
    /// - Parameter assets: Stock Media objects to append.
    func appendOnNewBlocks(assets: ArraySlice<StockPhotosMedia>) {
        assets.forEach {
            if let media = self.mediaInserter.insert(exportableAsset: $0, source: .giphy) {
                self.gutenberg.appendMedia(id: media.gutenbergUploadID, url: $0.URL, type: .image)
            }
        }
    }
}
