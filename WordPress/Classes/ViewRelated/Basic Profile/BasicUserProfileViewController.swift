import Foundation

final class BasicUserProfileViewController: UIViewController, DrawerPresentable, StoryboardLoadable {
    static var defaultStoryboardName: String = "BasicUserProfile"

    var expandedHeight: DrawerHeight = DrawerHeight.contentHeight(0)

    let allowsUserTransition = false

    @IBOutlet private weak var gravatarImageView: CircularImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var aboutMeLabel: UILabel!
    @IBOutlet private weak var sitesTableView: UITableView!

    var viewModel: BasicUserProfileViewModel!

    @objc class func present(context: UIViewController, view: UIView, email: String?) {
        guard let email = email else {
            return
        }
        let controller = BasicUserProfileViewController.loadFromStoryboard()
        controller.viewModel = BasicUserProfileViewModel(email: email)

        let bottomSheet = BottomSheetViewController(childViewController: controller)
        bottomSheet.show(from: context, sourceView: view, arrowDirections: .up)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Ghost animation
        // TODO: Accessibility
        // TODO: Dark mode
        // TODO: Tracking
        // TODO: Styling

        nameLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .bold)
        usernameLabel.font = WPStyleGuide.fontForTextStyle(.caption2)
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
            strongSelf.usernameLabel.text = profile?.preferredUsername
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

            // TODO: Update sites
        }
    }

    private func downloadGravatarImageView() {
        gravatarImageView.downloadGravatarWithEmail(viewModel.email)
    }
}
