import Foundation

typealias SuccessHandler = (_ resultingSize: CGSize) -> ()
typealias ErrorHandler = (_ error: NSError) -> ()

@objc protocol ExportableAsset: NSObjectProtocol {
    /// Exports an asset to a file URL with the desired targetSize and removing geolocation if requested.
    /// The targetSize is the maximum resolution permited, the resultSize will normally be a lower value that
    /// maitains the aspect ratio of the asset.
    ///
    /// - Note: Images aren't scaled up, so if you pass a `maximumResolution` that's larger than the original
    ///         image, it will not resize.
    ///
    /// - Parameters:
    ///     - url: file url to where the asset should be exported, this must be writable location
    ///     - targetUTI: the UTI format to use when exporting the asset
    ///     - maximumResolution:  the maximum pixel resolution that the asset can have after exporting.
    ///     - stripGeoLocation: if true any geographic location existent on the metadata of the asset will be stripped
    ///     - successHandler:  a handler that will be invoked on success with the resulting resolution of the asset exported
    ///     - errorHandler: a handler that will be invoked when some error occurs when generating the exported file for the asset
    ///
    func exportToURL(_ url: URL,
                     targetUTI: String,
                     maximumResolution: CGSize,
                     stripGeoLocation: Bool,
                     synchronous: Bool,
                     successHandler: @escaping SuccessHandler,
                     errorHandler: @escaping ErrorHandler)

    /// Exports an image thumbnail of the asset to a file URL that respects the targetSize.
    /// The targetSize is the maximum resulting resolution  the resultSize will normally be a lower value that
    /// mantains the aspect ratio of the asset
    ///
    /// - Parameters:
    ///     - url: File url to where the asset should be exported, this must be writable location.
    ///     - targetSize: The maximum pixel resolution that the file can have after exporting.
    ///                   If CGSizeZero is provided the original size of image is returned.
    ///     - successHandler: A handler that will be invoked on success with the resulting resolution of the image
    ///     - errorHandler: A handler that will be invoked when some error occurs when generating the thumbnail
    ///
    func exportThumbnailToURL(_ url: URL,
                              targetSize: CGSize,
                              synchronous: Bool,
                              successHandler: @escaping SuccessHandler,
                              errorHandler: @escaping ErrorHandler)

    /**
     Export the original asset without any modification to the specified URL
     
     - parameter toURL:          the location to export to
     - parameter successHandler: A handler that will be invoked on success with the resulting resolution of the image.
     - parameter errorHandler:   A handler that will be invoked when some error occurs.
     
     */
    func exportOriginalImage(_ toURL: URL, successHandler: @escaping SuccessHandler, errorHandler: @escaping ErrorHandler)

    func originalUTI() -> String?

    /// The MediaType for the asset
    ///
    var assetMediaType: MediaType { get }

    /// The default UTI for thumbnails
    ///
    var defaultThumbnailUTI: String { get }

    var mediaName: String? { get }
}
