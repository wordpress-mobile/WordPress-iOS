import WPMediaPicker
import Kanvas
import Gridicons
import Combine

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func present(on: UIViewController,
                               with settings: CameraSettings,
                               delegate: KanvasMediaPickerViewControllerDelegate,
                               completion: @escaping () -> Void) {

        guard let blog = (on as? StoryEditor)?.post.blog else {
            DDLogWarn("No blog for Kanvas Media Picker")
            return
        }

        let tabBar = PortraitTabBarController()

        let mediaPickerDelegate = MediaPickerDelegate(kanvasDelegate: delegate, presenter: tabBar)
        let options = WPMediaPickerOptions()
        options.allowCaptureOfMedia = false

        let photoPicker = WPMediaPickerForKanvas(options: options, delegate: mediaPickerDelegate)
        photoPicker.dataSource = WPPHAssetDataSource.sharedInstance()
        photoPicker.tabBarItem = UITabBarItem(title: Constants.photosTabBarTitle, image: Constants.photosTabBarIcon, tag: 0)


        let mediaPicker = WPMediaPickerForKanvas(options: options, delegate: mediaPickerDelegate)
        mediaPicker.startOnGroupSelector = false
        mediaPicker.showGroupSelector = false

        pickerDataSource = MediaLibraryPickerDataSource(blog: blog)
        mediaPicker.dataSource = pickerDataSource
        mediaPicker.tabBarItem = UITabBarItem(title: Constants.mediaPickerTabBarTitle, image: Constants.mediaPickerTabBarIcon, tag: 0)

        tabBar.viewControllers = [
            photoPicker,
            mediaPicker
        ]
        on.present(tabBar, animated: true, completion: completion)
    }
}

class MediaPickerDelegate: NSObject, WPMediaPickerViewControllerDelegate {

    private weak var kanvasDelegate: KanvasMediaPickerViewControllerDelegate?
    private weak var presenter: UIViewController?

    private var cancellables = Set<AnyCancellable>()

    init(kanvasDelegate: KanvasMediaPickerViewControllerDelegate, presenter: UIViewController) {
        self.kanvasDelegate = kanvasDelegate
        self.presenter = presenter
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        presenter?.dismiss(animated: true, completion: nil)
    }

    enum ExportErrors: Error {
        case missingImage
        case missingVideoURL
        case failedVideoDownload
        case unexpectedAssetType // `WPMediaAsset.assetType()` was not an image or video
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
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "Dismiss", style: .default) { _ in
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
}

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
