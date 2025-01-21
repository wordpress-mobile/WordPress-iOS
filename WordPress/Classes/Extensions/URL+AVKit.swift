import Foundation
import AVKit

extension URL {
    var pixelSize: CGSize {
        if isVideo {
            let asset = AVAsset(url: self as URL)
            if let track = asset.tracks(withMediaType: .video).first {
                return track.naturalSize.applying(track.preferredTransform)
            }
        } else if isImage {
            let options: [NSString: NSObject] = [kCGImageSourceShouldCache: false as CFBoolean]
            if
                let imageSource = CGImageSourceCreateWithURL(self as NSURL, nil),
                let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary?) as NSDictionary?,
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth as NSString] as? Int,
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight as NSString] as? Int {
                return CGSize(width: pixelWidth, height: pixelHeight)
            }
        }
        return CGSize.zero
    }
}
