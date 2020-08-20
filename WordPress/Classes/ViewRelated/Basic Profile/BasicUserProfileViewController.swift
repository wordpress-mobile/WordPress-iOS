import Foundation

final class BasicUserProfileViewController: UIViewController, DrawerPresentable, StoryboardLoadable {
    static var defaultStoryboardName: String = "BasicUserProfile"

    var expandedHeight: DrawerHeight = DrawerHeight.intrinsicHeight

    let allowsUserTransition = false

    @IBOutlet private weak var gravatarImageView: CircularImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var aboutMeLabel: UILabel!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var sitesTableView: UITableView!

    var viewModel: BasicUserProfileViewModel!

    @objc class func present(context: UIViewController, view: UIView, email: String?, avatarURL: URL?) {
        guard let viewModel = BasicUserProfileViewModel(email: email, avatarURL: avatarURL) else {
            return
        }

        let controller = BasicUserProfileViewController.loadFromStoryboard()
        controller.viewModel = viewModel

        let bottomSheet = BottomSheetViewController(childViewController: controller)
        bottomSheet.show(from: context, sourceView: view, arrowDirections: .up)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentView.startGhostAnimation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO - BASICPROFILES: Tracking

        nameLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        usernameLabel.font = WPStyleGuide.fontForTextStyle(.callout)
        locationLabel.font = WPStyleGuide.fontForTextStyle(.caption1)
        aboutMeLabel.font = WPStyleGuide.fontForTextStyle(.caption1)

        nameLabel.textColor = .text
        usernameLabel.textColor = .textSubtle
        locationLabel.textColor = .textSubtle
        aboutMeLabel.textColor = .text

        downloadGravatarImageView()

        viewModel.fetchUserDetails { [weak self] profile in
            guard let strongSelf = self else {
                return
            }

            strongSelf.nameLabel.text = profile?.formattedName
            strongSelf.usernameLabel.text = "@\(profile?.preferredUsername ?? "")"
            if let location = profile?.currentLocation {
                strongSelf.locationLabel.text = location
            } else {
                strongSelf.locationLabel.isHidden = true
            }
            if let aboutMe = profile?.aboutMe {
                strongSelf.aboutMeLabel.text = aboutMe
            } else {
                strongSelf.aboutMeLabel.isHidden = true
            }

            strongSelf.contentView.stopGhostAnimation()

            // TODO - BASICPROFILES: Update sites
        }
    }

    private func downloadGravatarImageView() {
        if let email = viewModel.email {
            gravatarImageView.downloadGravatarWithEmail(email)
        } else if let url = viewModel.avatarURL {
            let placeholder = UIImage(named: "gravatar")
            gravatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        }
    }
}
