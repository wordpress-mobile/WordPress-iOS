import Foundation

final class BasicUserProfileViewController: UIViewController, DrawerPresentable, StoryboardLoadable {
    static var defaultStoryboardName: String = "BasicUserProfile"

    let allowsUserTransition = false

    var expandedHeight: DrawerHeight = DrawerHeight.intrinsicHeight

    var viewModel: BasicUserProfileViewModel?

    private var isInitialDisplay = true

    @IBOutlet private weak var gravatarImageView: CircularImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var aboutMeLabel: UILabel!
    @IBOutlet private weak var contentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO - BASICPROFILES: Tracking

        applyStyling()
        downloadGravatarImageView()

        viewModel?.fetchUserDetails { [weak self] profile in
            guard let self = self else {
                return
            }

            self.nameLabel.text = profile?.formattedName
            self.usernameLabel.text = "@\(profile?.preferredUsername ?? "")"
            if let location = profile?.currentLocation {
                self.locationLabel.text = location
            } else {
                self.locationLabel.isHidden = true
            }
            if let aboutMe = profile?.aboutMe {
                self.aboutMeLabel.text = aboutMe
            } else {
                self.aboutMeLabel.isHidden = true
            }

            self.contentView.stopGhostAnimation()

            // TODO - BASICPROFILES: Update sites
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isInitialDisplay {
            contentView.startGhostAnimation()
            isInitialDisplay = false
        }
    }

    private func applyStyling() {
        nameLabel.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        usernameLabel.font = WPStyleGuide.fontForTextStyle(.callout)
        locationLabel.font = WPStyleGuide.fontForTextStyle(.caption1)
        aboutMeLabel.font = WPStyleGuide.fontForTextStyle(.caption1)

        nameLabel.textColor = .text
        usernameLabel.textColor = .textSubtle
        locationLabel.textColor = .textSubtle
        aboutMeLabel.textColor = .text
    }

    private func downloadGravatarImageView() {
        guard let viewModel = viewModel else {
            return
        }
        if let email = viewModel.email {
            gravatarImageView.downloadGravatarWithEmail(email)
        } else if let url = viewModel.avatarURL {
            let placeholder = UIImage(named: "gravatar")
            gravatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        }
    }
}

// MARK: - Presentation

extension BasicUserProfileViewController {
    @objc class func present(context: UIViewController, view: UIView, email: String?, avatarURL: URL?) {
        guard let viewModel = BasicUserProfileViewModel(email: email, avatarURL: avatarURL) else {
            return
        }

        let controller = BasicUserProfileViewController.loadFromStoryboard()
        controller.viewModel = viewModel

        let bottomSheet = BottomSheetViewController(childViewController: controller)
        bottomSheet.show(from: context, sourceView: view, arrowDirections: .up)
    }
}
