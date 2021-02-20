import WPMediaPicker
import Kanvas
import Gridicons
import Combine

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

        let tabBar = UITabBarController()

        let mediaPickerDelegate = MediaPickerDelegate(kanvasDelegate: delegate, presenter: tabBar)
        let options = WPMediaPickerOptions()

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

        let mediaExports: [AnyPublisher<(Int, PickedMedia), Error>] = assets.enumerated().map({ (index, asset) -> AnyPublisher<(Int, PickedMedia), Error> in
            switch asset.assetType() {
            case .image:
                return asset.imagePublisher().map({ (image, url) in
                    (index, PickedMedia.image(image, url))
                }).eraseToAnyPublisher()
            case .video:
                return asset.videoURLPublisher().map { url in
                    (index, PickedMedia.video(url))
                }.eraseToAnyPublisher()
            default:
                return Fail(outputType: (Int, PickedMedia).self, failure: ExportErrors.unexpectedAssetType).eraseToAnyPublisher()
            }
        })

        Publishers.MergeMany(mediaExports)
        .collect(assets.count) // Wait for all assets to complete before receiving.
        .map({ media in
            // Sort our media back into the original order since they may be mixed up after export.
            return media.sorted(by: { left, right in
                return left.0 < right.0
            }).map({
                return $0.1
            })
        })
        .receive(on: DispatchQueue.main).sink(receiveCompletion: { completion in

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

extension WPMediaAsset {

    /// Produces a Publisher which contains a resulting image and image URL where available.
    /// - Returns: A Publisher containing resuling image, URL and any errors during export.
    func imagePublisher() -> AnyPublisher<(UIImage, URL?), Error> {
        return Future<(UIImage, URL?), Error> { promise in
            let pixelSize = self.pixelSize()
            self.image(with: pixelSize) { (image, error) in
                guard let image = image else {
                    if let error = error {
                        return promise(.failure(error))
                    }
                    return promise(.failure(WPMediaAssetError.imageAssetExportFailed))
                }
                if image.size.width >= pixelSize.width && image.size.height >= pixelSize.height {
                    return promise(.success((image, nil)))
                }
                // `deliveryMode` is opportunistic so we wait for the full sized asset
            }
        }.eraseToAnyPublisher()
    }

    /// Produces a Publisher containing a URL of saved video and any errors which occurred.
    /// - Returns: Publisher containing the URL to a saved video and any errors which occurred.
    func videoURLPublisher() -> AnyPublisher<URL, Error> {
        return videoAssetPublisher().tryMap({ asset -> AnyPublisher<URL, Error> in
            let filename = UUID().uuidString
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(filename).appendingPathExtension("mp4")
            let urlAsset = asset as? AVURLAsset

            if let assetURL = urlAsset?.url {
                if urlAsset?.url.scheme != "file" {
                    // Download any file which isn't local and move it to the proper location.
                    return URLSession.shared.downloadTaskPublisher(url: assetURL).tryMap({ (location, _) -> URL in
                        if let location = location {
                            try FileManager.default.moveItem(at: location, to: url)
                        }
                        return url
                    }).eraseToAnyPublisher()
                }
                try FileManager.default.moveItem(at: assetURL, to: url)
                return Just(url).setFailureType(to: Error.self).eraseToAnyPublisher()
            } else {
                // Export any other file which isn't an AVURLAsset since we don't have a URL to use.
                if let asset = asset,
                   let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
                    exportSession.outputURL = url
                    exportSession.outputFileType = .mov
                    return exportSession.exportPublisher(url: url)
                } else {
                    throw WPMediaAssetError.videoAssetExportFailed
                }
            }
        }).flatMap { publisher -> AnyPublisher<URL, Error> in
            return publisher
        }.eraseToAnyPublisher()
    }
}

enum WPMediaAssetError: Error {
    case imageAssetExportFailed
    case videoAssetExportFailed
}

extension WPMediaAsset {
    /// Produces a Publisher  `AVAsset` from a `WPMediaAsset` object.
    /// - Returns: Publisher with an AVAsset and any errors which occur during export.
    func videoAssetPublisher() -> AnyPublisher<AVAsset?, Error> {
        return Future<AVAsset?, Error> { [weak self] promise in
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
