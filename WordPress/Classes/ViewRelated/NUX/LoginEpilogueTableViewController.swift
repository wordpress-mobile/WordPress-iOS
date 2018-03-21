import UIKit
import WordPressShared


// MARK: - LoginEpilogueTableViewController
//
class LoginEpilogueTableViewController: UITableViewController {

    ///
    ///
    private let blogDataSource = BlogListDataSource()

    ///
    ///
    var epilogueUserInfo: LoginEpilogueUserInfo? {
        didSet {
            blogDataSource.loggedIn = true
        }
    }

    ///
    ///
    var blog: Blog? {
        get {
            return blogDataSource.blog
        }
        set {
            blogDataSource.blog = newValue
        }
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerNib = UINib(nibName: "EpilogueSectionHeaderFooter", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "SectionHeader")

        let userInfoNib = UINib(nibName: "EpilogueUserInfoCell", bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: "userInfo")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return blogDataSource.numberOfSections(in: tableView) + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }

        return blogDataSource.tableView(tableView, numberOfRowsInSection: section-1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "userInfo") as? EpilogueUserInfoCell else {
                fatalError("Failed to get a user info cell")
            }

            if let info = epilogueUserInfo {
                cell.configure(userInfo: info)
            }

            return cell
        }

        let wrappedPath = IndexPath(row: indexPath.row, section: indexPath.section-1)
        return blogDataSource.tableView(tableView, cellForRowAt: wrappedPath)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as? EpilogueSectionHeaderFooter else {
            fatalError("Failed to get a section header cell")
        }

        cell.titleLabel?.text = title(for: section)

        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return Settings.profileRowHeight
        }

        return Settings.blogRowHeight
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Settings.headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}


// MARK: - UITableViewDelegate methods
//
extension LoginEpilogueTableViewController {

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else {
            return
        }

        headerView.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        headerView.textLabel?.textColor = WPStyleGuide.greyDarken20()
        headerView.contentView.backgroundColor = WPStyleGuide.lightGrey()
    }
}


// MARK: - Private Methods
//
private extension LoginEpilogueTableViewController {

    func title(for section: Int) -> String {
        if section == 0 {
            return NSLocalizedString("Logged In As", comment: "Header for user info, shown after loggin in").localizedUppercase
        }

        let rowCount = blogDataSource.tableView(tableView, numberOfRowsInSection: section-1)
        if rowCount > 1 {
            return NSLocalizedString("My Sites", comment: "Header for list of multiple sites, shown after loggin in").localizedUppercase
        }

        return NSLocalizedString("My Site", comment: "Header for a single site, shown after loggin in").localizedUppercase
    }
}


// MARK: - UITableViewDelegate methods
//
private extension LoginEpilogueTableViewController {
    struct Settings {
        static let profileRowHeight = CGFloat(140)
        static let blogRowHeight = CGFloat(52)
        static let headerHeight = CGFloat(50)
    }
}
