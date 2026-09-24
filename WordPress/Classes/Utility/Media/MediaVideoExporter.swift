import UIKit
import WordPressShared
import MobileCoreServices
import UniformTypeIdentifiers
import AVFoundation
import WordPressData

/// Media export handling of Videos from AVAssets.
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

        /// The maximum duration. The exporter throws an error if the video is
        /// longer than the limit.
        var durationLimit: TimeInterval?

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
        case videoLimitExceeded

        public var errorDescription: String? { description }

        var description: String {
            switch self {
            case .failedGeneratingVideoPreviewImage:
                return NSLocalizedString("Video Preview Unavailable", comment: "Message shown if a video preview image is unavailable while the video is being uploaded.")
            case .videoExportSessionCancelled:
                return NSLocalizedString("Video export canceled.", comment: "Message shown if a video export is canceled by the user.")
            case .videoLimitExceeded:
                return NSLocalizedString("mediaExporter.videoLimitExceededError", value: "Uploading videos longer than 5 minutes requires a paid plan.", comment: "Message of an alert informing users that the video they are trying to select is not allowed.")
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
        if let url {
            return exportVideo(atURL: url, onCompletion: onCompletion, onError: onError)
        } else if let session {
            return exportVideo(with: session, filename: filename, onCompletion: onCompletion, onError: onError)
        }
        return Progress.discreteCompletedProgress()
    }

    /// Exports a known video at a URL asynchronously.
    ///
    @discardableResult func exportVideo(atURL url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        report(progress: progress, onCompletion: onCompletion, onError: onError) {
            let asset = AVURLAsset(url: url)
            guard let isExportable = try? await asset.load(.isExportable), isExportable else {
                throw VideoExportError.videoAssetWasDetectedAsNotExportable
            }
            guard let session = AVAssetExportSession(asset: asset, presetName: self.options.exportPreset) else {
                throw VideoExportError.failedToInitializeVideoExportSession
            }
            return try await self.exportVideo(with: session, filename: url.lastPathComponent, progress: progress)
        }
        return progress
    }

    /// Configures an AVAssetExportSession and exports the video asynchronously.
    ///
    @discardableResult func exportVideo(with session: AVAssetExportSession, filename: String?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        report(progress: progress, onCompletion: onCompletion, onError: onError) {
            try await self.exportVideo(with: session, filename: filename, progress: progress)
        }
        return progress
    }

    /// Runs `export` in a task and reports its result through the callbacks.
    ///
    /// Cancelling `progress` cancels the task.
    private func report(progress: Progress, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError, export: @escaping () async throws -> MediaExport) {
        let task = Task {
            do {
                onCompletion(try await export())
            } catch {
                // A cancelled task can throw errors other than `CancellationError`,
                // e.g. a cancelled `isExportable` load reads as "not exportable".
                // Callers such as Aztec only treat `videoExportSessionCancelled`
                // as a cancellation.
                let exportError: MediaExportError = progress.isCancelled ? VideoExportError.videoExportSessionCancelled : exporterErrorWith(error: error)
                fail(progress, with: exportError, onError: onError)
            }
        }
        progress.cancellationHandler = {
            task.cancel()
        }
    }

    private func exportVideo(with session: AVAssetExportSession, filename: String?, progress: Progress) async throws -> MediaExport {
        // The synchronous `AVAsset.duration` this replaces returned zero when the
        // asset couldn't be read, which let the export go ahead.
        let duration = (try? await session.asset.load(.duration)) ?? .zero
        if let limit = options.durationLimit, CMTimeGetSeconds(duration) > limit {
            throw VideoExportError.videoLimitExceeded
        }

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
                throw VideoExportError.videoExportSessionDoesNotSupportVideoOutputType
            }
            outputType = supportedType
        }

        // Generate a URL for exported video.
        let mediaURL = try mediaFileManager.makeLocalMediaURL(
            withFilename: filename ?? "video",
            fileExtension: UTType(outputType)?.preferredFilenameExtension
        )
        session.shouldOptimizeForNetworkUse = true

        // Configure metadata filter for sharing, if we need to remove location data.
        if options.stripsGeoLocationIfNeeded {
            session.metadataItemFilter = AVMetadataItemFilter.forSharing()
        }

        let observer = VideoSessionProgressObserver(videoSession: session, progressHandler: { value in
            progress.completedUnitCount = Int64(Float(MediaExportProgressUnits.done) * value)
        })
        defer { observer.stop() }
        try await session.export(to: mediaURL, as: AVFileType(rawValue: outputType))

        let pixelSize = await mediaURL.videoPixelSize
        progress.completedUnitCount = MediaExportProgressUnits.done
        return MediaExport(url: mediaURL,
                           fileSize: mediaURL.fileSize,
                           width: pixelSize.width,
                           height: pixelSize.height,
                           duration: CMTimeGetSeconds(duration))
    }

    /// Reports a failure and marks the progress as finished.
    ///
    /// The progress is finished because the callers used to return an already
    /// completed progress when the export failed before the session started.
    private func fail(_ progress: Progress, with error: MediaExportError, onError: OnExportError) {
        progress.completedUnitCount = progress.totalUnitCount
        onError(error)
    }

    /// Generate and export a preview image for a known video at the URL, local file or remote resource.
    ///
    /// - Note: Generates the image asynchronously and could potentially take a bit.
    ///
    /// - imageOptions: ImageExporter options for the generated thumbnail image.
    ///
    @discardableResult
    func exportPreviewImageForVideo(atURL url: URL, imageOptions: MediaImageExporter.Options?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        progress.isCancellable = true
        Task {
            let asset = AVURLAsset(url: url)
            guard let isExportable = try? await asset.load(.isExportable), isExportable else {
                self.fail(progress, with: self.exporterErrorWith(error: VideoExportError.videoAssetWasDetectedAsNotExportable), onError: onError)
                return
            }
            self.generatePreviewImage(for: asset, imageOptions: imageOptions, progress: progress, onCompletion: onCompletion, onError: onError)
        }
        return progress
    }

    private func generatePreviewImage(for asset: AVAsset, imageOptions: MediaImageExporter.Options?, progress: Progress, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) {
        let generator = AVAssetImageGenerator(asset: asset)
        if let imageOptions, let maxSize = imageOptions.maximumImageSize {
            generator.maximumSize = CGSize(width: maxSize, height: maxSize)
        }
        generator.appliesPreferredTrackTransform = true
        progress.cancellationHandler = { () in
            generator.cancelAllCGImageGeneration()
        }
        // The progress can be cancelled while the asset properties load, before
        // the handler above is in place.
        guard !progress.isCancelled else {
            fail(progress, with: VideoExportError.failedGeneratingVideoPreviewImage, onError: onError)
            return
        }
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTimeMake(value: 0, timescale: 1))],
                                                 completionHandler: { _, cgImage, _, _, _ in
                                                    progress.completedUnitCount = MediaExportProgressUnits.halfDone
                                                    guard let cgImage else {
                                                        onError(VideoExportError.failedGeneratingVideoPreviewImage)
                                                        return
                                                    }
                                                    let image = UIImage(cgImage: cgImage)
                                                    let exporter = MediaImageExporter(image: image, filename: UUID().uuidString)
                                                    if let imageOptions {
                                                        exporter.options = imageOptions
                                                    }
                                                    exporter.mediaDirectoryType = self.mediaDirectoryType
                                                    let imageProgress = exporter.export(
                                                                         onCompletion: onCompletion,
                                                                         onError: onError)
                                                    progress.addChild(imageProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        })
    }

    /// Returns the supported UTType identifiers for the video exporter.
    ///
    /// - Note: This particular list is for the intention of uploading
    ///   exported videos to WordPress, and what WordPress itself supports.
    ///
    fileprivate var supportedExportFileTypes: [String] {
        let types: [UTType] = [
            .mpeg4Movie,
            .quickTimeMovie,
            .mpeg,
            .avi
        ]
        return types.map(\.identifier)
    }
}

final class VideoSessionProgressObserver {

    private let sessionProgress: () -> Float
    let progressHandler: (Float) -> ()
    var interrupt: Bool

    convenience init(videoSession: AVAssetExportSession, progressHandler: @escaping (Float) -> ()) {
        self.init(sessionProgress: { videoSession.progress }, progressHandler: progressHandler)
    }

    /// - Parameter sessionProgress: Reads the export progress, from 0 to 1.
    init(sessionProgress: @escaping () -> Float, progressHandler: @escaping (Float) -> ()) {
        self.sessionProgress = sessionProgress
        self.progressHandler = progressHandler
        interrupt = false
        self.work()
    }

    private func work() {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(100)) {
            // A tick that's already queued when `stop()` is called must not report,
            // or it overwrites the progress set after the export ends.
            guard !self.interrupt else { return }
            self.progressHandler(self.sessionProgress())
            if self.sessionProgress() != 1 {
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
