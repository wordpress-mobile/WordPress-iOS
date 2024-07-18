import UIKit
import WordPressUI
import GravatarUI

extension UIImageView {
    func setGravatarImage(with email: String, placeholder: UIImage? = nil, rating: Rating = .general) async throws {
        var options: [ImageSettingOption]?
        if let cache = WordPressUI.ImageCache.shared as? Gravatar.ImageCaching {
            options = [.imageCache(cache)]
        }
        else {
            assertionFailure("WordPressUI.ImageCache.shared should conform to Gravatar.ImageCaching")
        }
        try await gravatar.setImage(avatarID: .email(email),
                                    placeholder: placeholder,
                                    rating: .x,
                                    defaultAvatarOption: .status404,
                                    options: options)
    }
}
