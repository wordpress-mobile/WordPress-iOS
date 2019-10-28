import Foundation
import MobileCoreServices

/// Media export handling of UIImages.
///
class MediaImageExporter: MediaExporter {

    var mediaDirectoryType: MediaDirectory = .uploads

    /// Export options.
    ///
    var options = Options()

    /// Available options for an image export.
    ///
    struct Options: MediaExportingOptions {
        /// Set a maximumImageSize for resizing images, or nil for exporting the full images.
        ///
        var maximumImageSize: CGFloat?

        /// Compression quality if the image type supports compression, defaults to no compression or maximum quality.
        ///
        var imageCompressionQuality = 1.0

        /// The target UTType of the exported image, typically a UTTypeJPEG or UTTypePNG,
        /// or nil if the original image's format should be used.
        ///
        /// - Note: The exporter may not support exporting the original image as
        ///   the set type, and will throw an error if it fails.
        ///
        var exportImageType: String?

        /// If the original asset contains geo location information, enabling this option will remove it.
        var stripsGeoLocationIfNeeded = false
    }

    public enum ImageExportError: MediaExportError {
        case imageDataRepresentationFailed
        case imageSourceCreationWithDataFailed
        case imageSourceCreationWithURLFailed
        case imageSourceIsAnUnknownType
        case imageSourceDestinationWithURLFailed
        case imageSourceThumbnailGenerationFailed
        case imageSourceDestinationWriteFailed
        var description: String {
            switch self {
            default:
                return NSLocalizedString("The image could not be added to the Media Library.", comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            }
        }
    }

    /// Default filename used when writing media images locally, which may be appended with "-1" or "-thumbnail".
    ///
    fileprivate let defaultImageFilename = "image"

    private let image: UIImage?
    private let data: Data?
    private let url: URL?
    private let filename: String?
    private let caption: String?
    private let typeHint: String?

    private init(image: UIImage?, filename: String?, data: Data?, url: URL?, caption: String?, typeHint: String? = nil) {
        self.image = image
        self.filename = filename
        self.data = data
        self.url = url
        self.caption = caption
        self.typeHint = typeHint
    }

    convenience init(image: UIImage, filename: String?, caption: String? = nil) {
        self.init(image: image, filename: filename, data: nil, url: nil, caption: caption)
    }

    convenience init(url: URL) {
        self.init(image: nil, filename: nil, data: nil, url: url, caption: nil)
    }

    convenience init(data: Data, filename: String?, typeHint: String? = nil) {
        self.init(image: nil, filename: filename, data: data, url: nil, caption: nil, typeHint: typeHint)
    }

    @discardableResult public func export(onCompletion: @escaping OnMediaExport, onError: @escaping (MediaExportError) -> Void) -> Progress {
        if let image = image {
            return exportImage(image, fileName: filename, onCompletion: onCompletion, onError: onError)
        } else if let data = data {
            return exportImage(withData: data, fileName: filename, typeHint: typeHint, onCompletion: onCompletion, onError: onError)
        } else if let url = url {
            return exportImage(atFile: url, onCompletion: onCompletion, onError: onError)
        }
        return Progress.discreteCompletedProgress()
    }

    /// Exports and writes a UIImage to a local Media URL.
    ///
    /// A PNG or JPEG is expected but not necessarily required. Exporting will fail if a PNG or JPEG cannot
    /// be represented from the UIImage, such as trying to export a GIF.
    ///
    /// - Parameters:
    ///     - fileName: Filename if it's known.
    ///     - onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    ///     - onError: Called if an error was encountered during creation.
    ///
    /// - Returns: a progress object that report the current state of the export process.
    ///
    func exportImage(_ image: UIImage, fileName: String?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        var data: Data?
        var hint: String?
        // If the exportImageType is targeting a PNG, try to init PNG data.
        if let exportType = options.exportImageType, UTTypeEqual(exportType as CFString, kUTTypePNG) {
            data = image.pngData()
            hint = kUTTypePNG as String
        }
        // If the data failed to init as PNG, or is another type, try and init as JPEG data.
        if data == nil {
            data = image.jpegData(compressionQuality: 1.0)
            hint = kUTTypeJPEG as String
        }
        // Ensure that we do indeed have image data.
        guard let imageData = data else {
            onError(exporterErrorWith(error: ImageExportError.imageDataRepresentationFailed))
            return Progress.discreteCompletedProgress()
        }
        return exportImage(withData: imageData,
                    fileName: fileName,
                    typeHint: hint,
                    onCompletion: onCompletion,
                    onError: onError)
    }

    /// Exports and writes an image's data, expected as PNG or JPEG format, to a local Media URL.
    ///
    /// - Parameters:
    ///     - fileName: Filename if it's known.
    ///     - typeHint: Hint towards the UTType of data, such as PNG or JPEG.
    ///     - onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    ///     - onError: Called if an error was encountered during creation.
    ///
    /// - Returns: a progress object that report the current state of the export process.
    ///
    func exportImage(withData data: Data, fileName: String?, typeHint: String?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        do {
            let hint = typeHint ?? kUTTypeJPEG as String
            let sourceOptions: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: hint as CFString]
            guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
                throw ImageExportError.imageSourceCreationWithDataFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ImageExportError.imageSourceIsAnUnknownType
            }
            return exportImageSource(source,
                              filename: fileName,
                              type: options.exportImageType ?? utType as String,
                              onCompletion: onCompletion,
                              onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
        return Progress.discreteCompletedProgress()
    }

    /// Exports and writes image data located at a file URL, to a local Media URL.
    ///
    /// A JPEG or PNG is expected, but not necessarily required. The export will write the same data format
    /// as found at the URL, or will throw if the type is unknown or fails.
    ///
    /// - Parameters:
    ///     - url: The fileURL of image.
    ///     - onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    ///     - onError: Called if an error was encountered during creation.
    ///
    /// - Returns: a progress object that report the current state of the export process.
    ///
    func exportImage(atFile url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        do {
            let identifierHint = url.typeIdentifierFileExtension ?? kUTTypeJPEG as String
            let sourceOptions: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: identifierHint as CFString]
            guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary)  else {
                throw ImageExportError.imageSourceCreationWithURLFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ImageExportError.imageSourceIsAnUnknownType
            }
            return exportImageSource(source,
                              filename: UUID().uuidString,
                              type: options.exportImageType ?? utType as String,
                              onCompletion: onCompletion,
                              onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
        return Progress.discreteCompletedProgress()
    }

    /// Exports and writes an image source, to a local Media URL.
    ///
    /// - Parameters:
    ///     - fileName: Filename if it's known.
    ///     - onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    ///     - onError: Called if an error was encountered during creation.
    ///
    /// - Returns: a progress object that report the current state of the export process.
    ///
    func exportImageSource(_ source: CGImageSource, filename: String?, type: String, onCompletion: @escaping OnMediaExport, onError: OnExportError) -> Progress {
        do {
            let filename = filename ?? defaultImageFilename
            // Make a new URL within the local Media directory
            let url = try mediaFileManager.makeLocalMediaURL(withFilename: filename,
                                                               fileExtension: URL.fileExtensionForUTType(type))

            // Check MediaSettings and configure the image writer as needed.
            var writer = ImageSourceWriter(url: url, sourceUTType: type as CFString)
            if let maximumImageSize = options.maximumImageSize {
                writer.maximumSize = maximumImageSize as CFNumber
            }
            writer.lossyCompressionQuality = options.imageCompressionQuality
            writer.nullifyGPSData = options.stripsGeoLocationIfNeeded
            let result = try writer.writeImageSource(source)
            onCompletion(MediaExport(url: url,
                                          fileSize: url.fileSize,
                                          width: result.width,
                                          height: result.height,
                                          duration: nil,
                                          caption: caption))
        } catch {
            onError(exporterErrorWith(error: error))
        }
        return Progress.discreteCompletedProgress()
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
        var lossyCompressionQuality = 1.0

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

            // Keep track of the image's width and height
            var width: CGFloat?
            var height: CGFloat?

            // Configure orientation properties to default .up or 1
            imageProperties[kCGImagePropertyOrientation] = Int(CGImagePropertyOrientation.up.rawValue) as CFNumber
            if var tiffProperties = imageProperties[kCGImagePropertyTIFFDictionary] as? [NSString: Any] {
                // Remove TIFF orientation value
                tiffProperties.removeValue(forKey: kCGImagePropertyTIFFOrientation)
                imageProperties[kCGImagePropertyTIFFDictionary] = tiffProperties
            }
            if var iptcProperties = imageProperties[kCGImagePropertyIPTCDictionary] as? [NSString: Any] {
                // Remove IPTC orientation value
                iptcProperties.removeValue(forKey: kCGImagePropertyIPTCImageOrientation)
                imageProperties[kCGImagePropertyIPTCDictionary] = iptcProperties
            }

            // Configure options for generating the thumbnail, such as the maximum size.
            var thumbnailOptions: [NSString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCache: false,
                kCGImageSourceTypeIdentifierHint: sourceUTType,
                kCGImageSourceCreateThumbnailWithTransform: true ]

            if let maximumSize = maximumSize {
                thumbnailOptions[kCGImageSourceThumbnailMaxPixelSize] = maximumSize
            }

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
