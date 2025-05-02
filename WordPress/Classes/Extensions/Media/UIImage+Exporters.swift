import Foundation
import UIKit
import ImageIO
import MobileCoreServices
import WordPressData

extension UIImage: ExportableAsset {

    public var assetMediaType: MediaType {
        get {
            return .image
        }
    }

}
