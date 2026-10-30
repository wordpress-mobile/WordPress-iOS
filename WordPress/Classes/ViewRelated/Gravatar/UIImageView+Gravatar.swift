import Foundation
import AsyncImageKit
import GravatarUI
import WordPressUI

extension UIImageView {

    /// Downloads and sets the User's Gravatar, given his email.
    /// - Parameters:
    ///   - email: The user's email
    ///   - placeholderImage: Image to be used as Placeholder
    public func downloadGravatar(
        for email: String,
        placeholderImage: UIImage = .gravatarPlaceholderImage
    ) {
        let avatarURL = AvatarURL.url(for: email, preferredSize: gravatarDefaultSize(), gravatarRating: .general)
        downloadGravatar(fullURL: avatarURL, placeholder: placeholderImage, animate: false)
    }

    public func downloadGravatar(_ gravatar: AvatarURL?, placeholder: UIImage, animate: Bool) {
        guard let gravatar else {
            self.image = placeholder
            return
        }

        // Starting with iOS 10, it seems `initWithCoder` uses a default size
        // of 1000x1000, which was messing with our size calculations for gravatars
        // on newly created table cells.
        // Calling `layoutIfNeeded()` forces UIKit to calculate the actual size.
        layoutIfNeeded()

        let size = Int(ceil(max(28, frame.width) * traitCollection.displayScale))
        guard let url = gravatar.replacing(options: .init(preferredSize: .pixels(size)))?.url else { return }
        downloadGravatar(fullURL: url, placeholder: placeholder, animate: animate)
    }

    private func downloadGravatar(fullURL: URL?, placeholder: UIImage, animate: Bool) {
        wp.prepareForReuse()
        if let fullURL {
            wp.setImage(with: fullURL)
            if image == nil { // If image wasn't found synchronously in memory cache
                image = placeholder
            }
        }
    }

    private func gravatarDefaultSize() -> Gravatar.ImageSize {
        guard bounds.size.equalTo(.zero) == false else {
            return .pixels(GravatarDefaults.imageSize)
        }

        // Pass the size in points and let the Gravatar SDK apply the display scale.
        return .points(max(bounds.width, bounds.height))
    }
}

fileprivate struct GravatarDefaults {
    static let imageSize = 80
}

extension AvatarURL {

    public static func url(
        for email: String,
        preferredSize: Gravatar.ImageSize? = nil,
        gravatarRating: Rating? = nil,
        defaultAvatarOption: DefaultAvatarOption? = .status404
    ) -> URL? {
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
