import UIKit
import WordPressUI
import GravatarUI

extension UIImageView {
    func setGravatarImage(with email: String, placeholder: UIImage = .gravatarPlaceholderImage, rating: Rating = .general, preferredSize: CGSize? = nil) async throws {
        var options: [ImageSettingOption]?
        if let cache = WordPressUI.ImageCache.shared as? Gravatar.ImageCaching {
            options = [.imageCache(cache)]
        }
        else {
            assertionFailure("WordPressUI.ImageCache.shared should conform to Gravatar.ImageCaching")
        }
        listenForGravatarChanges(forEmail: email)
        try await gravatar.setImage(avatarID: .email(email),
                                    placeholder: placeholder,
                                    rating: .x,
                                    preferredSize: preferredSize,
                                    defaultAvatarOption: .status404,
                                    options: options)
    }
}
