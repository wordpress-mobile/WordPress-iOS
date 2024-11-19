import UIKit

/// GravatarEmailTableViewCell: Gravatar image + Email address in a UITableViewCell.
///
class GravatarEmailTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var gravatarImageView: UIImageView?
    @IBOutlet private weak var emailLabel: UITextField?
    @IBOutlet private var containerView: UIView!

    @IBOutlet private var containerViewMargins: [NSLayoutConstraint]!
    @IBOutlet private var gravatarImageViewSizeConstraints: [NSLayoutConstraint]!

    private let gridiconSize = CGSize(width: 48, height: 48)
    private let girdiconSmallSize = CGSize(width: 32, height: 32)

    /// Public properties
    ///
    public static let reuseIdentifier = "GravatarEmailTableViewCell"
    public var onChangeSelectionHandler: ((_ sender: UITextField) -> Void)?
    private var gravatarPlaceholderImage: UIImage? = nil
    private var gravatarPreferredSize: CGSize = .zero
    private var email: String?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar), name: .GravatarQEAvatarUpdateNotification, object: nil)
    }

    /// Public Methods
    ///
    public func configure(withEmail email: String?, andPlaceholder placeholderImage: UIImage? = nil, hasBorders: Bool = false) {
        self.email = email
        gravatarImageView?.tintColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        emailLabel?.textColor = WordPressAuthenticator.shared.unifiedStyle?.gravatarEmailTextColor ?? WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor ?? WordPressAuthenticator.shared.style.subheadlineColor
        emailLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        emailLabel?.text = email

        let gridicon: UIImage = .gridicon(.userCircle, size: hasBorders ? girdiconSmallSize : gridiconSize)

        guard let email = email,
            email.isValidEmail() else {
                gravatarImageView?.image = gridicon
                return
        }
        self.gravatarPlaceholderImage = placeholderImage ?? gridicon
        self.gravatarPreferredSize = gridicon.size
        Task {
            try await downloadAvatar()
        }

        gravatarImageViewSizeConstraints.forEach { constraint in
            constraint.constant = gridicon.size.width
        }

        let margin: CGFloat = hasBorders ? 16 : 0
        containerViewMargins.forEach { constraint in
            constraint.constant = margin
        }

        containerView.layer.borderWidth = hasBorders ? 1 : 0
        containerView.layer.cornerRadius = hasBorders ? 8 : 0
        containerView.layer.borderColor = hasBorders ? UIColor.systemGray3.cgColor : UIColor.clear.cgColor
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email, notification.userInfoHasEmail(email) else { return }
        Task {
            try await downloadAvatar(forceRefresh: true)
        }
    }

    private func downloadAvatar(forceRefresh: Bool = false) async throws {
        guard let email, let gravatarPlaceholderImage else { return }
        try await gravatarImageView?.setGravatarImage(with: email, placeholder: gravatarPlaceholderImage, preferredSize: gravatarPreferredSize, forceRefresh: forceRefresh)
    }

    func updateEmailAddress(_ email: String?) {
        emailLabel?.text = email
    }

}

// MARK: - Password Manager Handling

private extension GravatarEmailTableViewCell {

    // MARK: - All Password Managers

    /// Call the handler when the text field changes.
    ///
    /// - Note: we have to manually add an action to the textfield
    /// because the delegate method `textFieldDidChangeSelection(_ textField: UITextField)`
    /// is only available to iOS 13+. When we no longer support iOS 12,
    /// `textFieldDidChangeSelection`, and `onChangeSelectionHandler` can
    /// be deleted in favor of adding the delegate method to view controllers.
    ///
    @IBAction func textFieldDidChangeSelection() {
        guard let emailTextField = emailLabel else {
            return
        }

        onChangeSelectionHandler?(emailTextField)
    }

}
