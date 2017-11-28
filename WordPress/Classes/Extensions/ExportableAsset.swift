import Foundation

@objc public protocol ExportableAsset: NSObjectProtocol {

    func originalUTI() -> String?

    /// The MediaType for the asset
    ///
    var assetMediaType: MediaType { get }

    /// The default UTI for thumbnails
    ///
    var defaultThumbnailUTI: String { get }

    var mediaName: String? { get }
}
