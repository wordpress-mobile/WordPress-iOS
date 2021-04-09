class UserProfileSheetViewController: UITableViewController {

    // MARK: - Properties

    private let user: RemoteUser

    // MARK: - Init

    init(user: RemoteUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
        registerTableCells()
    }

}

// MARK: - DrawerPresentable Extension

extension UserProfileSheetViewController: DrawerPresentable {

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        }

        return .contentHeight(300)
    }

}

// MARK: - UITableViewDataSource methods

extension UserProfileSheetViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        // TODO: if no site, return 1.
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // User Info Row
        if indexPath.section == Constants.userInfoSection {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: UserProfileUserInfoCell.defaultReuseID) as? UserProfileUserInfoCell else {
                return UITableViewCell()
            }

            cell.configure(withUser: user)
            return cell
        }

        // Site Row
        // TODO: replace with site cell.
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Don't show section header for User Info
        guard section != Constants.userInfoSection,
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: UserProfileSectionHeader.defaultReuseID) as? UserProfileSectionHeader else {
            return nil
        }

        // TODO: Don't show section header if there are no sites.

        header.titleLabel.text = Constants.siteSectionTitle
        return header
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // TODO: replace 44 with estimated row height for site cell.
        return indexPath.section == Constants.userInfoSection ? UserProfileUserInfoCell.estimatedRowHeight : 44
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        // TODO: return 0 if there are no sites.
        if section == Constants.userInfoSection {
            return 0
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: show site if site row selected.
    }

}

// MARK: - Private Extension

private extension UserProfileSheetViewController {

    func configureTable() {
        tableView.backgroundColor = .basicBackground
        tableView.separatorStyle = .none
    }

    func registerTableCells() {
        tableView.register(UserProfileUserInfoCell.defaultNib,
                           forCellReuseIdentifier: UserProfileUserInfoCell.defaultReuseID)

        tableView.register(UserProfileSectionHeader.defaultNib,
                           forHeaderFooterViewReuseIdentifier: UserProfileSectionHeader.defaultReuseID)
    }

    enum Constants {
        static let userInfoSection = 0
        static let siteSectionTitle = NSLocalizedString("Site", comment: "Header for a single site, shown in Notification user profile.").localizedUppercase
    }

}
