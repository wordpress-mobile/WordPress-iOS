import UIKit
import WordPressAuthenticator

// MARK: - EpilogueUserInfoCell
//
class EpilogueUserInfoCell: UITableViewCell {

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var gravatarActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var gravatarAddIcon: UIImageView!
    @IBOutlet var gravatarButton: UIButton!
    @IBOutlet var gravatarView: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    private weak var viewController: UIViewController?
    private var gravatarStatus: GravatarUploaderStatus = .idle
    private var email: String?
    private var avatarMenuController: AnyObject?
    private var allowGravatarUploads: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        configureImages()
        configureColors()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar), name: .GravatarQEAvatarUpdateNotification, object: nil)
    }

    /// Configures the cell so that the LoginEpilogueUserInfo's payload is displayed
    ///
    func configure(userInfo: LoginEpilogueUserInfo, showEmail: Bool = false, allowGravatarUploads: Bool = false, viewController: UIViewController) {
        self.allowGravatarUploads = allowGravatarUploads
        email = userInfo.email
        self.viewController = viewController

        fullNameLabel.text = userInfo.fullName
        fullNameLabel.fadeInAnimation()

        var displayUsername: String {
            if showEmail && !userInfo.email.isEmpty {
                return userInfo.email
            }

            return "@\(userInfo.username)"
        }

        usernameLabel.text = displayUsername
        usernameLabel.fadeInAnimation()

        gravatarAddIcon.isHidden = !allowGravatarUploads
        configureAccessibility()

        if allowGravatarUploads {
            setupGravatarButton(viewController: viewController)
        }

        switch gravatarStatus {
        case .uploading:
            gravatarActivityIndicator.startAnimating()
        case .finished:
            gravatarActivityIndicator.stopAnimating()
        case .idle:
            if let gravatarUrl = userInfo.gravatarUrl, let url = URL(string: gravatarUrl) {
                gravatarView.downloadImage(from: url)
            } else {
                downloadGravatar()
            }
        }
    }

    private func setupGravatarButton(viewController: UIViewController) {
        if RemoteFeatureFlag.gravatarQuickEditor.enabled() {
            gravatarButton.addTarget(self, action: #selector(gravatarButtonTapped), for: .touchUpInside)
        }
        else {
            let menuController = AvatarMenuController(viewController: viewController)
            menuController.onAvatarSelected = { [weak self] in
                self?.uploadGravatarImage($0)
            }
            self.avatarMenuController = menuController // Just retaining it
            gravatarButton.menu = menuController.makeMenu()
            gravatarButton.showsMenuAsPrimaryAction = true
            gravatarButton.addAction(UIAction { _ in
                AuthenticatorAnalyticsTracker.shared.track(click: .selectAvatar)
            }, for: .menuActionTriggered)
        }
    }

    @objc private func gravatarButtonTapped() {
        guard let email,
              let presenter = GravatarQuickEditorPresenter(email: email),
              let viewController else { return }
        presenter.presentQuickEditor(on: viewController)
    }

    private func downloadGravatar(forceRefresh: Bool = false) {
        let placeholder: UIImage = allowGravatarUploads ? .gravatarUploadablePlaceholderImage : .gravatarPlaceholderImage
        if let email {
            gravatarView.downloadGravatar(for: email, gravatarRating: .x, placeholderImage: placeholder, forceRefresh: forceRefresh)
        }
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email, notification.userInfoHasEmail(email) else { return }
        downloadGravatar(forceRefresh: true)
    }

    /// Starts the Activity Indicator Animation, and hides the Username + Fullname labels.
    ///
    func startSpinner() {
        fullNameLabel.isHidden = true
        usernameLabel.isHidden = true
        activityIndicator.startAnimating()
    }

    /// Stops the Activity Indicator Animation, and shows the Username + Fullname labels.
    ///
    func stopSpinner() {
        fullNameLabel.isHidden = false
        usernameLabel.isHidden = false
        activityIndicator.stopAnimating()
    }
}

// MARK: - Private Methods
//
private extension EpilogueUserInfoCell {

    func configureImages() {
        gravatarAddIcon.image = .gridicon(.add)
        gravatarView.image = .gravatarPlaceholderImage
    }

    func configureColors() {
        gravatarAddIcon.tintColor = UIAppColor.primary
        gravatarAddIcon.backgroundColor = .systemBackground

        fullNameLabel.textColor = .label
        fullNameLabel.font = AppStyleGuide.epilogueTitleFont

        usernameLabel.textColor = .secondaryLabel
        usernameLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .regular)
    }

    func configureAccessibility() {
        usernameLabel.accessibilityIdentifier = "login-epilogue-username-label"
        accessibilityTraits = .none

        let accessibilityFormat = NSLocalizedString("Account Information. %@. %@.", comment: "Accessibility description for account information after logging in.")
        accessibilityLabel = String(format: accessibilityFormat, fullNameLabel.text ?? "", usernameLabel.text ?? "")

        fullNameLabel.isAccessibilityElement = false
        usernameLabel.isAccessibilityElement = false
        gravatarButton.isAccessibilityElement = false

        if !gravatarAddIcon.isHidden {
            configureSignupAccessibility()
        }
    }

    func configureSignupAccessibility() {
        gravatarButton.isAccessibilityElement = true
        let accessibilityDescription = NSLocalizedString("Add account image.", comment: "Accessibility description for adding an image to a new user account. Tapping this initiates that flow.")
        gravatarButton.accessibilityLabel = accessibilityDescription

        let accessibilityHint = NSLocalizedString("Add image, or avatar, to represent this new account.", comment: "Accessibility hint text for adding an image to a new user account.")
        gravatarButton.accessibilityHint = accessibilityHint
    }
}

// MARK: - Gravatar uploading
//
extension EpilogueUserInfoCell: GravatarUploader {
    /// Update the UI based on the status of the gravatar upload
    func updateGravatarStatus(_ status: GravatarUploaderStatus) {
        gravatarStatus = status
        switch status {
        case .uploading(image: let newImage):
            gravatarView.updateGravatar(image: newImage, email: email)
            gravatarActivityIndicator.startAnimating()
        case .idle, .finished:
            gravatarActivityIndicator.stopAnimating()
        }
    }
}

extension UIImage {
    /// Returns a Gravatar Placeholder Image when uploading is allowed
    ///
    fileprivate static var gravatarUploadablePlaceholderImage: UIImage {
        return UIImage(named: "gravatar-hollow") ?? UIImage()
    }
}
