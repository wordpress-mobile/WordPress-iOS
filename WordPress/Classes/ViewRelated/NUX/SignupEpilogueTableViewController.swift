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

    fileprivate enum EpilogueCellType {
        case displayName
        case username
        case password
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
        if loginFields.meta.socialService == .google {
            showPassword = false
            var userInfo = LoginEpilogueUserInfo()
            userInfo.email = loginFields.emailAddress
            userInfo.fullName = loginFields.username
            userInfo.username = loginFields.username
            epilogueUserInfo = userInfo
        } else {
            let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            if let account = service.defaultWordPressComAccount() {
                epilogueUserInfo = LoginEpilogueUserInfo(account: account)
            }
        }
    }

    func getEpilogueCellFor(cellType: EpilogueCellType) -> SignupEpilogueCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.signupEpilogueCell) as? SignupEpilogueCell else {
            fatalError("Failed to get epilogue cell")
        }

        switch cellType {
        case .displayName:
            cell.configureCell(labelText: NSLocalizedString("Display Name", comment: "Display Name label text."), fieldValue: epilogueUserInfo?.fullName)
            cell.cellField.addTarget(self, action: #selector(displayNameDidChange(_:)), for: .editingChanged)
            cell.cellField.addTarget(self, action: #selector(displayNameChanged(_:)), for: .editingDidEnd)
        case .username:
            cell.configureCell(labelText: NSLocalizedString("Username", comment: "Username label text."), fieldValue: epilogueUserInfo?.username)
            cell.accessoryType = .disclosureIndicator
            cell.cellField.addTarget(self, action: #selector(usernameSelected(_:)), for: .editingDidBegin)
        case .password:
            cell.configureCell(labelText: NSLocalizedString("Password", comment: "Password label text."), fieldValue: nil, fieldPlaceholder: NSLocalizedString("Optional", comment: "Password field placeholder text"), showSecureTextEntry: true)
            cell.cellField.addTarget(self, action: #selector(passwordChanged(_:)), for: .editingDidEnd)
        }

        return cell
    }

    // MARK: - Cell Action Handling

    @objc func displayNameDidChange(_ textField: UITextField) {
        userInfoCell?.fullNameLabel?.text = textField.text
    }

    @objc func displayNameChanged(_ textField: UITextField) {
        if let newDisplayName = textField.text {
            delegate?.displayNameUpdated(newDisplayName: newDisplayName)
        }
    }

    @objc func passwordChanged(_ textField: UITextField) {
        if let newPassword = textField.text {
            delegate?.passwordUpdated(newPassword: newPassword)
        }
    }

    @objc func usernameSelected(_ textField: UITextField) {
        let alertController = UIAlertController(title: nil, message: "Username changer coming soon!", preferredStyle: .alert)
        alertController.addDefaultActionWithTitle("OK")
        present(alertController, animated: true, completion: nil)
    }

}
