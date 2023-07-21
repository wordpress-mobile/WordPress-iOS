class PrepublishingSocialAccountsViewController: UITableViewController {

    // MARK: Properties

    private var connections: [Connection]

    private let sharingLimit: PublicizeInfo.SharingLimit?

    private var shareMessage: String {
        didSet {
            messageCell.detailTextLabel?.text = shareMessage
        }
    }

    private var isSharingLimitReached: Bool = false {
        didSet {
            guard oldValue != isSharingLimitReached else {
                return // no need to reload if the value doesn't change.
            }
            // only reload connections that are turned off.
            // the last toggled row is skipped so it can perform its full switch animation.
            tableView.reloadRows(at: indexPathsForDisabledConnections.filter { $0.row != lastToggledRow }, with: .none)
        }
    }

    /// Store the last table row toggled by the user.
    private var lastToggledRow: Int = -1

    private lazy var messageCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: Constants.messageCellIdentifier)
        WPStyleGuide.configureTableViewCell(cell)

        cell.textLabel?.text = Constants.messageCellLabelText
        cell.detailTextLabel?.text = shareMessage
        cell.accessoryType = .disclosureIndicator

        return cell
    }()

    // MARK: Methods

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(model: PrepublishingAutoSharingModel) {
        self.connections = model.services.flatMap { service in
            service.connections.map {
                .init(service: service.name, account: $0.account, keyringID: $0.keyringID, isOn: $0.enabled)
            }
        }
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
        return connections.count + 1 // extra row for the sharing message
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < connections.count {
            return accountCell(for: indexPath)
        }

        return messageCell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // interactions for the account switches are absorbed by the tap gestures set up in the SwitchTableViewCell,
        // so it shouldn't trigger this method. In any case, we should only care about handling taps on the message row.
        guard indexPath.row == connections.count else {
            return
        }

        showEditMessageScreen()
    }
}

// MARK: - Private Helpers

private extension PrepublishingSocialAccountsViewController {

    var enabledCount: Int {
        connections.filter { $0.isOn }.count
    }

    var indexPathsForDisabledConnections: [IndexPath] {
        connections.indexed().compactMap { $1.isOn ? nil : IndexPath(row: $0, section: .zero) }
    }

    func accountCell(for indexPath: IndexPath) -> UITableViewCell {
        guard var connection = connections[safe: indexPath.row],
              let cell = tableView.dequeueReusableCell(withIdentifier: Constants.accountCellIdentifier) as? SwitchTableViewCell else {
            return UITableViewCell()
        }

        cell.textLabel?.text = connection.account
        cell.textLabel?.numberOfLines = 1
        cell.imageView?.image = connection.imageForCell
        cell.on = connection.isOn
        cell.onChange = { [weak self] newValue in
            self?.updateConnection(at: indexPath.row, enabled: newValue)
        }

        let isInteractionAllowed = connection.isOn || !isSharingLimitReached
        isInteractionAllowed ? cell.enable() : cell.disable()
        cell.imageView?.alpha = isInteractionAllowed ? 1.0 : Constants.disabledCellImageOpacity

        cell.accessibilityLabel = "\(connection.service.description), \(connection.account)"

        return cell
    }

    func updateConnection(at index: Int, enabled: Bool) {
        guard index < connections.count else {
            return
        }

        // directly mutate the value to avoid copy-on-write.
        connections[index].isOn = enabled
        lastToggledRow = index

        toggleInteractivityIfNeeded()
    }

    func toggleInteractivityIfNeeded() {
        guard let sharingLimit else {
            // if sharing limit does not exist, then interactions should be unlimited.
            isSharingLimitReached = false
            return
        }

        isSharingLimitReached = enabledCount >= sharingLimit.remaining
    }

    func showEditMessageScreen() {
        let multiTextViewController = SettingsMultiTextViewController(text: shareMessage,
                                                                      placeholder: nil,
                                                                      hint: Constants.editShareMessageHint,
                                                                      isPassword: false)

        multiTextViewController.title = Constants.editShareMessageNavigationTitle
        multiTextViewController.onValueChanged = { [weak self] newValue in
            self?.shareMessage = newValue
        }

        self.navigationController?.pushViewController(multiTextViewController, animated: true)
    }

    /// Convenient model that represents the user's Publicize connections.
    struct Connection {
        let service: PublicizeService.ServiceName
        let account: String
        let keyringID: Int
        var isOn: Bool

        lazy var imageForCell: UIImage = {
            service.localIconImage.resizedImage(with: .scaleAspectFit,
                                                bounds: Constants.cellImageSize,
                                                interpolationQuality: .default)
        }()
    }

    // MARK: Constants

    enum Constants {
        static let disabledCellImageOpacity = 0.36
        static let cellImageSize = CGSize(width: 28.0, height: 28.0)

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

        static let editShareMessageNavigationTitle = NSLocalizedString(
            "prepublishing.socialAccounts.editMessage.navigationTitle",
            value: "Customize message",
            comment: "The navigation title for a screen that edits the sharing message for the post."
        )

        static let editShareMessageHint = NSLocalizedString(
            "prepublishing.socialAccounts.editMessage.hint",
            value: """
                Customize the message you want to share.
                If you don't add your own text here, we'll use the post's title as the message.
                """,
            comment: "A hint shown below the text field when editing the sharing message from the pre-publishing flow."
        )
    }

}
