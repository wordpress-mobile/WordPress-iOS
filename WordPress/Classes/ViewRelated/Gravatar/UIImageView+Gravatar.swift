import Foundation
import GravatarUI
import WordPressUI

/// Convenience intermediate enum for Objc compatibility.
/// Gravatar Image Ratings for Objc compatibility.
@objc
public enum ObjcGravatarRating: Int {
    case g
    case pg
    case r
    case x

    fileprivate func map() -> Rating {
        switch self {
        case .g: .general
        case .pg: .parentalGuidance
        case .r: .restricted
        case .x: .x
        }
    }
}

extension UIImageView {

    /// Re-declaration for Objc compatibility
    @objc(downloadGravatarFor:gravatarRating:)
    public func objc_downloadGravatar(for email: String, gravatarRating: ObjcGravatarRating) {
        downloadGravatar(for: email, gravatarRating: gravatarRating.map(), placeholderImage: .gravatarPlaceholderImage)
    }

    /// Downloads and sets the User's Gravatar, given his email.
    /// - Parameters:
    ///   - email: The user's email
    ///   - gravatarRating: Expected image rating
    ///   - placeholderImage: Image to be used as Placeholder
    ///   - forceRefresh: Skip the cache and fetch the latest version of the avatar.
    public func downloadGravatar(
        for email: String,
        gravatarRating: Rating = .general,
        placeholderImage: UIImage = .gravatarPlaceholderImage,
        forceRefresh: Bool = false
    ) {
        let avatarURL = AvatarURL.url(for: email, preferredSize: .pixels(gravatarDefaultSize()), gravatarRating: gravatarRating)
        downloadGravatar(fullURL: avatarURL, placeholder: placeholderImage, animate: false, forceRefresh: forceRefresh)
    }

    public func downloadGravatar(_ gravatar: AvatarURL?, placeholder: UIImage, animate: Bool, forceRefresh: Bool = false) {
        guard let gravatar = gravatar else {
            self.image = placeholder
            return
        }

        // Starting with iOS 10, it seems `initWithCoder` uses a default size
        // of 1000x1000, which was messing with our size calculations for gravatars
        // on newly created table cells.
        // Calling `layoutIfNeeded()` forces UIKit to calculate the actual size.
        layoutIfNeeded()

        let size = Int(ceil(frame.width * min(2, UIScreen.main.scale)))
        guard let url = gravatar.replacing(options: .init(preferredSize: .pixels(size)))?.url else { return }
        downloadGravatar(fullURL: url, placeholder: placeholder, animate: animate, forceRefresh: forceRefresh)
    }

    private func downloadGravatar(fullURL: URL?, placeholder: UIImage, animate: Bool, forceRefresh: Bool = false) {
        wp.prepareForReuse()
        if let fullURL {
            var urlToDownload = fullURL
            if forceRefresh {
                urlToDownload = fullURL.appendingGravatarCacheBusterParam()
            }

            wp.setImage(with: urlToDownload)

            if forceRefresh {
                // If this is a `forceRefresh`, the cache for the original URL should be updated too.
                // Because the cache buster parameter modifies the download URL.
                Task {
                    await wp.controller.task?.value // Wait until setting the new image is done.
                    if let image {
                        ImageCache.shared.setImage(image, forKey: fullURL.absoluteString) // Update the cache for the original URL
                    }
                }
            }

            if image == nil { // If image wasn't found synchronously in memory cache
                image = placeholder
            }
        }
    }

    @objc public func overrideGravatarImageCache(_ image: UIImage, gravatarRating: ObjcGravatarRating, email: String) {
        guard let gravatarURL = AvatarURL.url(for: email, preferredSize: .pixels(gravatarDefaultSize()), gravatarRating: gravatarRating.map()) else {
            return
        }

        listenForGravatarChanges(forEmail: email)
        overrideImageCache(for: gravatarURL, with: image)
    }

    private func gravatarDefaultSize() -> Int {
        guard bounds.size.equalTo(.zero) == false else {
            return GravatarDefaults.imageSize
        }

        let targetSize = max(bounds.width, bounds.height) * UIScreen.main.scale
        return Int(targetSize)
    }
}

fileprivate struct GravatarDefaults {
    static let imageSize = 80
}

extension AvatarURL {

    public static func url(for email: String,
                           preferredSize: ImageSize? = nil,
                           gravatarRating: Rating? = nil,
                           defaultAvatarOption: DefaultAvatarOption? = .status404) -> URL? {
        AvatarURL(
            with: .email(email),
            // Passing GravatarDefaults.imageSize to keep the previous default.
            // But ideally this should be passed explicitly.
            options: .init(
                preferredSize: preferredSize ?? .pixels(GravatarDefaults.imageSize),
                rating: gravatarRating,
                defaultAvatarOption: defaultAvatarOption
            )
        )?.url
    }
}
