import UIKit

class SignupEpilogueTableViewController: NUXTableViewController {

    // MARK: - Properties

    private struct Constants {
        static let numberOfSections = 3
        static let namesSectionRows = 2
        static let sectionRows = 1
        static let headerHeight: CGFloat = 50
    }

    private struct TableSections {
        static let userInfo = 0
        static let names = 1
        static let password = 2
    }

    private enum EpilogueCellType {
        case displayName
        case username
        case password
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerNib = UINib(nibName: "LoginEpilogueSectionHeader", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "SectionHeader")

        let displayNameNib = UINib(nibName: "SignupEpilogueCell", bundle: nil)
        tableView.register(displayNameNib, forCellReuseIdentifier: "SignupEpilogueCell")

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        // remove empty cells
        tableView.tableFooterView = UIView()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.numberOfSections
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

        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as? LoginEpilogueSectionHeader else {
            fatalError("Failed to get a section header cell")
        }
        cell.titleLabel?.text = sectionTitle

        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == TableSections.names {
            if indexPath.row == 0 {
                return getEpilogueCellFor(cellType: .displayName)
            }

            if indexPath.row == 1 {
                return getEpilogueCellFor(cellType: .username)
            }
        }

        if indexPath.section == TableSections.password {
            if indexPath.row == 0 {
                return getEpilogueCellFor(cellType: .password)
            }
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Constants.headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    // MARK: - Cell Creation

    private func getEpilogueCellFor(cellType: EpilogueCellType) -> SignupEpilogueCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SignupEpilogueCell") as? SignupEpilogueCell else {
            fatalError("Failed to get epilogue cell")
        }

        switch cellType {
        case .displayName:

            // TODO: use real user values

            cell.configureCell(labelText: NSLocalizedString("Display Name", comment: "Display Name label text."), fieldValue: "Juanita Gonzales")
        case .username:
            cell.configureCell(labelText: NSLocalizedString("Username", comment: "Username label text."), fieldValue: "juanitagonzales666")
            cell.accessoryType = .disclosureIndicator
            cell.cellField.isUserInteractionEnabled = false
        case .password:
            cell.configureCell(labelText: NSLocalizedString("Password", comment: "Password label text."), fieldValue: nil, fieldPlaceholder: NSLocalizedString("Optional", comment: "Password field placeholder text"), showSecureTextEntry: true)
        }

        return cell
    }
}
