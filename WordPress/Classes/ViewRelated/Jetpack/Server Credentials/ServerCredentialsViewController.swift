import CocoaLumberjack
import Foundation
import WordPressShared

class ServerCredentialsViewController: UITableViewController {

    // MARK: - Private Properties

    private var blog: Blog!
    private var service: JetpackScanService!
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Initialization

    convenience init(blog: Blog, service: JetpackScanService) {
        self.init(style: .grouped)
        self.blog = blog
        self.service = service
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Remote Server Credentials", comment: "Title for the Jetpack Remote Server Credentials Screen")
        ImmuTable.registerRows([EditableTextRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        reloadViewModel()
    }

    // MARK: - Model

    private func reloadViewModel() {
        // FIXME: Pass credentials retrieved from getCredentials
        self.handler.viewModel = credentialsViewModel()

        /*
        service.getCredentials(for: blog, success: { [unowned self] credentials in
            guard let credentials = credentials?.first else {
                return
            }
            self.handler.viewModel = self.credentialsViewModel(credentials)
            DDLogInfo("Fetched Remote Server Credentials")
        }, failure: { error in
            DDLogError("Error while fetching Remote Server Credentials: \(error.localizedDescription)")
        })
        */
    }

    private func credentialsViewModel(_ credentials: JetpackScanCredentials? = nil) -> ImmuTable {
        let credentialType = EditableTextRow(
            title: NSLocalizedString("Credential type", comment: "Remote Server Credentials: Credential type"),
            value: credentials?.type ?? "",
            action: nil
        )

        let serverAddress = EditableTextRow(
            title: NSLocalizedString("Server address", comment: "Remote Server Credentials: Server address"),
            value: credentials?.host ?? "",
            action: nil
        )

        var port = ""
        if let credentialsPort = credentials?.port {
            port = String(credentialsPort)
        }
        let portNumber = EditableTextRow(
            title: NSLocalizedString("Port number", comment: "Remote Server Credentials: Port number"),
            value: port,
            action: nil
        )

        let serverUsername = EditableTextRow(
            title: NSLocalizedString("Server username", comment: "Remote Server Credentials: Server username"),
            value: credentials?.user ?? "",
            action: nil
        )

        let installationPath = EditableTextRow(
            title: NSLocalizedString("WordPress installation path", comment: "Remote Server Credentials: WordPress installation path"),
            value: credentials?.path ?? "",
            action: nil
        )

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                credentialType,
                serverAddress,
                portNumber,
                serverUsername,
                installationPath
            ])
        ])
    }

}
