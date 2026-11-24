import Combine
import UIKit

final class MyProfileIconView: UIImageView {
    private var avatarSubscription: AnyCancellable?

    init() {
        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground

        // Hide only without an account: `AccountAvatar.image` is also nil while
        // loading and for an email without a Gravatar.
        isHidden = !AccountHelper.isDotcomAvailable()
        avatarSubscription = AccountAvatar.shared.$image.sink { [weak self] avatar in
            self?.image = avatar ?? .gravatarPlaceholderImage
        }

        layer.masksToBounds = true

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 36),
            heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.width / 2
    }
}
