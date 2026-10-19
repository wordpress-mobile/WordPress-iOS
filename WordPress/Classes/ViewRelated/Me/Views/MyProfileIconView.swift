import Combine
import UIKit

final class MyProfileIconView: UIImageView {
    private let hidesWhenEmpty: Bool
    private var avatarSubscription: AnyCancellable?

    init(hidesWhenEmpty: Bool = false) {
        self.hidesWhenEmpty = hidesWhenEmpty

        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground

        avatarSubscription = AccountAvatar.shared.$image.sink { [weak self] avatar in
            self?.updateAvatar(avatar)
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

    private func updateAvatar(_ avatar: UIImage?) {
        image = avatar
        isHidden = avatar == nil && hidesWhenEmpty
    }
}
