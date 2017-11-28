import Foundation

@objc public protocol ExportableAsset: NSObjectProtocol {

    /// The MediaType for the asset
    ///
    var assetMediaType: MediaType { get }

}
