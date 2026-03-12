import UIKit
import AsyncImageKit
import WordPressData

enum LightboxItem {
    case image(UIImage)
    case asset(LightboxAsset)
    case media(Media)
}

struct LightboxAsset {
    let sourceURL: URL
    /// An optional smaller preview to display while the full-resolution image loads.
    var previewURL: URL?
    var host: MediaHost?
}
