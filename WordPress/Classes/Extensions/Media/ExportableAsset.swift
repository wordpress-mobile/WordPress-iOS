import Foundation
import WordPressData

@objc public protocol ExportableAsset: NSObjectProtocol {

    /// The MediaType for the asset
    ///
    var assetMediaType: MediaType { get }

}
