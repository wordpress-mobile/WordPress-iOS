import WPMediaPicker
import Kanvas
import Gridicons
import Combine
import Photos
import PhotosUI

class PortraitTabBarController: UITabBarController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
}

class WPMediaPickerForKanvas: WPNavigationMediaPickerViewController, MediaPicker {

    private struct Constants {
        static let photosTabBarTitle: String = NSLocalizedString("Photos", comment: "Tab bar title for the Photos tab in Media Picker")
        static let photosTabBarIcon: UIImage? = .gridicon(.imageMultiple)
        static let mediaPickerTabBarTitle: String = NSLocalizedString("Media", comment: "Tab bar title for the Media tab in Media Picker")
        static let mediaPickerTabBarIcon: UIImage? = UIImage(named: "icon-wp")?.af_imageAspectScaled(toFit: CGSize(width: 30, height: 30))
    }

    static var pickerDataSource: MediaLibraryPickerDataSource?

    private let delegateHandler: MediaPickerDelegate

    init(options: WPMediaPickerOptions, delegate: MediaPickerDelegate) {
        self.delegateHandler = delegate
        super.init(options: options)
        self.delegate = delegate
        self.mediaPicker.mediaPickerDelegate = delegate
        self.mediaPicker.registerClass(forReusableCellOverlayViews: DisabledVideoOverlay.self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func present(on presentingViewController: UIViewController,
                               with settings: CameraSettings,
                               delegate: KanvasMediaPickerViewControllerDelegate,
                               completion: @escaping () -> Void) {

        guard let blog = (presentingViewController as? StoryEditor)?.post.blog else {
            DDLogWarn("No blog for Kanvas Media Picker")
            return
        }

        let tabBar = PortraitTabBarController()

        let mediaPickerDelegate = MediaPickerDelegate(kanvasDelegate: delegate,
                                                      presenter: presentingViewController,
                                                      blog: blog)
        let options = WPMediaPickerOptions()
        options.allowCaptureOfMedia = false

        let photoPicker = WPMediaPickerForKanvas(options: options, delegate: mediaPickerDelegate)
        photoPicker.dataSource = WPPHAssetDataSource.sharedInstance()
        photoPicker.tabBarItem = UITabBarItem(title: Constants.photosTabBarTitle, image: Constants.photosTabBarIcon, tag: 0)
        photoPicker.mediaPicker.registerClass(forCustomHeaderView: DeviceMediaPermissionsHeader.self)


        let mediaPicker = WPMediaPickerForKanvas(options: options, delegate: mediaPickerDelegate)
        mediaPicker.startOnGroupSelector = false
        mediaPicker.showGroupSelector = false

        pickerDataSource = MediaLibraryPickerDataSource(blog: blog)
        mediaPicker.dataSource = pickerDataSource
        mediaPicker.tabBarItem = UITabBarItem(title: Constants.mediaPickerTabBarTitle, image: Constants.mediaPickerTabBarIcon, tag: 0)


        let photosPicker = PHPickerViewController(configuration: {
            var configuration = PHPickerConfiguration()
            configuration.preferredAssetRepresentationMode = .current
            configuration.selection = .ordered
            configuration.selectionLimit = 0
            return configuration
        }())
        photosPicker.delegate = mediaPickerDelegate
        photosPicker.tabBarItem = UITabBarItem(title: Constants.photosTabBarTitle, image: Constants.photosTabBarIcon, tag: 0)

        retainedDelegate = mediaPickerDelegate
        presentingViewController.present(photosPicker, animated: true, completion: completion)
    }
}

private var retainedDelegate: MediaPickerDelegate?

class MediaPickerDelegate: NSObject, PHPickerViewControllerDelegate, WPMediaPickerViewControllerDelegate {

    private weak var kanvasDelegate: KanvasMediaPickerViewControllerDelegate?
    private weak var presenter: UIViewController?
    private let blog: Blog
    private var cancellables = Set<AnyCancellable>()

    init(kanvasDelegate: KanvasMediaPickerViewControllerDelegate,
         presenter: UIViewController,
         blog: Blog) {
        self.kanvasDelegate = kanvasDelegate
        self.presenter = presenter
        self.blog = blog
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            picker.presentingViewController?.dismiss(animated: true)
            return
        }
        Task {
            await process(results, picker: picker)
        }
    }

    @MainActor
    private func process(_ results: [PHPickerResult], picker: PHPickerViewController) async {
        startLoading(in: picker)
        defer { stopLoading() }

        do {
            let selection = try await exportPickedMedia(from: results, blog: blog)
            picker.presentingViewController?.dismiss(animated: true)
            kanvasDelegate?.didPick(media: selection)
        } catch {
            if let error = error as? VideoExportError,
               case .videoLengthLimitExceeded = error {
                presentVideoLimitExceededFromPicker(on: picker)
            } else {
                showError(error, in: picker)
            }
        }
    }

    // MARK: - WPMediaPickerViewControllerDelegate

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        presenter?.dismiss(animated: true, completion: nil)
    }

    enum ExportErrors: Error {
        case missingImage
        case missingVideoURL
        case failedVideoDownload
        case unexpectedAssetType
    }

    private struct ExportOutput {
        let index: Int
        let media: PickedMedia
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {

        let selected = picker.selectedAssets
        picker.clearSelectedAssets(false)
        picker.reloadInputViews() // Reloads the bottom bar so it is hidden while loading

        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setContainerView(presenter?.view)
        SVProgressHUD.showProgress(-1)

        let mediaExports: [AnyPublisher<(Int, PickedMedia), Error>] = assets.enumerated().map { (index, asset) -> AnyPublisher<(Int, PickedMedia), Error> in
            switch asset.assetType() {
            case .image:
                return asset.imagePublisher().map { (image, url) in
                    (index, PickedMedia.image(image, url))
                }.eraseToAnyPublisher()
            case .video:
                return asset.videoURLPublisher().map { url in
                    (index, PickedMedia.video(url))
                }.eraseToAnyPublisher()
            default:
                return Fail(outputType: (Int, PickedMedia).self, failure: ExportErrors.unexpectedAssetType).eraseToAnyPublisher()
            }
        }

        Publishers.MergeMany(mediaExports)
        .collect(assets.count) // Wait for all assets to complete before receiving.
        .map { media in
            // Sort our media back into the original order since they may be mixed up after export.
            return media.sorted { left, right in
                return left.0 < right.0
            }.map {
                return $0.1
            }
        }
        .receive(on: DispatchQueue.main).sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                picker.selectedAssets = selected

                let title = NSLocalizedString("Failed Media Export", comment: "Error title when picked media cannot be imported into stories.")
                let message = NSLocalizedString("Your media could not be exported. If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Error message when picked media cannot be imported into stories.")
                let dismissTitle = NSLocalizedString(
                    "mediaPicker.failedMediaExportAlert.dismissButton",
                    value: "Dismiss",
                    comment: "The title of the button to dismiss the alert shown when the picked media cannot be imported into stories."
                )
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let dismiss = UIAlertAction(title: dismissTitle, style: .default) { _ in
                    alert.dismiss(animated: true, completion: nil)
                }
                alert.addAction(dismiss)
                picker.present(alert, animated: true, completion: nil)

                DDLogError("Failed to export picked Stories media: \(error)")
            case .finished:
                break
            }
            SVProgressHUD.dismiss()
        }, receiveValue: { [weak self] media in
            self?.presenter?.dismiss(animated: true, completion: nil)
            self?.kanvasDelegate?.didPick(media: media)
        }).store(in: &cancellables)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShowOverlayViewForCellFor asset: WPMediaAsset) -> Bool {
        picker != self && !blog.canUploadAsset(asset)
    }

    func mediaPickerControllerShouldShowCustomHeaderView(_ picker: WPMediaPickerViewController) -> Bool {
        guard picker.dataSource is WPPHAssetDataSource else {
            return false
        }

        return PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
    }

    func mediaPickerControllerReferenceSize(forCustomHeaderView picker: WPMediaPickerViewController) -> CGSize {
        let header = DeviceMediaPermissionsHeader()
        header.translatesAutoresizingMaskIntoConstraints = false

        return header.referenceSizeInView(picker.view)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, configureCustomHeaderView headerView: UICollectionReusableView) {
        guard let headerView = headerView as? DeviceMediaPermissionsHeader else {
            return
        }

        headerView.presenter = picker
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldSelect asset: WPMediaAsset) -> Bool {
        if picker != self, !blog.canUploadAsset(asset) {
            presentVideoLimitExceededFromPicker(on: picker)
            return false
        }
        return true
    }

    // MARK: - Helpers

    private func startLoading(in viewController: UIViewController) {
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setContainerView(viewController.view)
        SVProgressHUD.showProgress(-1)
    }

    private func stopLoading() {
        SVProgressHUD.dismiss()
    }

    private func showError(_ error: Error, in viewController: UIViewController) {
        let title = NSLocalizedString("mediaPicker.failedMediaExportAlert.title", value: "Failed Media Export", comment: "Error title when picked media cannot be imported into stories.")
        let message = NSLocalizedString("mediaPicker.failedMediaExportAlert.message", value: "Your media could not be exported. If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Error message when picked media cannot be imported into stories.")
        let dismissTitle = NSLocalizedString(
            "mediaPicker.failedMediaExportAlert.dismissButton",
            value: "Dismiss",
            comment: "The title of the button to dismiss the alert shown when the picked media cannot be imported into stories."
        )
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismiss = UIAlertAction(title: dismissTitle, style: .default) { _ in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(dismiss)
        viewController.present(alert, animated: true, completion: nil)

        DDLogError("Failed to export picked Stories media: \(error)")
    }
}

// MARK: - Helpers

@MainActor
private func exportPickedMedia(from results: [PHPickerResult], blog: Blog) async throws -> [PickedMedia] {
    try await withThrowingTaskGroup(of: PickedMedia.self) { group in
        for result in results {
            group.addTask { @MainActor in
                try await exportPickedMedia(from: result.itemProvider, blog: blog)
            }
        }
        var selection: [PickedMedia] = []
        for try await media in group {
            selection.append(media)
        }
        return selection
    }
}

// Isolating it on the @MainActor because NSItemProvider is non-Sendable.
@MainActor
private func exportPickedMedia(from provider: NSItemProvider, blog: Blog) async throws -> PickedMedia {
    if provider.hasConformingType(.image) {
        let image = try await NSItemProvider.image(for: provider)
        let imageSize = image.size.scaled(by: image.scale)
        let targetSize = getTargetSize(forImageSize: imageSize, targetSize: CGSize(width: 2048, height: 2048))
        let resized = await Task.detached {
            image.resizedImage(targetSize, interpolationQuality: .default)
        }.value
        return PickedMedia.image(resized ?? image, nil)
    } else if provider.hasConformingType(.movie) || provider.hasConformingType(.video) {
        let videoURL = try await NSItemProvider.video(for: provider)
        guard blog.canUploadVideo(from: videoURL) else {
            throw VideoExportError.videoLengthLimitExceeded
        }
        let asset = AVAsset(url: videoURL)
        // important: Kanvas doesn't support video orientation!
        guard asset.tracks(withMediaType: .video).first?.preferredTransform != .identity else {
            return PickedMedia.video(videoURL)
        }
        defer { try? FileManager.default.removeItem(at: videoURL) }
        let exportURL = try await asset.exportFixingOrientation(to: videoURL
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString))
        return PickedMedia.video(exportURL)
    } else {
        throw MediaPickerDelegate.ExportErrors.unexpectedAssetType
    }
}

private enum VideoExportError: Error {
    case videoLengthLimitExceeded
}

/// - parameter imageSize: Image size in pixels.
private func getTargetSize(forImageSize imageSize: CGSize, targetSize originalTargetSize: CGSize) -> CGSize {
    guard imageSize.width > 0 && imageSize.height > 0 else {
        return originalTargetSize
    }
    // Scale image to fit the target size but avoid upscaling
    let scale = min(1, min(
        originalTargetSize.width / imageSize.width,
        originalTargetSize.height / imageSize.height
    ))
    return imageSize.scaled(by: scale).rounded()
}

// MARK: - User messages for video limits allowances

extension MediaPickerDelegate: VideoLimitsAlertPresenter {}

// MARK: Media Export extensions

enum VideoURLErrors: Error {
    case videoAssetExportFailed
    case failedVideoDownload
}

private extension PHAsset {
    // TODO: Update MPMediaPicker with degraded image implementation.
    func sizedImage(with size: CGSize, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: self, targetSize: size, contentMode: .aspectFit, options: options, resultHandler: { (result, info) in
            let error = info?[PHImageErrorKey] as? Error
            let cancelled = info?[PHImageCancelledKey] as? Bool
            if let error = error, cancelled != true {
                completionHandler(nil, error)
            }
            // Wait for resized image instead of thumbnail
            if let degraded = info?[PHImageResultIsDegradedKey] as? Bool, degraded == false {
                completionHandler(result, nil)
            }
        })
    }
}

extension WPMediaAsset {

    private func fit(size: CGSize) -> CGSize {
        let assetSize = pixelSize()
        let aspect = assetSize.width / assetSize.height
        if size.width / aspect <= size.height {
            return CGSize(width: size.width, height: round(size.width / aspect))
        } else {
            return CGSize(width: round(size.height * aspect), height: round(size.height))
        }
    }

    func sizedImage(with size: CGSize, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        if let asset = self as? PHAsset {
            asset.sizedImage(with: size, completionHandler: completionHandler)
        } else {
            image(with: size, completionHandler: completionHandler)
        }
    }

    /// Produces a Publisher which contains a resulting image and image URL where available.
    /// - Returns: A Publisher containing resuling image, URL and any errors during export.
    func imagePublisher() -> AnyPublisher<(UIImage, URL?), Error> {
        return Future<(UIImage, URL?), Error> { promise in
            let size = self.fit(size: UIScreen.main.nativeBounds.size)
            self.sizedImage(with: size) { (image, error) in
                guard let image = image else {
                    if let error = error {
                        return promise(.failure(error))
                    }
                    return promise(.failure(WPMediaAssetError.imageAssetExportFailed))
                }
                return promise(.success((image, nil)))
            }
        }.eraseToAnyPublisher()
    }

    /// Produces a Publisher containing a URL of saved video and any errors which occurred.
    ///
    /// - Parameters:
    ///     - skipTransformCheck: Skips the transform check.
    ///
    /// - Returns: Publisher containing the URL to a saved video and any errors which occurred.
    ///
    func videoURLPublisher(skipTransformCheck: Bool = false) -> AnyPublisher<URL, Error> {
        videoAssetPublisher().tryMap { asset -> AnyPublisher<URL, Error> in
            let filename = UUID().uuidString
            let url = try StoryEditor.mediaCacheDirectory().appendingPathComponent(filename)
            let urlAsset = asset as? AVURLAsset

            // Portrait video is exported so that it is rotated for use in Kanvas.
            // Once the Metal renderer is fixed to properly rotate this media, this can be removed.
            let trackTransform = asset.tracks(withMediaType: .video).first?.preferredTransform

            // DRM: I moved this logic into a variable because it seems to be completely out of place in this method
            // and it was causing some issues when sharing videos that needed to be downloaded.  I added a parameter
            // with a default value that will make sure this check is executed for any old code.
            let transformCheck = skipTransformCheck || trackTransform == CGAffineTransform.identity

            if let assetURL = urlAsset?.url, transformCheck {
                let exportURL = url.appendingPathExtension(assetURL.pathExtension)
                if urlAsset?.url.scheme != "file" {
                    // Download any file which isn't local and move it to the proper location.
                    return URLSession.shared.downloadTaskPublisher(url: assetURL).tryMap { (location, _) -> URL in
                        if let location = location {
                            try FileManager.default.moveItem(at: location, to: exportURL)
                            return exportURL
                        } else {
                            return url
                        }
                    }.eraseToAnyPublisher()
                } else {
                    // Return the local asset URL which we will use directly.
                    return Just(assetURL).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
            } else {
                // Export any other file which isn't an AVURLAsset since we don't have a URL to use.
                return try asset.exportPublisher(url: url)
            }
        }.flatMap { publisher -> AnyPublisher<URL, Error> in
            return publisher
        }.eraseToAnyPublisher()
    }
}

private extension AVAsset {
    func exportFixingOrientation(to exportURL: URL) async throws -> URL {
        let exportURL = exportURL.deletingPathExtension().appendingPathExtension("mov")
        let (composition, videoComposition) = try rotate()

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset1920x1080) else {
            throw WPMediaAssetError.videoAssetExportFailed
        }
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .mov
        await exportSession.export()
        if let error = exportSession.error {
            throw error
        }
        return exportURL
    }

    func exportPublisher(url: URL) throws -> AnyPublisher<URL, Error> {
        let exportURL = url.appendingPathExtension("mov")

        let (composition, videoComposition) = try rotate()

        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset1920x1080) {
            exportSession.videoComposition = videoComposition
            exportSession.outputURL = exportURL
            exportSession.outputFileType = .mov
            return exportSession.exportPublisher(url: exportURL)
        } else {
            throw WPMediaAssetError.videoAssetExportFailed
        }
    }

    /// Applies the `preferredTransform` of the video track.
    /// - Returns: Returns both an AVMutableComposition containing video + audio and an AVVideoComposition of the rotate video.
    private func rotate() throws -> (AVMutableComposition, AVVideoComposition) {
        guard let videoTrack = tracks(withMediaType: .video).first else {
            throw WPMediaAssetError.assetMissingVideoTrack
        }

        let videoComposition = AVMutableVideoComposition(propertiesOf: self)
        let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        videoComposition.renderSize = CGSize(width: abs(size.width), height: abs(size.height))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: videoTrack.timeRange.duration)

        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        transformer.setTransform(videoTrack.preferredTransform, at: .zero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]

        let composition = AVMutableComposition()

        let mutableVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? mutableVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, end: videoTrack.timeRange.duration), of: videoTrack, at: .zero)

        if let audioTrack = tracks(withMediaType: .audio).first {
            let mutableAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? mutableAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: audioTrack.timeRange.duration), of: audioTrack, at: .zero)
        }

        return (composition, videoComposition)
    }
}


enum WPMediaAssetError: Error {
    case imageAssetExportFailed
    case videoAssetExportFailed
    case assetMissingVideoTrack
}

extension WPMediaAsset {
    /// Produces a Publisher  `AVAsset` from a `WPMediaAsset` object.
    /// - Returns: Publisher with an AVAsset and any errors which occur during export.
    func videoAssetPublisher() -> AnyPublisher<AVAsset, Error> {
        Future<AVAsset, Error> { [weak self] promise in
            self?.videoAsset(completionHandler: { asset, error in
                guard let asset = asset else {
                    if let error = error {
                        return promise(.failure(error))
                    }
                    return promise(.failure(WPMediaAssetError.videoAssetExportFailed))
                }
                promise(.success(asset))
            })
        }.eraseToAnyPublisher()
    }
}

extension URLSession {
    typealias DownloadTaskResult = (location: URL?, response: URLResponse?)
    /// Produces a Publisher which contains the result of a Download Task
    /// - Parameter url: The URL to download from.
    /// - Returns: A publisher containing the result of a Download Task and any errors which occur during the download.
    func downloadTaskPublisher(url: URL) -> AnyPublisher<DownloadTaskResult, Error> {
        return Deferred {
            Future<DownloadTaskResult, Error> { promise in
                URLSession.shared.downloadTask(with: url) { (location, response, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success((location, response)))
                    }
                }.resume()
            }
        }.eraseToAnyPublisher()
    }
}

extension AVAssetExportSession {
    /// Produces a publisher which wraps the export of a video.
    /// - Parameter url: The location to save the video to.
    /// - Returns: A publisher containing the location the asset was saved to and an error.
    func exportPublisher(url: URL) -> AnyPublisher<URL, Error> {
        return Deferred {
            Future<URL, Error> { [weak self] promise in
                self?.exportAsynchronously { [weak self] in
                    if let error = self?.error {
                        promise(.failure(error))
                    }
                    promise(.success(url))
                }
            }
        }.handleEvents(receiveCancel: {
            self.cancelExport()
        }).eraseToAnyPublisher()
    }
}

extension MediaLibraryGroup {

    @objc(getMediaLibraryCountForMediaTypes:ofBlog:success:failure:)
    func getMediaLibraryCount(forMediaTypes types: Set<NSNumber>, of blog: Blog, success: @escaping (Int) -> Void, failure: @escaping (Error) -> Void) {
        guard let remote = MediaServiceRemoteFactory().remote(for: blog) else {
            DispatchQueue.main.async {
                failure(MediaRepository.Error.remoteAPIUnavailable)
            }
            return
        }

        let mediaTypes = types.compactMap {
            MediaType(rawValue: $0.uintValue)
        }

        Task { @MainActor in
            do {
                let total = try await remote.getMediaLibraryCount(forMediaTypes: mediaTypes)
                success(total)
            } catch {
                failure(error)
            }
        }
    }

}
