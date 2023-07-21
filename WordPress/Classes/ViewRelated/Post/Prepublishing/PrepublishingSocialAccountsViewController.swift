class PrepublishingSocialAccountsViewController: UITableViewController {
    /// TODO
    /// - grouped table view
    /// - table footer view
    /// - react after upgrade: perform sync on viewDidAppear

    typealias Connection = PrepublishingAutoSharingModel.Connection

    // MARK: Properties

    private var connections: [Connection]

    private let sharingLimit: PublicizeInfo.SharingLimit?

    private var shareMessage: String {
        didSet {
            // update the message cell.
            var contentConfiguration = messageCell.defaultContentConfiguration()
            contentConfiguration.text = Constants.messageCellLabelText
            contentConfiguration.secondaryText = shareMessage
            messageCell.contentConfiguration = contentConfiguration
        }
    }

    private lazy var messageCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: Constants.messageCellIdentifier)
        WPStyleGuide.configureTableViewCell(cell)

        return cell
    }()

    // MARK: Methods

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(model: PrepublishingAutoSharingModel) {
        self.connections = model.services.flatMap { $0.connections }
        self.shareMessage = model.message
        self.sharingLimit = model.sharingLimit

        super.init(style: .insetGrouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.navigationTitle

        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: Constants.accountCellIdentifier)
    }
}

// MARK: - UITableView

extension PrepublishingSocialAccountsViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count + 1 // message row
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < connections.count {
            return accountCell(for: indexPath)
        }

        return messageCell
    }

    // TODO: Footer view
}

// MARK: - Private Helpers

private extension PrepublishingSocialAccountsViewController {

    func accountCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let connection = connections[safe: indexPath.row],
              let cell = tableView.dequeueReusableCell(withIdentifier: Constants.accountCellIdentifier) as? SwitchTableViewCell else {
            return UITableViewCell()
        }

        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.text = connection.account
        cell.contentConfiguration = contentConfiguration
        cell.on = connection.enabled
        cell.onChange = { [weak self] newValue in
            self?.updateConnection(at: indexPath.row, enabled: newValue)
        }

        return cell
    }

    func updateConnection(at index: Int, enabled: Bool) {
        guard index < connections.count else {
            return
        }

        connections[index].enabled = enabled

        // TODO: check between enabled and remaining values.
    }

    enum Constants {
        static let accountCellIdentifier = "AccountCell"
        static let messageCellIdentifier = "MessageCell"

        static let navigationTitle = NSLocalizedString(
            "prepublishing.socialAccounts.navigationTitle",
            value: "Social",
            comment: "The navigation title for the pre-publishing social accounts screen."
        )

        static let messageCellLabelText = NSLocalizedString(
            "prepublishing.socialAccounts.message.label",
            value: "Message",
            comment: """
                The label displayed for a table row that displays the sharing message for the post.
                Tapping on this row allows the user to edit the sharing message.
                """
        )
    }

}
