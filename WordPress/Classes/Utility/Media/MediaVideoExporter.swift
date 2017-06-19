import Foundation
import MobileCoreServices

/// MediaLibrary export handling of Videos from PHAssets or AVAssets.
///
class MediaVideoExporter: MediaExporter {

    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads

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
        var preferredExportFileType: String?

        // MARK: - MediaExporting

        var stripsGeoLocationIfNeeded = false
    }

    /// Completion block with a MediaVideoExport.
    ///
    typealias OnVideoExport = (MediaVideoExport) -> Void

    public enum VideoExportError: MediaExportError {
        case videoAssetWasDetectedAsNotExportable
        case videoExportSessionDoesNotSupportVideoOutputType
        case failedToInitializeVideoExportSession
        case failedExportingVideoDuringExportSession

        var description: String {
            switch self {
            default:
                return NSLocalizedString("The video could not be added to the Media Library.", comment: "Message shown when a video failed to load while trying to add it to the Media library.")
            }
        }
        func toNSError() -> NSError {
            return NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey: String(describing: self)])
        }
    }

    /// Exports a known video at a URL asynchronously.
    ///
    func exportVideo(atURL url: URL, onCompletion: @escaping OnVideoExport, onError: @escaping OnExportError) {
        do {
            let asset = AVURLAsset(url: url)
            guard asset.isExportable else {
                throw VideoExportError.videoAssetWasDetectedAsNotExportable
            }
            guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                throw VideoExportError.failedToInitializeVideoExportSession
            }
            exportVideo(with: session,
                        filename: url.lastPathComponent,
                        onCompletion: onCompletion,
                        onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Configures an AVAssetExportSession and exports the video asynchronously.
    ///
    func exportVideo(with session: AVAssetExportSession, filename: String?, onCompletion: @escaping OnVideoExport, onError: @escaping OnExportError) {
        do {
            var outputType = options.preferredExportFileType ?? supportedExportFileTypes.first!
            // Check if the exportFileType is one of the supported types for the exportSession.
            if session.supportedFileTypes.contains(outputType) == false {
                /* 
                 If it is not supported by the session, try and find one
                 of the exporter's own supported types within the session's.
                 Ideally we return the first type, as an order of preference from supportedExportFileTypes.
                */
                guard let supportedType = supportedExportFileTypes.first(where: { session.supportedFileTypes.contains($0) }) else {
                    // No supported types available, throw an error.
                    throw VideoExportError.videoExportSessionDoesNotSupportVideoOutputType
                }
                outputType = supportedType
            }

            // Generate a URL for exported video.
            let mediaURL = try MediaLibrary.makeLocalMediaURL(withFilename: filename ?? "video",
                                                              fileExtension: URL.fileExtensionForUTType(outputType),
                                                              type: mediaDirectoryType)
            session.outputURL = mediaURL
            session.outputFileType = outputType
            session.shouldOptimizeForNetworkUse = true

            // Configure metadata filter for sharing, if we need to remove location data.
            if options.stripsGeoLocationIfNeeded {
                session.metadataItemFilter = AVMetadataItemFilter.forSharing()
            }
            session.exportAsynchronously {
                guard session.status == .completed else {
                    if let error = session.error {
                        onError(self.exporterErrorWith(error: error))
                    } else {
                        onError(VideoExportError.failedExportingVideoDuringExportSession)
                    }
                    return
                }
                onCompletion(MediaVideoExport(url: mediaURL,
                                              fileSize: mediaURL.resourceFileSize,
                                              duration: session.asset.duration.seconds))
            }
        } catch {
            onError(exporterErrorWith(error: error))
        }
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
