import Foundation

final class BasicUserProfileViewController: UIViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "BasicUserProfile"

    var viewModel: BasicUserProfileViewModel?

    private var isInitialDisplay = true

    private var sites: [RemoteGravatarProfileUrl] = [] {
        didSet {
            sitesTableView.reloadData()
            sitesTableView.isHidden = sites.isEmpty
        }
    }

    @IBOutlet private weak var gravatarImageView: CircularImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var aboutMeLabel: UILabel!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var sitesTableView: UITableView!
    @IBOutlet private weak var ghostableTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO - BASICPROFILES: Tracking

        configureSitesTableView()
        applyStyling()
        downloadGravatarImageView()

        viewModel?.fetchUserDetails { [weak self] profile in
            guard let self = self else {
                return
            }

            self.nameLabel.text = profile?.formattedName
            self.usernameLabel.text = "@\(profile?.preferredUsername ?? "")"
            if let location = profile?.currentLocation,
                !location.isEmpty {
                self.locationLabel.text = location
            } else {
                self.locationLabel.isHidden = true
            }
            if let aboutMe = profile?.aboutMe,
                !aboutMe.isEmpty {
                self.aboutMeLabel.text = aboutMe
            } else {
                self.aboutMeLabel.isHidden = true
            }

            self.sites = profile?.urls ?? []
            self.stopGhostAnimations()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isInitialDisplay {
            contentView.startGhostAnimation()
            updateGhostableTableViewOptions(cellClass: SiteTableViewCell.self, identifier: "Sites")
            isInitialDisplay = false
        }
    }

    private func configureSitesTableView() {
        sitesTableView.dataSource = self
        sitesTableView.register(WPBlogTableViewCell.self,
                                forCellReuseIdentifier: WPBlogTableViewCell.reuseIdentifier())
        sitesTableView.accessibilityIdentifier = "Sites"
    }

    private func applyStyling() {
        nameLabel.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        usernameLabel.font = WPStyleGuide.fontForTextStyle(.callout)
        locationLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        aboutMeLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)

        nameLabel.textColor = .text
        usernameLabel.textColor = .textSubtle
        locationLabel.textColor = .textSubtle
        aboutMeLabel.textColor = .text

        sitesTableView.tableFooterView = UIView()
    }

    private func updateGhostableTableViewOptions(cellClass: UITableViewCell.Type, identifier: String) {
        ghostableTableView.register(cellClass, forCellReuseIdentifier: identifier)
        let ghostOptions = GhostOptions(displaysSectionHeader: false,
                                        reuseIdentifier: identifier,
                                        rowsPerSection: [3])
        ghostableTableView.removeGhostContent()
        ghostableTableView.displayGhostContent(options: ghostOptions, style: GhostStyle.default)
    }

    private func stopGhostAnimations() {
        self.contentView.stopGhostAnimation()
        self.ghostableTableView.isHidden = true
        self.ghostableTableView.removeGhostContent()
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

// MARK: - UITableViewDataSource

extension BasicUserProfileViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let site = sites[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WPBlogTableViewCell.reuseIdentifier()) as? WPBlogTableViewCell else {
            fatalError("Failed to get a blog cell")
        }

        cell.textLabel?.text = site.title
        cell.detailTextLabel?.text = site.value
        cell.imageView?.image = .siteIconPlaceholder
        cell.accessibilityIdentifier = site.value

        // TODO: Display blog on selection

        viewModel?.fetchSiteIcon(url: site.value, completion: { (siteUrl, iconUrl) in
            if siteUrl == site.value,
                let iconUrl = iconUrl {
                cell.imageView?.downloadSiteIcon(at: iconUrl)
            }
        })

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Sites", comment: "Title of the header showing user's sites.")
    }
}

// MARK: - DrawerPresentable

extension BasicUserProfileViewController: DrawerPresentable {
    var scrollableView: UIScrollView? {
        return sitesTableView
    }

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        } else {
            return .contentHeight(UIScreen.main.bounds.height * 0.3)
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
