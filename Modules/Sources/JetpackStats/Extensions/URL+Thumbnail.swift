import Foundation
import UIKit
import WordPressShared

extension URL {
    /// Returns this image cropped to fill a square of `pointSize`, when its host can
    /// resize it.
    ///
    /// The site's posts endpoint reports a featured image as the original upload, which is
    /// routinely a few thousand pixels wide, and the stats rows draw it at thumbnail size.
    /// A WordPress.com-hosted image is resized from query parameters; anything else goes
    /// through Photon. Both crop rather than fit, which is what the rows draw.
    ///
    /// Photon hands the URL back untouched when it can't resize it — an extension it
    /// doesn't recognise, such as a `.webp` upload — and a private site's image isn't
    /// reachable by the proxy at all, so this is an optimization and not a guarantee.
    func thumbnail(fillingSquareOf pointSize: CGFloat, displayScale: CGFloat) -> URL {
        guard pointSize > 0, displayScale > 0 else {
            return self
        }
        let size = CGSize(width: pointSize, height: pointSize)
        if isWordPressComHost {
            let pixels = size.scaled(by: displayScale)
            let query = "w=\(Int(pixels.width))&h=\(Int(pixels.height))&crop=1"
            return replacingQuery(with: query) ?? self
        }
        // Photon takes the size in points and applies the display scale itself.
        return PhotonImageURLHelper.photonURL(
            with: size,
            forImageURL: self,
            traitCollection: UITraitCollection(displayScale: displayScale)
        ) ?? self
    }

    /// Replaces the whole query, so a size the endpoint already applied can't survive and
    /// leave the image smaller than it was asked for.
    private func replacingQuery(with query: String) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            components.host != nil
        else {
            return nil
        }
        components.query = query
        return components.url
    }
}
