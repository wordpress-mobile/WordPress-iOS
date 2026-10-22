import Foundation
import AVKit

extension URL {
    /// The pixel size of the image at the URL, or `.zero` if it isn't an image.
    ///
    /// Use `videoPixelSize` for videos.
    var pixelSize: CGSize {
        if isImage {
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

    /// The pixel size of the video at the URL, or `.zero` if it isn't a video.
    var videoPixelSize: CGSize {
        get async {
            if isVideo {
                let asset = AVURLAsset(url: self)
                if let track = try? await asset.loadTracks(withMediaType: .video).first,
                   let videoProperties = try? await track.load(.naturalSize, .preferredTransform) {
                    let (naturalSize, preferredTransform) = videoProperties
                    return naturalSize.applying(preferredTransform)
                }
            }
            return CGSize.zero
        }
    }
}
