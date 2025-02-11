import UIKit

final class MyProfileIconView: UIImageView {
    private let hidesWhenEmpty: Bool

    init(hidesWhenEmpty: Bool = false) {
        self.hidesWhenEmpty = hidesWhenEmpty

        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground

        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar), name: .GravatarQEAvatarUpdateNotification, object: nil)

        refresh()

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

    private func refresh() {
        if let email {
            isHidden = false
            downloadGravatar(for: email, gravatarRating: .x, forceRefresh: false)
        } else {
            isHidden = true
        }
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email, notification.userInfoHasEmail(email) else { return }
        downloadGravatar(for: email, gravatarRating: .x, forceRefresh: true)
    }

    private var email: String? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)?.email
    }
}
