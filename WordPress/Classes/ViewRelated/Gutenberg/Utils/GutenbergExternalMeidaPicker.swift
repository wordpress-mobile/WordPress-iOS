import Gutenberg
import ImagePlayground

class GutenbergExternalMediaPicker: NSObject {
    private var mediaPickerCallback: MediaPickerDidPickMediaCallback?
    private let mediaInserter: GutenbergMediaInserterHelper
    private unowned var gutenberg: Gutenberg
    private var multipleSelection = false
    private var imagePlaygroundController: GutenbergImagePlaygroundController?

    init(gutenberg: Gutenberg, mediaInserter: GutenbergMediaInserterHelper) {
        self.mediaInserter = mediaInserter
        self.gutenberg = gutenberg
        super.init()
    }

    @available(iOS 18.1, *)
    func presentImagePlayground(origin: UIViewController, post: AbstractPost, callback: @escaping MediaPickerDidPickMediaCallback) {
        imagePlaygroundController = GutenbergImagePlaygroundController(mediaInserter: mediaInserter, callback: callback)

        let viewController = ImagePlaygroundViewController()
        viewController.delegate = imagePlaygroundController
        viewController.isModalInPresentation = true
        origin.present(viewController, animated: true)
    }

    func presentTenorPicker(origin: UIViewController, post: AbstractPost, multipleSelection: Bool, callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerCallback = callback
        self.multipleSelection = multipleSelection

        MediaPickerMenu(viewController: origin, isMultipleSelectionEnabled: multipleSelection)
            .showFreeGIFPicker(blog: post.blog, delegate: self)
    }

    func presentStockPhotoPicker(origin: UIViewController, post: AbstractPost, multipleSelection: Bool, callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerCallback = callback
        self.multipleSelection = multipleSelection

        MediaPickerMenu(viewController: origin, isMultipleSelectionEnabled: multipleSelection)
            .showStockPhotosPicker(blog: post.blog, delegate: self)
    }
}

extension GutenbergExternalMediaPicker: ExternalMediaPickerViewDelegate {
    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection assets: [ExternalMediaAsset]) {
        defer {
            mediaPickerCallback = nil
        }

        viewController.presentingViewController?.dismiss(animated: true)

        guard assets.isEmpty == false else {
            mediaPickerCallback?(nil)
            return
        }

        // For blocks that support multiple uploads this will upload all images.
        // If multiple uploads are not supported then it will seperate them out to Image Blocks.
        if multipleSelection {
            insertOnBlock(with: assets, source: viewController.source)
        } else {
            insertSingleImages(assets, source: viewController.source)
        }
    }

    /// Adds the given image object to the requesting block and seperates multiple images to seperate image blocks
    /// - Parameter asset: Tenor Media object to add.
    func insertSingleImages(_ assets: [ExternalMediaAsset], source: MediaSource) {
        // Append the first item via callback given by Gutenberg.
        if let firstItem = assets.first {
            insertOnBlock(with: [firstItem], source: source)
        }
        // Append the rest of images via `.appendMedia` event.
        // Ideally we would send all picked images via the given callback, but that seems to not be possible yet.
        appendOnNewBlocks(assets: assets.dropFirst(), source: source)
    }

    /// Adds the given images  to the requesting block
    /// - Parameter assets: Tenor Media objects to add.
    func insertOnBlock(with assets: [ExternalMediaAsset], source: MediaSource) {
        guard let callback = mediaPickerCallback else {
            return assertionFailure("Image picked without callback")
        }

        let mediaInfo = assets.compactMap { (asset) -> MediaInfo? in
            guard let media = self.mediaInserter.insert(exportableAsset: asset, source: source) else {
                return nil
            }
            let mediaUploadID = media.gutenbergUploadID
            return MediaInfo(id: mediaUploadID, url: asset.largeURL.absoluteString, type: media.mediaTypeString)
        }

        callback(mediaInfo)
    }

    /// Create a new image block for each of the image objects in the slice.
    /// - Parameter assets: Tenor Media objects to append.
    func appendOnNewBlocks(assets: ArraySlice<ExternalMediaAsset>, source: MediaSource) {
        assets.forEach {
            if let media = self.mediaInserter.insert(exportableAsset: $0, source: source) {
                self.gutenberg.appendMedia(id: media.gutenbergUploadID, url: $0.largeURL, type: .image)
            }
        }
    }
}

// Uses the following workaround https://mastodon.social/@_inside/113640137011009924
private final class GutenbergImagePlaygroundController: NSObject {
    let callback: MediaPickerDidPickMediaCallback?
    let mediaInserter: GutenbergMediaInserterHelper

    init(mediaInserter: GutenbergMediaInserterHelper, callback: MediaPickerDidPickMediaCallback?) {
        self.mediaInserter = mediaInserter
        self.callback = callback
    }
}

@available(iOS 18.1, *)
extension GutenbergImagePlaygroundController: ImagePlaygroundViewController.Delegate {
    func imagePlaygroundViewController(_ imagePlaygroundViewController: ImagePlaygroundViewController, didCreateImageAt imageURL: URL) {
        if let callback {
            mediaInserter.insertFromDevice([makeItemProvider(with: imageURL)], callback: callback)
        }
        imagePlaygroundViewController.presentingViewController?.dismiss(animated: true)
    }

    /// ImagePlayground returns heic images that are not supported by many WordPress
    /// sites. The only exporter that currentyl supports transcoding images is
    /// ``ItemProviderMediaExporter``, which is why we use it and which is why
    /// we fallback to "public.heic" (should never happen as these URLs have
    /// proper extensions).
    private func makeItemProvider(with imageURL: URL) -> NSItemProvider {
        let provider = NSItemProvider()
        let typeIdentifier = imageURL.typeIdentifier ?? "public.heic"
        provider.registerFileRepresentation(forTypeIdentifier: typeIdentifier, visibility: .all) { completion in
            completion(imageURL, false, nil)
            return nil
        }
        return provider
    }

    func imagePlaygroundViewControllerDidCancel(_ imagePlaygroundViewController: ImagePlaygroundViewController) {
        imagePlaygroundViewController.presentingViewController?.dismiss(animated: true)
    }
}
