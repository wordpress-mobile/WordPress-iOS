import Gutenberg

class GutenbergStockPhotos {
    private let stockPhotos = StockPhotosPicker()
    private var mediaPickerCallback: MediaPickerDidPickMediaCallback?
    private let mediaInserter: GutenbergMediaInserterHelper

    init(mediaInserter: GutenbergMediaInserterHelper) {
        self.mediaInserter = mediaInserter
        stockPhotos.delegate = self
    }

    func presentPicker(origin: UIViewController, post: AbstractPost, callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerCallback = callback
        stockPhotos.presentPicker(origin: origin, blog: post.blog)
    }
}

extension GutenbergStockPhotos: StockPhotosPickerDelegate {
    func stockPhotosPicker(_ picker: StockPhotosPicker, didFinishPicking assets: [StockPhotosMedia]) {
        defer {
            mediaPickerCallback = nil
        }
        guard let callback = mediaPickerCallback else {
            return assertionFailure("Image picked without callback")
        }
        assets.forEach {
            mediaInserter.insertFromExternalSource(asset: $0, provisionalUrl:$0.URL, source: .stockPhotos, callback: callback)
        }
    }
}
