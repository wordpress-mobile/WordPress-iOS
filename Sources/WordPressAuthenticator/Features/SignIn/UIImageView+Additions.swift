import UIKit
import WordPressUI
import GravatarUI

extension UIImageView {
    func setGravatarImage(with email: String, placeholder: UIImage = .gravatarPlaceholderImage, rating: Rating = .general, preferredSize: CGSize? = nil, forceRefresh: Bool = false) async throws {
        listenForGravatarChanges(forEmail: email)
        var options: [ImageSettingOption] = []
        if forceRefresh {
            options.append(.forceRefresh)
        }
        try await gravatar.setImage(avatarID: .email(email),
                                    placeholder: placeholder,
                                    rating: rating,
                                    preferredSize: preferredSize,
                                    defaultAvatarOption: .status404,
                                    options: options)
    }
}
