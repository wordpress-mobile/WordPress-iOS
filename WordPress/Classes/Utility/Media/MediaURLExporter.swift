import Foundation
import MobileCoreServices

/// MediaLibrary export handling of URLs.
///
class MediaURLExporter: MediaExporter {

    var maximumImageSize: CGFloat?
    var stripsGeoLocationIfNeeded = false
    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads

    /// Enumerable type value for a URLExport, typed according to the resulting export of the file at the URL.
    ///
    public enum URLExport {
        case exportedImage(MediaImageExport)
        case exportedVideo(MediaVideoExport)
        case exportedGIF(MediaGIFExport)
    }

    public enum URLExportError: MediaExportError {
        case invalidFileURL
        case unknownFileUTI
        case failedToInitializeVideoExportSession
        case videoExportSessionFailedWithAnUnknownError

        var description: String {
            switch self {
            case .invalidFileURL,
                 .unknownFileUTI:
                return NSLocalizedString("The media could not be added to the Media Library.", comment: "Message shown when an image or video failed to load while trying to add it to the Media library.")
            case .failedToInitializeVideoExportSession,
                 .videoExportSessionFailedWithAnUnknownError:
                return NSLocalizedString("The video could not be added to the Media Library.", comment: "Message shown when a video failed to load while trying to add it to the Media library.")
            }
        }
        func toNSError() -> NSError {
            return NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey: String(describing: self)])
        }
    }

    /// Exports a file of an unknown type, to a new Media URL.
    ///
    /// Expects files conforming to a video, image or GIF uniform type.
    ///
    func exportURL(fileURL: URL, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            guard fileURL.isFileURL else {
                throw URLExportError.invalidFileURL
            }
            let typeIdentifier = try typeIdentifierAtURL(fileURL) as CFString
            if UTTypeEqual(typeIdentifier, kUTTypeGIF) {
                exportGIF(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            } else if UTTypeConformsTo(typeIdentifier, kUTTypeVideo) || UTTypeConformsTo(typeIdentifier, kUTTypeMovie) {
                exportVideo(atURL: fileURL, typeIdentifier: typeIdentifier, onCompletion: onCompletion, onError: onError)
            } else if UTTypeConformsTo(typeIdentifier, kUTTypeImage) {
                exportImage(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            } else {
                throw URLExportError.unknownFileUTI
            }
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports the known image file at the URL to a new Media URL.
    ///
    fileprivate func exportImage(atURL url: URL, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        // Pass the export off to the image exporter
        let exporter = MediaImageExporter()
        exporter.maximumImageSize = maximumImageSize
        exporter.stripsGeoLocationIfNeeded = stripsGeoLocationIfNeeded
        exporter.mediaDirectoryType = mediaDirectoryType
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                onCompletion(URLExport.exportedImage(imageExport))
        },
                             onError: onError)
    }

    /// Exports the known video file at the URL to a new Media URL.
    ///
    fileprivate func exportVideo(atURL url: URL, typeIdentifier: CFString, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            let asset = AVURLAsset(url: url)
            guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                throw URLExportError.failedToInitializeVideoExportSession
            }

            let mediaURL = try MediaLibrary.makeLocalMediaURL(withFilename: url.lastPathComponent,
                                                              fileExtension: String.fileExtensionForUTType(typeIdentifier),
                                                              type: mediaDirectoryType)
            session.outputURL = mediaURL
            session.outputFileType = typeIdentifier as String
            session.shouldOptimizeForNetworkUse = true
            session.exportAsynchronously {
                guard session.status == .completed else {
                    if let error = session.error {
                        onError(self.exporterErrorWith(error: error))
                    } else {
                        onError(URLExportError.videoExportSessionFailedWithAnUnknownError)
                    }
                    return
                }
                onCompletion(URLExport.exportedVideo(MediaVideoExport(url: mediaURL,
                                                                      fileSize: mediaURL.resourceFileSize,
                                                                      duration: nil)))
            }
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports the GIF file at the URL to a new Media URL, by simply copying the file.
    ///
    fileprivate func exportGIF(atURL url: URL, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            let fileManager = FileManager.default
            let mediaURL = try MediaLibrary.makeLocalMediaURL(withFilename: url.lastPathComponent,
                                                              fileExtension: "gif",
                                                              type: mediaDirectoryType)
            try fileManager.copyItem(at: url, to: mediaURL)
            onCompletion(URLExport.exportedGIF(MediaGIFExport(url: mediaURL,
                                                              fileSize: mediaURL.resourceFileSize)))
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Resolves the uniform type identifier for the file at the URL, or throws an error if unknown.
    ///
    fileprivate func typeIdentifierAtURL(_ url: URL) throws -> String {
        let resourceValues = try url.resourceValues(forKeys: [.typeIdentifierKey])
        guard let typeIdentifier = resourceValues.typeIdentifier else {
            throw URLExportError.unknownFileUTI
        }
        return typeIdentifier
    }
}
