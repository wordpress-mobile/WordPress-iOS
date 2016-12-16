import UIKit
import Gridicons
import WordPressShared

/// Displays a list of available keyring connection accounts that can be used to
/// forge a publicize connection.
///
@objc open class SharingAccountViewController : UITableViewController
{
    var publicizeService: PublicizeService
    var keyringConnections: [KeyringConnection]
    var existingPublicizeConnections: [PublicizeConnection]?
    var immutableHandler: ImmuTableViewHandler!
    var delegate: SharingAccountSelectionDelegate?


    // MARK: - Lifecycle Methods


    init(service: PublicizeService, connections: [KeyringConnection], existingConnections: [PublicizeConnection]?) {
        publicizeService = service
        keyringConnections = connections
        existingPublicizeConnections = existingConnections

        super.init(style: .grouped)

        navigationItem.title = publicizeService.label
    }


    required public init?(coder aDecoder: NSCoder) {
        // TODO:
        fatalError("init(coder:) has not been implemented")
    }


    open override func viewDidLoad() {
        super.viewDidLoad()

        configureNavbar()
        configureTableView()
    }


    // MARK: - Configuration


    /// Configures the appearance of the nav bar.
    ///
    fileprivate func configureNavbar() {
        let image = Gridicon.iconOfType(.cross)
        let closeButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(SharingAccountViewController.handleCloseTapped(_:)))
        closeButton.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = closeButton

        // The preceding WPWebViewController changes the default navbar appearance. Restore it.
        if let navBar = navigationController?.navigationBar {
            navBar.shadowImage = WPStyleGuide.navigationBarShadowImage()
            navBar.setBackgroundImage(WPStyleGuide.navigationBarBackgroundImage(), for: .default)
            navBar.barStyle = WPStyleGuide.navigationBarBarStyle()
        }
    }


    /// Configures the `UITableView`
    ///
    fileprivate func configureTableView() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([TextRow.self], tableView: tableView)

        immutableHandler = ImmuTableViewHandler(takeOver: self)
        immutableHandler.viewModel = tableViewModel()
    }


    // MARK: - View Model Wrangling


    /// Builds and returns the ImmuTable view model.
    ///
    /// - Returns: An ImmuTable instance.
    ///
    fileprivate func tableViewModel() -> ImmuTable {
        var sections = [ImmuTableSection]()
        var connectedAccounts = [KeyringAccount]()
        var accounts = keyringAccountsFromKeyringConnections(keyringConnections)

        // Filter out connected accounts into a different Array
        for (idx, acct) in accounts.enumerated() {
            if accountIsConnected(acct) {
                connectedAccounts.append(acct)
                accounts.remove(at: idx)
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


    /// Builds the ImmuTableSection that displays unconnected keyring accounts.
    ///
    /// - Parameter rows: An array of ImmuTableRow objects appearing in the section.
    ///
    /// - Returns: An ImmuTableSection or `nil` if there were no rows.
    ///
    fileprivate func sectionForUnconnectedKeyringAccountRows(_ rows: [ImmuTableRow]) -> ImmuTableSection? {
        if rows.count == 0 {
            return nil
        }

        var title =  NSLocalizedString("Connecting %@", comment: "Connecting is a verb. Title of Publicize account selection. The %@ is a placeholder for the service's name")
        title = NSString(format: title as NSString, publicizeService.label) as String

        let manyAccountFooter = NSLocalizedString("Select the account you would like to authorize. Note that your posts will be automatically shared to the selected account.", comment: "")
        let oneAccountFooter = NSLocalizedString("Confirm this is the account you would like to authorize. Note that your posts will be automatically shared to this account.", comment: "")
        let footer = rows.count > 1 ? manyAccountFooter : oneAccountFooter

        return ImmuTableSection(headerText: title, rows: rows, footerText: footer)
    }


    /// Builds the ImmuTableSection that displays connected keyring accounts.
    ///
    /// - Parameter rows: An array of ImmuTableRow objects appearing in the section.
    ///
    /// - Returns: An ImmuTableSection or `nil` if there were no rows.
    ///
    fileprivate func rowsForUnconnectedKeyringAccounts(_ accounts: [KeyringAccount]) -> [ImmuTableRow] {
        var rows = [ImmuTableRow]()
        for acct in accounts {
            let row = KeyringRow(title: acct.name, value: "", action: actionForRow(acct))

            rows.append(row)
        }

        return rows
    }


    /// Builds an ImmuTableAction that should be performed when a specific row is selected.
    ///
    /// - Parameter keyringAccount: The keyring account for the row.
    ///
    /// - Returns: An ImmuTableAction instance.
    ///
    fileprivate func actionForRow(_ keyringAccount: KeyringAccount) -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)

            self.delegate?.sharingAccountViewController(self,
                selectedKeyringConnection: keyringAccount.keyringConnection,
                externalID: keyringAccount.externalID)
        }
    }


    /// Builds ImmuTableRows for the specified keyring accounts.
    ///
    /// - Parameter accounts: An array of KeyringAccount objects.
    ///
    /// - Returns: An array of ImmuTableRows representing the keyring accounts.
    ///
    fileprivate func rowsForConnectedKeyringAccounts(_ accounts: [KeyringAccount]) -> [ImmuTableRow] {
        var rows = [ImmuTableRow]()
        for acct in accounts {
            let row = TextRow(title: acct.name, value: "")
            rows.append(row)
        }

        return rows
    }


    /// Normalizes available accounts for a KeyringConnection and its `additionalExternalUsers`
    ///
    /// - Parameter connections: An array of `KeyringConnection` instances to normalize.
    ///
    /// - Returns: An array of `KeyringAccount` objects.
    ///
    fileprivate func keyringAccountsFromKeyringConnections(_ connections: [KeyringConnection]) -> [KeyringAccount] {
        var accounts = [KeyringAccount]()

        for connection in connections {
            let acct = KeyringAccount(name: connection.externalDisplay, externalID: nil, externalIDForConnection: connection.externalID, keyringConnection: connection)
            accounts.append(acct)

            for externalUser in connection.additionalExternalUsers {
                let acct = KeyringAccount(name: externalUser.externalName, externalID: externalUser.externalID, externalIDForConnection: externalUser.externalID, keyringConnection: connection)
                accounts.append(acct)
            }
        }

        return accounts
    }


    /// Checks if the specified keyring account is connected.
    ///
    /// - Parameter keyringAccount: The keyring account to check.
    ///
    /// - Returns: true if the keyring account is being used by an existing publicize connection. False otherwise.
    ///
    fileprivate func accountIsConnected(_ keyringAccount: KeyringAccount) -> Bool {
        guard let existingConnections = existingPublicizeConnections else {
            return false
        }

        let keyringConnection = keyringAccount.keyringConnection
        for existingConnection in existingConnections {
            if existingConnection.keyringConnectionID == keyringConnection.keyringID &&
                existingConnection.keyringConnectionUserID == keyringConnection.userID &&
                existingConnection.externalID == keyringAccount.externalIDForConnection {
                    return true
            }
        }

        return false
    }


    // MARK: - Actions


    /// Notifies the delegate that the user has clicked the close button to dismiss the controller.
    ///
    /// - Parameter sender: The close button that was tapped.
    ///
    func handleCloseTapped(_ sender: UIBarButtonItem) {
        delegate?.didDismissSharingAccountViewController(self)
    }


    // MARK: - Structs


    /// KeyringAccount is used to normalize the list of avaiable accounts while
    /// preserving the owning keyring connection.
    ///
    struct KeyringAccount {
        var name: String // The account name
        var externalID: String? // The actual externalID value that should be passed when creating/updating a publicize connection.
        var externalIDForConnection: String // The effective external ID that should be used for comparing a keyring account with a PublicizeConnection.
        var keyringConnection: KeyringConnection
    }


    /// An ImmuTableRow class.
    ///
    struct KeyringRow : ImmuTableRow {
        static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

        let title: String
        let value: String
        let action: ImmuTableAction?

        func configureCell(_ cell: UITableViewCell) {
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = value

            WPStyleGuide.configureTableViewCell(cell)
        }
    }
}


/// Delegate protocol.
///
@objc protocol SharingAccountSelectionDelegate : NSObjectProtocol
{
    func didDismissSharingAccountViewController(_ controller: SharingAccountViewController)
    func sharingAccountViewController(_ controller: SharingAccountViewController, selectedKeyringConnection keyringConnection: KeyringConnection, externalID: String?)
}
