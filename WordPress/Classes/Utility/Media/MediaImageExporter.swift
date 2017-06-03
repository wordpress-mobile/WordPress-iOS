import Foundation
import MobileCoreServices

/// MediaLibrary export handling of UIImages.
///
class MediaImageExporter: MediaExporter {

    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads

    /// Export options.
    ///
    var options = Options()

    /// Available options for an image export.
    ///
    struct Options: MediaExportingOptions {
        /// Set a maximumImageSize for resizing images, or nil for exporting the full images.
        ///
        var maximumImageSize: CGFloat?

        /// Default compression quality when an image is being resized.
        ///
        var imageCompressionQualityUponResizing = 0.9

        // MARK: - MediaExporting

        var stripsGeoLocationIfNeeded = false
    }

    /// Completion block with a MediaImageExport.
    ///
    typealias OnImageExport = (MediaImageExport) -> Void

    public enum ImageExportError: MediaExportError {
        case imageJPEGDataRepresentationFailed
        case imageSourceCreationWithDataFailed
        case imageSourceCreationWithURLFailed
        case imageSourceIsAnUnknownType
        case imageSourceExpectedJPEGImageType
        case imageSourceDestinationWithURLFailed
        case imageSourceThumbnailGenerationFailed
        case imageSourceDestinationWriteFailed
        var description: String {
            switch self {
            default:
                return NSLocalizedString("The image could not be added to the Media Library.", comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            }
        }
        func toNSError() -> NSError {
            return NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey: String(describing: self)])
        }
    }

    /// Default filename used when writing media images locally, which may be appended with "-1" or "-thumbnail".
    ///
    fileprivate let defaultImageFilename = "image"

    /// Exports and writes a UIImage to a local Media URL.
    ///
    /// A JPEG or PNG is expected, but not necessarily required. Exporting will fail if a JPEG cannot
    /// be represented from the UIImage, such as trying to export a GIF.
    ///
    /// - parameter fileName: Filename if it's known.
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImage(_ image: UIImage, fileName: String?, onCompletion: @escaping OnImageExport, onError: @escaping OnExportError) {
        do {
            guard let data = UIImageJPEGRepresentation(image, 1.0) else {
                throw ImageExportError.imageJPEGDataRepresentationFailed
            }
            exportImage(withJPEGData: data,
                        fileName: fileName,
                        onCompletion: onCompletion,
                        onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes an image's data, expected as JPEG format, to a local Media URL.
    ///
    /// - parameter fileName: Filename if it's known.
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImage(withJPEGData data: Data, fileName: String?, onCompletion: @escaping OnImageExport, onError: @escaping OnExportError) {
        do {
            let options: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG]
            guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
                throw ImageExportError.imageSourceCreationWithDataFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ImageExportError.imageSourceIsAnUnknownType
            }
            guard UTTypeEqual(utType, kUTTypeJPEG) else {
                throw ImageExportError.imageSourceExpectedJPEGImageType
            }
            exportImageSource(source,
                              filename: fileName,
                              type: utType as String,
                              onCompletion: onCompletion,
                              onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes image data located at a URL, to a local Media URL.
    ///
    /// A JPEG or PNG is expected, but not necessarily required. The export will write the same data format
    /// as found at the URL, or will throw if the type is unknown or fails.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImage(atURL url: URL, onCompletion: @escaping OnImageExport, onError: @escaping OnExportError) {
        do {
            let options: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG]
            guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary)  else {
                throw ImageExportError.imageSourceCreationWithURLFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ImageExportError.imageSourceIsAnUnknownType
            }
            exportImageSource(source,
                              filename: url.deletingPathExtension().lastPathComponent,
                              type: utType as String,
                              onCompletion: onCompletion,
                              onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes an image source, to a local Media URL.
    ///
    /// - parameter fileName: Filename if it's known.
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImageSource(_ source: CGImageSource, filename: String?, type: String, onCompletion: @escaping OnImageExport, onError: OnExportError) {
        do {
            let filename = filename ?? defaultImageFilename
            // Make a new URL within the local Media directory
            let url = try MediaLibrary.makeLocalMediaURL(withFilename: filename,
                                                         fileExtension: URL.fileExtensionForUTType(type),
                                                         type: mediaDirectoryType)

            // Check MediaSettings and configure the image writer as needed.
            var writer = ImageSourceWriter(url: url, sourceUTType: type as CFString)
            if let maximumImageSize = options.maximumImageSize {
                writer.maximumSize = maximumImageSize as CFNumber
                writer.lossyCompressionQuality = options.imageCompressionQualityUponResizing as CFNumber
            }
            writer.nullifyGPSData = options.stripsGeoLocationIfNeeded
            let result = try writer.writeImageSource(source)
            onCompletion(MediaImageExport(url: url,
                                          fileSize: url.resourceFileSize,
                                          width: result.width,
                                          height: result.height))
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Configurable struct for writing an image to a URL from a CGImageSource, via CGImageDestination, particular to the needs of a MediaImageExporter.
    ///
    fileprivate struct ImageSourceWriter {

        /// File URL where the image should be written
        ///
        var url: URL

        /// The UTType of the image source
        ///
        var sourceUTType: CFString

        /// The Compression quality used, defaults to 1.0 or full
        ///
        var lossyCompressionQuality = 1.0 as CFNumber

        /// Whether or not GPS data should be nullified.
        ///
        var nullifyGPSData = false

        /// A maximum size required for the image to be written, or nil.
        ///
        var maximumSize: CFNumber?

        init(url: URL, sourceUTType: CFString) {
            self.url = url
            self.sourceUTType = sourceUTType
        }

        /// Struct for returned result from writing an image, and any properties worth keeping track of.
        ///
        struct WriteResultProperties {
            let width: CGFloat?
            let height: CGFloat?
        }

        /// Write a given image source, succeeds unless an error is thrown, returns the resulting properties if available.
        ///
        func writeImageSource(_ source: CGImageSource) throws -> WriteResultProperties {
            // Create the destination with the URL, or error
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, sourceUTType, 1, nil) else {
                throw ImageExportError.imageSourceDestinationWithURLFailed
            }

            // Configure image properties for the image source and image destination methods
            // Preserve any existing properties from the source.
            var imageProperties: [NSString: Any] = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary) ?? [:]
            // Configure destination properties
            imageProperties[kCGImageDestinationLossyCompressionQuality] = lossyCompressionQuality
            // Configure orientation properties to default .up or 1
            imageProperties[kCGImagePropertyOrientation] = CGImagePropertyOrientation.up
            if var tiffProperties = imageProperties[kCGImagePropertyTIFFDictionary] as? [NSString: Any] {
                // Remove TIFF orientation value
                tiffProperties.removeValue(forKey: kCGImagePropertyTIFFOrientation)
                imageProperties[kCGImagePropertyTIFFDictionary] = tiffProperties
            }
            if var iptcProperties = imageProperties[kCGImagePropertyIPTCImageOrientation] as? [NSString: Any] {
                // Remove IPTC orientation value
                iptcProperties.removeValue(forKey: kCGImagePropertyIPTCImageOrientation)
                imageProperties[kCGImagePropertyIPTCImageOrientation] = iptcProperties
            }

            // Keep track of the image's width and height
            var width: CGFloat?
            var height: CGFloat?

            if let maximumSize = maximumSize {
                // Configure options for generating the thumbnail, such as the maximum size.
                let thumbnailOptions: [NSString: Any] = [kCGImageSourceThumbnailMaxPixelSize: maximumSize,
                                                       kCGImageSourceCreateThumbnailFromImageAlways: true,
                                                       kCGImageSourceShouldCache: false,
                                                       kCGImageSourceTypeIdentifierHint: sourceUTType,
                                                       kCGImageSourceCreateThumbnailWithTransform: true]
                // Create a thumbnail of the image source.
                guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
                    throw ImageExportError.imageSourceThumbnailGenerationFailed
                }

                if nullifyGPSData == true {
                    // When removing GPS data for a thumbnail, we have to remove the dictionary
                    // itself for the CGImageDestinationAddImage method.
                    imageProperties.removeValue(forKey: kCGImagePropertyGPSDictionary)
                }

                // Add the thumbnail image as the destination's image.
                CGImageDestinationAddImage(destination, image, imageProperties as CFDictionary?)

                // Get the dimensions from the CGImage itself
                width = CGFloat(image.width)
                height = CGFloat(image.height)
            } else {

                if nullifyGPSData == true {
                    // When removing GPS data for a full-sized image, we have to nullify the GPS dictionary
                    // for the CGImageDestinationAddImageFromSource method.
                    imageProperties[kCGImagePropertyGPSDictionary] = kCFNull
                }
                // No resizing needed, add the full sized image from the source
                CGImageDestinationAddImageFromSource(destination, source, 0, imageProperties as CFDictionary?)

                // Get the dimensions of the full size image from the source's properties
                width = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat
                height = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
            }

            // Write the image to the file URL
            let written = CGImageDestinationFinalize(destination)
            guard written == true else {
                throw ImageExportError.imageSourceDestinationWriteFailed
            }
            // Return the result with any interesting properties.
            return WriteResultProperties(width: width,
                                         height: height)
        }
    }
}
