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
    /// through the Photon proxy. Both crop rather than fit, which is what the rows draw.
    ///
    /// Photon hands the URL back untouched when it can't resize it — an extension it
    /// doesn't recognise, such as a `.webp` upload — so this is an optimization and not a
    /// guarantee.
    ///
    /// - parameter isWordPressComHosted: Pass `true` for a site WordPress.com serves from
    ///   the site's own domain, a P2 above all. Its images resize from query parameters
    ///   like any other WordPress.com image, and Photon can't fetch them. This mirrors
    ///   `SiteIconViewModel.optimizedURL(for:imageSize:isP2:traitCollection:)`.
    func thumbnail(
        fillingSquareOf pointSize: CGFloat,
        displayScale: CGFloat,
        isWordPressComHosted: Bool = false
    ) -> URL {
        guard pointSize > 0, displayScale > 0 else {
            return self
        }
        let size = CGSize(width: pointSize, height: pointSize)

        // Checked before the branch below, which an `i0.wp.com` URL also matches. Photon's
        // own URLs carry parameters that branch doesn't speak — `ssl=1` above all, without
        // which the proxy fetches an https-only origin over http — so they go back to the
        // helper that knows how to rewrite them in place.
        if isPhotonHost {
            return photonURL(fillingSquareOf: size, displayScale: displayScale)
        }
        if isWordPressComHost || isWordPressComHosted {
            return resized(toPixelSize: size.scaled(by: displayScale)) ?? self
        }
        return photonURL(fillingSquareOf: size, displayScale: displayScale)
    }

    /// Photon takes the size in points and applies the display scale itself.
    private func photonURL(fillingSquareOf size: CGSize, displayScale: CGFloat) -> URL {
        PhotonImageURLHelper.photonURL(
            with: size,
            forImageURL: self,
            traitCollection: UITraitCollection(displayScale: displayScale)
        ) ?? self
    }

    /// Overrides the parameters that set a size and leaves the rest of the query intact.
    ///
    /// A size the endpoint already applied has to go, or it would win and leave the image
    /// smaller than it was asked for. Anything else the URL carries identifies the resource
    /// or how it is encoded, so dropping it can change which bytes come back.
    private func resized(toPixelSize pixels: CGSize) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            components.host != nil
        else {
            return nil
        }
        let sizingKeys: Set<String> = ["w", "h", "crop", "resize", "fit", "zoom"]
        var items = (components.queryItems ?? [])
            .filter {
                !sizingKeys.contains($0.name.lowercased())
            }
        items.append(URLQueryItem(name: "w", value: "\(Int(pixels.width))"))
        items.append(URLQueryItem(name: "h", value: "\(Int(pixels.height))"))
        items.append(URLQueryItem(name: "crop", value: "1"))
        components.queryItems = items
        return components.url
    }

    /// Whether this URL already points at the Photon proxy, which serves from `i0.wp.com`
    /// through `i3.wp.com`.
    private var isPhotonHost: Bool {
        guard let host = host?.lowercased(), host.hasSuffix(".wp.com") else {
            return false
        }
        let subdomain = host.dropLast(".wp.com".count)
        return subdomain.first == "i" && subdomain.count > 1
            && subdomain.dropFirst().allSatisfy(\.isNumber)
    }
}
