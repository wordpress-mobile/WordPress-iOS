import UIKit
import WordPressShared

// wrap BlogListDataSource calls to add a section for the user's info cell
class LoginEpilogueTableView: UITableViewController {
    @objc var blogDataSource: BlogListDataSource
    var blogCount: Int?
    var epilogueUserInfo: LoginEpilogueUserInfo? {
        didSet {
            blogDataSource.blog = epilogueUserInfo?.blog
            blogDataSource.loggedIn = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        blogDataSource = BlogListDataSource()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let headerNib = UINib(nibName: "LoginEpilogueSectionHeader", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "SectionHeader")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return blogDataSource.numberOfSections(in: tableView) + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            let count = blogDataSource.tableView(tableView, numberOfRowsInSection: section-1)
            blogCount = count
            return count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "userInfo") as? LoginEpilogueUserInfoCell else {
                fatalError("Failed to get a user info cell")
            }

            if let info = epilogueUserInfo {
                cell.configure(userInfo: info)
            }

            return cell
        } else {
            let wrappedPath = IndexPath(row: indexPath.row, section: indexPath.section-1)
            return blogDataSource.tableView(tableView, cellForRowAt: wrappedPath)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionTitle: String
        if section == 0 {
            sectionTitle = NSLocalizedString("Logged In As", comment: "Header for user info, shown after loggin in").localizedUppercase
        } else {
            switch blogCount {
            case .some(let count) where count > 1:
                sectionTitle = NSLocalizedString("My Sites", comment: "Header for list of multiple sites, shown after loggin in").localizedUppercase
            case .some(let count) where count == 1:
                sectionTitle = NSLocalizedString("My Site", comment: "Header for a single site, shown after loggin in").localizedUppercase
            default:
                sectionTitle = ""
            }
        }

        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as? LoginEpilogueSectionHeader else {
            fatalError("Failed to get a section header cell")
        }
        cell.titleLabel?.text = sectionTitle

        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 140.0
        } else {
            return 52.0
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
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

/// UITableViewDelegate methods
extension LoginEpilogueTableView {
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else {
            return
        }
        headerView.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        headerView.textLabel?.textColor = WPStyleGuide.greyDarken20()
        headerView.contentView.backgroundColor = WPStyleGuide.lightGrey()
    }
}
