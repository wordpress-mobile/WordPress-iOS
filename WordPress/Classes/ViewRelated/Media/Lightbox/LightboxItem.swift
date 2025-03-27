import UIKit
import AsyncImageKit

enum LightboxItem {
    case image(UIImage)
    case asset(LightboxAsset)
    case media(Media)
}

struct LightboxAsset {
    let sourceURL: URL
    var host: MediaHost?
}
