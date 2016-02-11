import UIKit
import WordPressShared

@objc public class SharingAccountViewController : UITableViewController
{
    var publicizeService: PublicizeService
    var keyringConnections: [KeyringConnection]
    var existingPublicizeConnections: [PublicizeConnection]?
    var immutableHandler: ImmuTableViewHandler!
    var delegate: SharingAccountSelectionDelegate?


    //MARK: - Lifecycle Methods


    ///
    ///
    ///
    init(service: PublicizeService, connections: [KeyringConnection], existingConnections: [PublicizeConnection]?) {
        publicizeService = service
        keyringConnections = connections
        existingPublicizeConnections = existingConnections

        super.init(style: .Grouped)

        navigationItem.title = publicizeService.serviceID
    }


    required public init?(coder aDecoder: NSCoder) {
        // TODO:
        fatalError("init(coder:) has not been implemented")
    }


    public override func viewDidLoad() {
        super.viewDidLoad()

        configureNavbar()
        configureTableView()
    }


    // MARK: - Configuration


    ///
    ///
    ///
    private func configureNavbar() {
        let image = UIImage(named: "gridicons-cross")
        let closeButton = UIBarButtonItem(image: image, style: .Plain, target: self, action: "handleCloseTapped:")
        closeButton.tintColor = UIColor.whiteColor()
        navigationItem.leftBarButtonItem = closeButton

        if let navBar = navigationController?.navigationBar {
            navBar.shadowImage = UIImage(color: UIColor(fromHex: 0x007eb1))
            navBar.setBackgroundImage(UIImage(color: WPStyleGuide.wordPressBlue()), forBarMetrics: .Default)
            navBar.barStyle = .Black
        }
    }


    ///
    ///
    ///
    private func configureTableView() {
        ImmuTable.registerRows([TextRow.self], tableView: tableView)

        immutableHandler = ImmuTableViewHandler(takeOver: self)
        immutableHandler.viewModel = tableViewModel()
    }


    // MARK: - View Model Wrangling


    ///
    ///
    ///
    private func tableViewModel() -> ImmuTable {
        var sections = [ImmuTableSection]()
        var connectedAccounts = [KeyringAccount]()
        var accounts = keyringAccountsFromKeyringConnections(keyringConnections)

        // Filter out connected accounts into a different Array
        for (idx, acct) in accounts.enumerate() {
            if accountIsConnected(acct) {
                connectedAccounts.append(acct)
                accounts.removeAtIndex(idx)
                break
            }
        }

        // Build the section for unconnected accounts
        var rows = rowsForUnconnectedKeyringAccounts(accounts)
        if let section = sectionForUnconnectedKeyringAccountRows(rows) {
            sections.append(section)
        }

        // Build the section for connected accounts
        rows = rowsForConnectedKeyringAccounts(connectedAccounts)
        if rows.count > 0 {
            let title = NSLocalizedString("Connected", comment: "Adjective. The title of a list of third-part sharing service account names.")
            let section = ImmuTableSection(headerText: title, rows: rows, footerText: nil)
            sections.append(section)
        }

        return ImmuTable(sections: sections)
    }


    ///
    ///
    ///
    private func sectionForUnconnectedKeyringAccountRows(rows: [ImmuTableRow]) -> ImmuTableSection? {
        if rows.count == 0 {
            return nil
        }

        var title =  NSLocalizedString("Connecting %@", comment: "Connecting is a verb. Title of Publicize account selection. The %@ is a placeholder for the service's name");
        title = NSString(format: title, publicizeService.serviceID) as String

        let manyAccountFooter = NSLocalizedString("Select the account you would like to authorize. Note that your posts will be automatically shared to the selected account.", comment: "")
        let oneAccountFooter = NSLocalizedString("Confirm this is the account you would like to authorize. Note that your posts will be automatically shared to this account.", comment: "")
        let footer = rows.count > 1 ? manyAccountFooter : oneAccountFooter

        return ImmuTableSection(headerText: title, rows: rows, footerText: footer)
    }


    ///
    ///
    ///
    private func rowsForUnconnectedKeyringAccounts(accounts: [KeyringAccount]) -> [ImmuTableRow] {
        var rows = [ImmuTableRow]()
        for acct in accounts {
            let row = KeyringRow(title: acct.name, value: "", action: actionForRow(acct));

            rows.append(row)
        }

        return rows
    }


    ///
    ///
    ///
    private func actionForRow(keyringAccount: KeyringAccount) -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)

            self.delegate?.sharingAccountViewController(self,
                selectedKeyringConnection: keyringAccount.keyringConnection,
                externalID: keyringAccount.externalID)
        }
    }


    ///
    ///
    ///
    private func rowsForConnectedKeyringAccounts(accounts: [KeyringAccount]) -> [ImmuTableRow] {
        var rows = [ImmuTableRow]()
        for acct in accounts {
            let row = TextRow(title: acct.name, value: "");
            rows.append(row)
        }

        return rows
    }


    ///
    ///
    ///
    private func keyringAccountsFromKeyringConnections(connections: [KeyringConnection]) -> [KeyringAccount] {
        var accounts = [KeyringAccount]()

        for connection in connections {
            let acct = KeyringAccount(name: connection.externalDisplay, externalID: nil, keyringConnection: connection)
            accounts.append(acct)

            for externalUser in connection.additionalExternalUsers {
                let acct = KeyringAccount(name: externalUser.externalName, externalID: externalUser.externalID, keyringConnection: connection)
                accounts.append(acct)
            }
        }

        return accounts
    }


    ///
    ///
    ///
    private func accountIsConnected(keyringAccount: KeyringAccount) -> Bool {
        guard let existingConnections = existingPublicizeConnections else {
            return false
        }

        let keyringConnection = keyringAccount.keyringConnection
        for existingConnection in existingConnections {
            if existingConnection.keyringConnectionID == keyringConnection.keyringID &&
                existingConnection.keyringConnectionUserID == keyringConnection.userID &&
                existingConnection.externalID == keyringAccount.externalID {
                    return true
            }
        }

        return false
    }


    //MARK: - Actions


    ///
    ///
    ///
    func handleCloseTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.didDismissSharingAccountViewController(self)
    }


    //MARK: - Structs


    ///
    ///
    ///
    struct KeyringAccount {
        var name: String
        var externalID: String?
        var keyringConnection: KeyringConnection
    }


    ///
    ///
    ///
    struct KeyringRow : ImmuTableRow {
        static let cell = ImmuTableCell.Class(WPTableViewCellValue1)

        let title: String
        let value: String
        let action: ImmuTableAction?

        func configureCell(cell: UITableViewCell) {
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = value

            WPStyleGuide.configureTableViewCell(cell)
        }
    }
}


///
///
///
@objc protocol SharingAccountSelectionDelegate : NSObjectProtocol
{
    func didDismissSharingAccountViewController(controller: SharingAccountViewController)
    func sharingAccountViewController(controller: SharingAccountViewController, selectedKeyringConnection keyringConnection: KeyringConnection, externalID: String?)
}
