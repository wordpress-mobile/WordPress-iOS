import Foundation
import Gravatar
import WordPressUI

// Convenience intermediate enum for Objc compatibility.
@objc(GravatarRating)
/// Gravatar Image Ratings for Objc compatibility.
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
    public func downloadGravatar(for email: String, gravatarRating: Rating = .general, placeholderImage: UIImage = .gravatarPlaceholderImage) {
        let avatarURL = AvatarURL.url(for: email, preferredSize: .pixels(gravatarDefaultSize()), gravatarRating: gravatarRating)
        listenForGravatarChanges(forEmail: email)
        downloadGravatar(fullURL: avatarURL, placeholder: placeholderImage, animate: false, failure: nil)
    }

    public func downloadGravatar(_ gravatar: AvatarURL?, placeholder: UIImage, animate: Bool, failure: ((Error?) -> ())? = nil) {
        guard let gravatar = gravatar else {
            self.image = placeholder
            return
        }

        // Starting with iOS 10, it seems `initWithCoder` uses a default size
        // of 1000x1000, which was messing with our size calculations for gravatars
        // on newly created table cells.
        // Calling `layoutIfNeeded()` forces UIKit to calculate the actual size.
        layoutIfNeeded()

        let size = Int(ceil(frame.width * UIScreen.main.scale))
        let url = gravatar.replacing(options: .init(preferredSize: .pixels(size)))?.url
        downloadGravatar(fullURL: url, placeholder: placeholder, animate: animate, failure: failure)
    }

    private func downloadGravatar(fullURL: URL?, placeholder: UIImage, animate: Bool, failure: ((Error?) -> ())? = nil) {
        self.gravatar.cancelImageDownload()
        guard let cache = WordPressUI.ImageCache.shared as? GravatarImageCaching else {
            assertionFailure("WordPressUI.ImageCache.shared should conform to GravatarImageCaching.")
            return
        }
        let options: [ImageSettingOption] = [.imageCache(cache)]
        self.gravatar.setImage(with: fullURL,
                               placeholder: placeholder,
                               options: options) { [weak self] result in
            switch result {
            case .success:
                if animate {
                    self?.fadeInAnimation()
                }
            case .failure(let error):
                failure?(error)
            }
        }
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
