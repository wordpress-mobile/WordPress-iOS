import UIKit
import Gravatar
import AsyncImageKit
import WordPressShared

extension AsyncImageKit.ImageDownloader {

    /// Downloads the account avatar for `email`.
    ///
    /// - Returns: The avatar, or `nil` when Gravatar confirms that `email` has no avatar.
    /// - Throws: Any other download failure.
    func accountAvatar(for email: String, forceRefresh: Bool) async throws -> UIImage? {
        guard let url = Self.accountAvatarURL(for: email) else {
            return nil
        }

        let image: UIImage?
        do {
            if forceRefresh {
                // The cache-busted URL is unique per request, so nothing reads
                // its cache entries. Cache the result under the plain URL instead.
                let options = ImageRequestOptions(isMemoryCacheEnabled: false, isDiskCacheEnabled: false)
                image = try await self.image(from: url.appendingGravatarCacheBusterParam(), options: options)
            } else {
                image = try await self.image(from: url)
            }
        } catch let error where Self.isMissingGravatar(error) {
            image = nil
        }

        if forceRefresh {
            // The backend keeps serving the old avatar at the plain URL for about
            // 25 seconds after a change, so store the fresh result under it.
            setCachedImage(image, for: url)
        }
        return image
    }

    /// The URL of the account avatar for `email`.
    ///
    /// Every consumer downscales from this one URL, so they share one download and
    /// one cache entry. 192 pixels is 64 points at 3x, the largest consumer on the
    /// sharpest screen. Pixels, not points, keep the URL independent of the
    /// current display scale.
    nonisolated static func accountAvatarURL(for email: String) -> URL? {
        AvatarURL.url(for: email, preferredSize: .pixels(192), gravatarRating: .x, defaultAvatarOption: .status404)
    }

    /// Whether `error` means Gravatar has no avatar for the requested email, which
    /// it reports with a 404 when the URL uses the 404 default-image option.
    nonisolated static func isMissingGravatar(_ error: Error) -> Bool {
        if case ImageDownloaderError.unacceptableStatusCode(404) = error {
            return true
        }
        return false
    }
}
