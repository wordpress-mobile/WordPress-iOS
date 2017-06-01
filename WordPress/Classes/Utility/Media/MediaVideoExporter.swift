import Foundation
import MobileCoreServices

/// MediaLibrary export handling of Videos from PHAssets or AVAssets.
///
class MediaVideoExporter: MediaExporter {

    var maximumImageSize: CGFloat?
    var stripsGeoLocationIfNeeded = false
    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads
    var exportPreset = AVAssetExportPresetHighestQuality
    var exportFileType = kUTTypeMPEG4 as String
    var exportFilename: String?

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
    func exportVideo(atURL url: URL, onCompletion: @escaping (MediaVideoExport) -> Void, onError: @escaping (MediaExportError) -> Void) {
        do {
            let asset = AVURLAsset(url: url)
            guard asset.isExportable else {
                throw VideoExportError.videoAssetWasDetectedAsNotExportable
            }
            guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                throw VideoExportError.failedToInitializeVideoExportSession
            }
            exportVideo(with: session,
                        onCompletion: onCompletion,
                        onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Configures an AVAssetExportSession and exports the video asynchronously.
    ///
    func exportVideo(with session: AVAssetExportSession, onCompletion: @escaping (MediaVideoExport) -> Void, onError: @escaping (MediaExportError) -> Void) {
        do {
            let supportedTypes = session.supportedFileTypes
            // Check that the exportFileType is supported.
            // Otherwise the session will raise an exception when setting outputFileType.
            guard supportedTypes.contains(exportFileType) else {
                throw VideoExportError.videoExportSessionDoesNotSupportVideoOutputType
            }
            let mediaURL = try MediaLibrary.makeLocalMediaURL(withFilename: exportFilename ?? "video",
                                                              fileExtension: URL.fileExtensionForUTType(exportFileType),
                                                              type: mediaDirectoryType)
            session.outputURL = mediaURL
            session.outputFileType = exportFileType
            session.shouldOptimizeForNetworkUse = true

            // Configure metadata filter for sharing, if we need to remove location data.
            if self.stripsGeoLocationIfNeeded {
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
}
