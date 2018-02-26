import UIKit

protocol SignupEpilogueTableViewControllerDelegate {
    func displayNameUpdated(newDisplayName: String)
    func passwordUpdated(newPassword: String)
}

class SignupEpilogueTableViewController: NUXTableViewController {

    // MARK: - Properties

    open var delegate: SignupEpilogueTableViewControllerDelegate?

    private var epilogueUserInfo: LoginEpilogueUserInfo?
    private var userInfoCell: EpilogueUserInfoCell?
    private var showPassword: Bool = true

    private struct Constants {
        static let numberOfSections = 3
        static let namesSectionRows = 2
        static let sectionRows = 1
        static let headerFooterHeight: CGFloat = 50
    }

    private struct TableSections {
        static let userInfo = 0
        static let names = 1
        static let password = 2
    }

    private struct CellIdentifiers {
        static let sectionHeaderFooter = "SectionHeaderFooter"
        static let signupEpilogueCell = "SignupEpilogueCell"
        static let epilogueUserInfoCell = "userInfo"
    }

    private struct CellNibNames {
        static let sectionHeaderFooter = "EpilogueSectionHeaderFooter"
        static let signupEpilogueCell = "SignupEpilogueCell"
        static let epilogueUserInfoCell = "EpilogueUserInfoCell"
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        getUserInfo()
        configureTable()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return showPassword == true ? Constants.numberOfSections : Constants.numberOfSections - 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.names {
            return Constants.namesSectionRows
        }

        return Constants.sectionRows
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var sectionTitle = ""
        if section == TableSections.userInfo {
            sectionTitle = NSLocalizedString("New Account", comment: "Header for user info, shown after account created.").localizedUppercase
        }

        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellIdentifiers.sectionHeaderFooter) as? EpilogueSectionHeaderFooter else {
            fatalError("Failed to get a section header cell")
        }
        cell.titleLabel?.text = sectionTitle

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

        if section == TableSections.password {
            guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellIdentifiers.sectionHeaderFooter) as? EpilogueSectionHeaderFooter else {
                fatalError("Failed to get a section footer cell")
            }
            cell.titleLabel?.numberOfLines = 0
            cell.titleLabel?.text = NSLocalizedString("Log in will be possible by getting a new email like the one you just used, but you can setup a password if you prefer.", comment: "Information shown below the optional password field after new account creation.")

            return cell
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == TableSections.userInfo {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.epilogueUserInfoCell) as? EpilogueUserInfoCell else {
                fatalError("Failed to get a user info cell")
            }

            if let epilogueUserInfo = epilogueUserInfo {
                cell.configure(userInfo: epilogueUserInfo, showEmail: true)
            }
            userInfoCell = cell
            return cell
        }

        if indexPath.section == TableSections.names {
            if indexPath.row == 0 {
                return getEpilogueCellFor(cellType: .displayName)
            }

            if indexPath.row == 1 {
                return getEpilogueCellFor(cellType: .username)
            }
        }

        if indexPath.section == TableSections.password {
            return getEpilogueCellFor(cellType: .password)
        }

        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Constants.headerFooterHeight
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return Constants.headerFooterHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == TableSections.password {
            return UITableViewAutomaticDimension
        }
        return 0
    }

}

// MARK: - Private Extension

private extension SignupEpilogueTableViewController {

    func configureTable() {
        let headerFooterNib = UINib(nibName: CellNibNames.sectionHeaderFooter, bundle: nil)
        tableView.register(headerFooterNib, forHeaderFooterViewReuseIdentifier: CellIdentifiers.sectionHeaderFooter)

        let cellNib = UINib(nibName: CellNibNames.signupEpilogueCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: CellIdentifiers.signupEpilogueCell)

        let userInfoNib = UINib(nibName: CellNibNames.epilogueUserInfoCell, bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: CellIdentifiers.epilogueUserInfoCell)

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        // remove empty cells
        tableView.tableFooterView = UIView()
    }

    func getUserInfo() {

        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        guard let account = service.defaultWordPressComAccount() else {
            return
        }

        var userInfo: LoginEpilogueUserInfo
        if loginFields.meta.socialService == .google {
            showPassword = false
            userInfo = LoginEpilogueUserInfo(account: account, loginFields: loginFields)
        } else {
            userInfo = LoginEpilogueUserInfo(account: account)
        }
        let autoDisplayName = generateDisplayName(from: userInfo.email)
        userInfo.fullName = autoDisplayName
        delegate?.displayNameUpdated(newDisplayName: autoDisplayName)
        epilogueUserInfo = userInfo
    }

    private func generateDisplayName(from rawEmail: String) -> String {
        // step 1: lower case
        let email = rawEmail.lowercased()
        // step 2: remove the @ and everything after
        let localPart = email.split(separator: "@")[0]
        // step 3: remove all non-alpha characters
        let localCleaned = localPart.replacingOccurrences(of: "[^A-Za-z/.]", with: "", options: .regularExpression) //, range: nil)
        // step 4: turn periods into spaces
        let nameLowercased = localCleaned.replacingOccurrences(of: ".", with: " ")
        // step 5: capitalize
        let autoDisplayName = nameLowercased.capitalized
        
        return autoDisplayName
    }

    func getEpilogueCellFor(cellType: EpilogueCellType) -> SignupEpilogueCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.signupEpilogueCell) as? SignupEpilogueCell else {
            fatalError("Failed to get epilogue cell")
        }

        switch cellType {
        case .displayName:
            cell.configureCell(forType: .displayName,
                               labelText: NSLocalizedString("Display Name", comment: "Display Name label text."),
                               fieldValue: epilogueUserInfo?.fullName)
        case .username:
            cell.configureCell(forType: .username,
                               labelText: NSLocalizedString("Username", comment: "Username label text."),
                               fieldValue: epilogueUserInfo?.username)
        case .password:
            cell.configureCell(forType: .password,
                               labelText: NSLocalizedString("Password", comment: "Password label text."),
                               fieldValue: nil,
                               fieldPlaceholder: NSLocalizedString("Optional", comment: "Password field placeholder text"))
        }

        cell.delegate = self
        return cell
    }

}

// MARK: - SignupEpilogueCellDelegate

extension SignupEpilogueTableViewController: SignupEpilogueCellDelegate {

    func updated(value: String, forType: EpilogueCellType) {
        switch forType {
        case .displayName:
            delegate?.displayNameUpdated(newDisplayName: value)
        case .password:
            delegate?.passwordUpdated(newPassword: value)
        default:
            break
        }
    }

    func changed(value: String, forType: EpilogueCellType) {
        if forType == .displayName {
            userInfoCell?.fullNameLabel?.text = value
        }
    }

    func usernameSelected() {
        let alertController = UIAlertController(title: nil, message: "Username changer coming soon!", preferredStyle: .alert)
        alertController.addDefaultActionWithTitle("OK")
        present(alertController, animated: true, completion: nil)
    }

}
