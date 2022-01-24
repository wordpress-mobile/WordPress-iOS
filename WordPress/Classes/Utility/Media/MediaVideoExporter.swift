import Foundation
import MobileCoreServices

/// Media export handling of Videos from PHAssets or AVAssets.
///
class MediaVideoExporter: MediaExporter {

    var mediaDirectoryType: MediaDirectory = .uploads

    /// Export options.
    ///
    var options = Options()

    /// Available options for a video export.
    ///
    struct Options: MediaExportingOptions {

        /// The export preset to use when exporting a video, see AVAssetExportSession documentation.
        ///
        var exportPreset = AVAssetExportPresetHighestQuality

        /// The preferred UTType of the output video file.
        ///
        /// - Note: the exporter will try to honor the type,
        ///   if both the exporter and AVAsset support the type for exporting.
        ///
        var preferredExportVideoType: String?

        // MARK: - MediaExporting

        var stripsGeoLocationIfNeeded = false
    }

    public enum VideoExportError: MediaExportError {
        case videoAssetWasDetectedAsNotExportable
        case videoExportSessionDoesNotSupportVideoOutputType
        case failedToInitializeVideoExportSession
        case failedExportingVideoDuringExportSession
        case failedGeneratingVideoPreviewImage
        case videoExportSessionCancelled

        var description: String {
            switch self {
            case .failedGeneratingVideoPreviewImage:
                return NSLocalizedString("Video Preview Unavailable", comment: "Message shown if a video preview image is unavailable while the video is being uploaded.")
            case .videoExportSessionCancelled:
                return NSLocalizedString("Video export canceled.", comment: "Message shown if a video export is canceled by the user.")
            default:
                return NSLocalizedString("The video could not be added to the Media Library.", comment: "Message shown when a video failed to load while trying to add it to the Media library.")
            }
        }
    }

    private let url: URL?
    private let session: AVAssetExportSession?
    private let filename: String?

    private init(url: URL?, session: AVAssetExportSession?, filename: String?) {
        self.url = url
        self.session = session
        self.filename = filename
    }

    convenience public init(url: URL) {
        self.init(url: url, session: nil, filename: url.lastPathComponent)
    }

    convenience public init(session: AVAssetExportSession, filename: String? = nil) {
        self.init(url: nil, session: session, filename: filename)
    }

    @discardableResult public func export(onCompletion: @escaping OnMediaExport, onError: @escaping (MediaExportError) -> Void) -> Progress {
        if let url = url {
            return exportVideo(atURL: url, onCompletion: onCompletion, onError: onError)
        } else if let session = session {
            return exportVideo(with: session, filename: filename, onCompletion: onCompletion, onError: onError)
        }
        return Progress.discreteCompletedProgress()
    }

    /// Exports a known video at a URL asynchronously.
    ///
    @discardableResult func exportVideo(atURL url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        let asset = AVURLAsset(url: url)
        guard asset.isExportable else {
            onError(exporterErrorWith(error: VideoExportError.videoAssetWasDetectedAsNotExportable))
            return Progress.discreteCompletedProgress()
        }

        guard let session = AVAssetExportSession(asset: asset, presetName: options.exportPreset) else {
            onError(exporterErrorWith(error: VideoExportError.failedToInitializeVideoExportSession))
            return Progress.discreteCompletedProgress()
        }
        return exportVideo(with: session,
                    filename: url.lastPathComponent,
                    onCompletion: onCompletion,
                    onError: onError)
    }

    /// Configures an AVAssetExportSession and exports the video asynchronously.
    ///
    @discardableResult func exportVideo(with session: AVAssetExportSession, filename: String?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        var outputType = options.preferredExportVideoType ?? supportedExportFileTypes.first!
        // Check if the exportFileType is one of the supported types for the exportSession.
        if session.supportedFileTypes.contains(AVFileType(rawValue: outputType)) == false {
            /*
             If it is not supported by the session, try and find one
             of the exporter's own supported types within the session's.
             Ideally we return the first type, as an order of preference from supportedExportFileTypes.
            */
            guard let supportedType = supportedExportFileTypes.first(where: { session.supportedFileTypes.contains(AVFileType(rawValue: $0)) }) else {
                // No supported types available, throw an error.
                onError(exporterErrorWith(error: VideoExportError.videoExportSessionDoesNotSupportVideoOutputType))
                return Progress.discreteCompletedProgress()
            }
            outputType = supportedType
        }

        // Generate a URL for exported video.
        let mediaURL: URL
        do {
            mediaURL = try mediaFileManager.makeLocalMediaURL(withFilename: filename ?? "video",
                                                                fileExtension: URL.fileExtensionForUTType(outputType))
        } catch {
            onError(exporterErrorWith(error: error))
            return Progress.discreteCompletedProgress()
        }
        session.outputURL = mediaURL
        session.outputFileType = AVFileType(rawValue: outputType)
        session.shouldOptimizeForNetworkUse = true

        // Configure metadata filter for sharing, if we need to remove location data.
        if options.stripsGeoLocationIfNeeded {
            session.metadataItemFilter = AVMetadataItemFilter.forSharing()
        }
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        progress.cancellationHandler = {
            session.cancelExport()
        }
        let observer = VideoSessionProgressObserver(videoSession: session, progressHandler: { value in
            progress.completedUnitCount = Int64(Float(MediaExportProgressUnits.done) * value)
        })

        session.exportAsynchronously {
            observer.stop()
            guard session.status == .completed else {
                if let error = session.error {
                    onError(self.exporterErrorWith(error: error))
                } else {
                    if session.status == .cancelled {
                        onError(VideoExportError.videoExportSessionCancelled)
                    } else {
                        onError(VideoExportError.failedExportingVideoDuringExportSession)
                    }
                }
                return
            }
            progress.completedUnitCount = MediaExportProgressUnits.done
            onCompletion(MediaExport(url: mediaURL,
                                          fileSize: mediaURL.fileSize,
                                          width: mediaURL.pixelSize.width,
                                          height: mediaURL.pixelSize.height,
                                          duration: session.asset.duration.seconds))
        }
        return progress
    }

    /// Generate and export a preview image for a known video at the URL, local file or remote resource.
    ///
    /// - Note: Generates the image asynchronously and could potentially take a bit.
    ///
    /// - imageOptions: ImageExporter options for the generated thumbnail image.
    ///
    @discardableResult
    func exportPreviewImageForVideo(atURL url: URL, imageOptions: MediaImageExporter.Options?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        let asset = AVURLAsset(url: url)
        guard asset.isExportable else {
            onError(exporterErrorWith(error: VideoExportError.videoAssetWasDetectedAsNotExportable))
            return Progress.discreteCompletedProgress()
        }
        let generator = AVAssetImageGenerator(asset: asset)
        if let imageOptions = imageOptions, let maxSize = imageOptions.maximumImageSize {
            generator.maximumSize = CGSize(width: maxSize, height: maxSize)
        }
        generator.appliesPreferredTrackTransform = true
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        progress.isCancellable = true
        progress.cancellationHandler = { () in
            generator.cancelAllCGImageGeneration()
        }
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTimeMake(value: 0, timescale: 1))],
                                                 completionHandler: { (time, cgImage, actualTime, result, error) in
                                                    progress.completedUnitCount = MediaExportProgressUnits.halfDone
                                                    guard let cgImage = cgImage else {
                                                        onError(VideoExportError.failedGeneratingVideoPreviewImage)
                                                        return
                                                    }
                                                    let image = UIImage(cgImage: cgImage)
                                                    let exporter = MediaImageExporter(image: image, filename: UUID().uuidString)
                                                    if let imageOptions = imageOptions {
                                                        exporter.options = imageOptions
                                                    }
                                                    exporter.mediaDirectoryType = self.mediaDirectoryType
                                                    let imageProgress = exporter.export(
                                                                         onCompletion: onCompletion,
                                                                         onError: onError)
                                                    progress.addChild(imageProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        })
        return progress
    }

    /// Returns the supported UTType identifiers for the video exporter.
    ///
    /// - Note: This particular list is for the intention of uploading
    ///   exported videos to WordPress, and what WordPress itself supports.
    ///
    fileprivate var supportedExportFileTypes: [String] {
        let types = [
            kUTTypeMPEG4,
            kUTTypeQuickTimeMovie,
            kUTTypeMPEG,
            kUTTypeAVIMovie
        ]
        return types as [String]
    }
}

fileprivate class VideoSessionProgressObserver {

    let videoSession: AVAssetExportSession
    let progressHandler: (Float) -> ()
    var interrupt: Bool

    init(videoSession: AVAssetExportSession, progressHandler: @escaping (Float) -> ()) {
        self.videoSession = videoSession
        self.progressHandler = progressHandler
        interrupt = false
        self.work()
    }

    private func work() {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(100)) {
            self.progressHandler(self.videoSession.progress)
            if self.videoSession.progress != 1 && !self.interrupt {
                self.work()
            }
        }
    }

    func stop() {
        interrupt = true
    }

    deinit {
        interrupt = true
    }
}
