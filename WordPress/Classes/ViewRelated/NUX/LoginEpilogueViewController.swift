import UIKit
import WordPressShared

class LoginEpilogueViewController: UIViewController {
    var originalPresentingVC: UIViewController?
    var dismissBlock: ((_ cancelled: Bool) -> Void)?

    // @IBAction to allow to set the selector for target in the storyboard
    @IBAction func unwindOut(segue: UIStoryboardSegue) {
        dismissBlock?(false)
    }
}

// wrap BlogListDataSource calls to add a section for the user's info cell
class LoginEpilogueTableView: UITableViewController {
    var blogDataSource: BlogListDataSource
    var blogCount: Int?

    required init?(coder aDecoder: NSCoder) {
        blogDataSource = BlogListDataSource()
        blogDataSource.loggedin = true
        super.init(coder: aDecoder)
    }

    /// - Note: Copied from MeViewController which I bet @koke is happy about :P
    fileprivate func defaultAccount() -> WPAccount? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()
        return account
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return blogDataSource.numberOfSections(in:tableView) + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 1
        } else {
            let count = blogDataSource.tableView(tableView, numberOfRowsInSection: section-1)
            blogCount = count
            return count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "userInfo") as? LoginEpilogueUserInfoCell else {
                fatalError("Failed to get a user info cell")
            }
            guard let account = defaultAccount() else {
                return cell
            }
            if let username = account.username {
                cell.usernameLabel?.text = "@\(username)"
            } else {
                cell.usernameLabel?.text = ""
            }
            cell.gravatarView?.downloadGravatarWithEmail(account.email, rating: .x)
            cell.fullNameLabel?.text = account.displayName
            return cell
        } else {
            let wrappedPath = IndexPath(row: indexPath.row, section: indexPath.section-1)
            return blogDataSource.tableView(tableView, cellForRowAt: wrappedPath)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "LOGGED IN AS"
        } else {
            switch blogCount {
            case .none:
                return ""
            case .some(let count) where count > 1:
                return "MY SITES"
            default:
                return "MY SITE"
            }
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0) {
            return 140.0
        } else {
            return 52.0
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
