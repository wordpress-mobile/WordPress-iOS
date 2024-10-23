import UIKit
import WordPressUI
import GravatarUI

extension UIImageView {
    func setGravatarImage(with email: String, placeholder: UIImage = .gravatarPlaceholderImage, rating: Rating = .general, preferredSize: CGSize? = nil) async throws {
        listenForGravatarChanges(forEmail: email)
        try await gravatar.setImage(avatarID: .email(email),
                                    placeholder: placeholder,
                                    rating: .x,
                                    preferredSize: preferredSize,
                                    defaultAvatarOption: .status404)
    }
}
