import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension NSURL: ExportableAsset {

    public func originalUTI() -> String? {
        return typeIdentifier
    }

    public var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }

    public var assetMediaType: MediaType {
        get {
            if isImage {
                return .image
            } else if isVideo {
                return .video
            }
            return .document
        }
    }

    // MARK: - Helper methods

    @objc var pixelSize: CGSize {
        get {
            if isVideo {
                let asset = AVAsset(url: self as URL)
                if let track = asset.tracks(withMediaType: .video).first {
                    return track.naturalSize.applying(track.preferredTransform)
                }
            } else if isImage {
                let options: [NSString: NSObject] = [kCGImageSourceShouldCache: false as CFBoolean]
                if
                    let imageSource = CGImageSourceCreateWithURL(self, nil),
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary?) as NSDictionary?,
                    let pixelWidth = imageProperties[kCGImagePropertyPixelWidth as NSString] as? Int,
                    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight as NSString] as? Int
                {
                        return CGSize(width: pixelWidth, height: pixelHeight)
                }
            }
            return CGSize.zero
        }
    }

    @objc var typeIdentifier: String? {
        guard isFileURL else { return nil }
        do {
            let data = try bookmarkData(options: NSURL.BookmarkCreationOptions.minimalBookmark, includingResourceValuesForKeys: [URLResourceKey.typeIdentifierKey], relativeTo: nil)
            guard
                let resourceValues = NSURL.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey], fromBookmarkData: data),
                let typeIdentifier = resourceValues[URLResourceKey.typeIdentifierKey] as? String else {
                    return nil
            }
            return typeIdentifier
        } catch {
            return nil
        }
    }

    @objc var mimeType: String {
        guard let uti = typeIdentifier,
            let mimeType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)?.takeUnretainedValue() as String?
            else {
                return "application/octet-stream"
        }

        return mimeType
    }

    @objc var isVideo: Bool {
        guard let uti = typeIdentifier else {
            return false
        }

        return UTTypeConformsTo(uti as CFString, kUTTypeMovie)
    }

    @objc var isImage: Bool {
        guard let uti = typeIdentifier else {
            return false
        }

        return UTTypeConformsTo(uti as CFString, kUTTypeImage)
    }


    @objc func removeAttributes(attributes: [String], fromMetadata: [String: AnyObject]) -> [String: AnyObject] {
        var resultingMetadata = fromMetadata
        for attribute in attributes {
            resultingMetadata.removeValue(forKey: attribute)
            if attribute == kCGImagePropertyOrientation as String {
                if let tiffMetadata = resultingMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: AnyObject] {
                    var newTiffMetadata = tiffMetadata
                    newTiffMetadata.removeValue(forKey: kCGImagePropertyTIFFOrientation as String)
                    resultingMetadata[kCGImagePropertyTIFFDictionary as String] = newTiffMetadata as AnyObject?
                }
            }
        }
        return resultingMetadata
    }

    /// Makes sure the metadata of the image is matching the attributes in the Image.
    ///
    /// - Parameters:
    ///     - metadata: The original metadata of the image.
    ///     - image: The current image.
    ///
    /// - Returns: A new metadata object where the values match the values on the UIImage
    ///
    @objc func matchMetadata(metadata: [String: AnyObject], image: UIImage) -> [String: AnyObject] {
        var resultingMetadata = metadata
        let correctOrientation = image.metadataOrientation
        resultingMetadata[kCGImagePropertyOrientation as String] = Int(correctOrientation.rawValue) as AnyObject?
        if var tiffMetadata = resultingMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: AnyObject] {
            tiffMetadata[kCGImagePropertyTIFFOrientation as String] = Int(correctOrientation.rawValue) as AnyObject?
            resultingMetadata[kCGImagePropertyTIFFDictionary as String] = tiffMetadata as AnyObject?
        }

        return resultingMetadata
    }

    // MARK: - Error Handling

    enum ErrorCode: Int {
        case UnsupportedAssetType = 1
        case FailedToExport = 2
        case FailedToExportMetadata = 3
    }

    private func errorForCode(errorCode: ErrorCode, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let error = NSError(domain: "NSURL+ExporterExtensions", code: errorCode.rawValue, userInfo: userInfo)

        return error
    }

    public var mediaName: String? {
        return lastPathComponent
    }

}
