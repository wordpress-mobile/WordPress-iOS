import WPMediaPicker
import MobileCoreServices
import CoreGraphics
import Photos
import UniformTypeIdentifiers
import PhotosUI

/// Encapsulates launching and customization of a media picker to import media from the Photos Library
final class MediaLibraryPicker: NSObject, PHPickerViewControllerDelegate {
    private let dataSource = WPPHAssetDataSource()

    weak var delegate: WPMediaPickerViewControllerDelegate?
    private var blog: Blog?

    func presentPicker(origin: UIViewController, blog: Blog) {
        self.blog = blog

        var configuration = PHPickerConfiguration(photoLibrary: .shared())

        // Set the filter type according to the user’s selection.
//        configuration.filter = filter
        // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
        // TODO: Is this right?
        configuration.preferredAssetRepresentationMode = .compatible
        // Set the selection behavior to respect the user’s selection order.
        configuration.selection = .ordered
        // TODO: What should the selection limit be?
        configuration.selectionLimit = 20
        // Set the preselected asset identifiers with the identifiers that the app tracks.
        // configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        origin.present(picker, animated: true)


//        let options = WPMediaPickerOptions()
//        options.showMostRecentFirst = true
//        options.filter = [.all]
//        options.allowCaptureOfMedia = false
//        // TODO: How do we handle GIFs?
//        options.badgedUTTypes = [UTType.gif.identifier]
//        options.preferredStatusBarStyle = WPStyleGuide.preferredStatusBarStyle
//
//        let picker = WPNavigationMediaPickerViewController(options: options)
//        picker.dataSource = dataSource
//        picker.delegate = delegate
//        picker.mediaPicker.registerClass(forReusableCellOverlayViews: DisabledVideoOverlay.self)
//
//        if FeatureFlag.mediaPickerPermissionsNotice.enabled {
//            picker.mediaPicker.registerClass(forCustomHeaderView: DeviceMediaPermissionsHeader.self)
//        }
//
//        origin.present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // TODO: We could load PHAssets for the given picker results, but that requires access to PHPhotoLibrary

//        let result = PHAsset.fetchAssets(withLocalIdentifiers: results.compactMap(\.assetIdentifier), options: nil)
//        var assets: [PHAsset] = []
//        for index in 0..<result.count {
//            assets.append(result[index])
//        }

        // TODO: update the API to not include WPMediaPickerViewController
        let stub = WPMediaPickerViewController()
        let assets = results.map(PhotoPickerResult.init)
        self.delegate?.mediaPickerController(stub, didFinishPicking: assets)
    }
}

final class PhotoPickerResult: NSObject, WPMediaAsset, ExportableAsset {
    let result: PHPickerResult
    private var itemProvider: NSItemProvider { result.itemProvider }
    private var requests: [WPMediaRequestID: Progress] = [:]
    private var nextRequestID: WPMediaRequestID = 0

    init(result: PHPickerResult) {
        self.result = result
    }

    // TODO: Is this image going to be used to display the thumbnails?
    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        guard itemProvider.canLoadObject(ofClass: UIImage.self) else {
            completionHandler(nil, nil)
            return -1
        }
        nextRequestID += 1
        let requestID = nextRequestID
        requests[requestID] = itemProvider.loadObject(ofClass: UIImage.self) { image, error in
            // TODO: Do we need DispatchQueue.main.async? It was in the sample code.
                DispatchQueue.main.async {
                    completionHandler(image as? UIImage, error)
                }
            }
        return requestID
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        if let progress = requests.removeValue(forKey: requestID) {
            progress.cancel()
        }
    }

    func videoAsset(completionHandler: @escaping WPMediaAssetBlock) -> WPMediaRequestID {
        // TODO: Add support for video (see sample code below)
//        itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
//            progress = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
//                do {
//                    guard let url = url, error == nil else {
//                        throw error ?? NSError(domain: NSFileProviderErrorDomain, code: -1, userInfo: nil)
//                    }
//                    let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
//                    try? FileManager.default.removeItem(at: localURL)
//                    try FileManager.default.copyItem(at: url, to: localURL)
//                    DispatchQueue.main.async {
//                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: localURL)
//                    }
//                } catch let catchedError {
//                    DispatchQueue.main.async {
//                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: catchedError)
//                    }
//                }
//            }
        return -1
    }

    // TODO: Add support for other asset types
    var assetMediaType: MediaType {
        return .image
    }

    func assetType() -> WPMediaType {
        // TODO: Add support for video (using itemProvider?)
        return .image
    }

    func duration() -> TimeInterval {
        0
    }

    func baseAsset() -> Any {
        self
    }

    func identifier() -> String {
        result.assetIdentifier ?? ""
    }

    func date() -> Date {
        Date()
    }

    // TODO: Why do we need this?
    func pixelSize() -> CGSize {
        .zero
    }
}

final class PhotoPickerMediaAssetExporter: MediaExporter {
    // TODO: ???
    var mediaDirectoryType: MediaDirectory = .uploads

    func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        let itemProvider = result.result.itemProvider
        return itemProvider.loadObject(ofClass: UIImage.self) { image, error in
//            guard let self else { return }

            // TODO: Do we need DispatchQueue.main.async? It was in the sample code.
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    // TODO: Simplify this (copy-pasted from MediaAssetExporter)

                    // Hand off the image export to a shared image writer.
                    let exporter = MediaImageExporter(image: image, filename: nil)
                    exporter.mediaDirectoryType = self.mediaDirectoryType
//                    if let options = self.imageOptions {
//                        exporter.options = options
//                        // TODO: Get UTI from the asset
////                        if options.exportImageType == nil {
////                            exporter.options.exportImageType = self.preferedExportTypeFor(uti: utiToUse)
////                        }
//                    }
                    let exportProgress = exporter.export(onCompletion: { (imageExport) in
                        onCompletion(imageExport)
                    }, onError: onError)

                } else {
                    onError(MediaAssetExporter.AssetExportError.failedLoadingPHImageManagerRequest) // TODO: Add proper error
                }
            }
        }
    }

    let result: PhotoPickerResult

    init(result: PhotoPickerResult) {
        self.result = result
    }


}

/// An overlay for videos that exceed allowed duration
class DisabledVideoOverlay: UIView {

    static let overlayTransparency: CGFloat = 0.8

    init() {
        super.init(frame: .zero)
        backgroundColor = .gray.withAlphaComponent(Self.overlayTransparency)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
