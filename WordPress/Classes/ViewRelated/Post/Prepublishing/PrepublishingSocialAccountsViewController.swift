import WordPressUI

protocol PrepublishingSocialAccountsDelegate: NSObjectProtocol {

    func didUpdateSharingLimit(with newValue: PublicizeInfo.SharingLimit?)

    func didFinish(with connectionChanges: [Int: Bool], message: String?)
}

class PrepublishingSocialAccountsViewController: UITableViewController {

    // MARK: Properties

    private let coreDataStack: CoreDataStackSwift

    private let service: BlogService

    private weak var delegate: PrepublishingSocialAccountsDelegate?

    private let blogID: Int

    private let connections: [Connection]

    private let originalMessage: String

    private var connectionChanges = [Int: Bool]()

    private var sharingLimit: PublicizeInfo.SharingLimit? {
        didSet {
            toggleInteractivityIfNeeded()
            tableView.reloadData()
            delegate?.didUpdateSharingLimit(with: sharingLimit)
        }
    }

    private var shareMessage: String {
        didSet {
            messageCell.detailTextLabel?.text = shareMessage
        }
    }

    var onContentHeightUpdated: (() -> Void)? = nil

    /// Stores the interaction state for disabled connections.
    /// The value is stored in order to perform table operations *only* when the value changes.
    private var canInteractWithDisabledConnections: Bool {
        didSet {
            guard oldValue != canInteractWithDisabledConnections else {
                return
            }
            // only reload connections that are turned off.
            // the last toggled row is skipped so it can perform its full switch animation.
            tableView.reloadRows(at: indexPathsForDisabledConnections.filter { $0.row != lastToggledRow }, with: .none)
            lastToggledRow = -1 // reset once the reload completes.
        }
    }

    /// Stores the last table row toggled by the user.
    ///
    /// This property is only used for visual purposes, to allow the toggled cell's switch animation to complete
    /// instead of having it abruptly stopped due to the table view reload.
    private var lastToggledRow: Int = -1

    private lazy var messageCell: UITableViewCell = {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: Constants.messageCellIdentifier)
        WPStyleGuide.configureTableViewCell(cell)

        cell.textLabel?.text = Constants.messageCellLabelText
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.text = shareMessage
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            cell.detailTextLabel?.numberOfLines = 3
        }
        cell.accessoryType = .disclosureIndicator

        return cell
    }()

    // MARK: Methods

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(blogID: Int,
         model: PrepublishingAutoSharingModel,
         delegate: PrepublishingSocialAccountsDelegate?,
         coreDataStack: CoreDataStackSwift = ContextManager.shared,
         blogService: BlogService? = nil) {
        self.blogID = blogID
        self.connections = model.services.flatMap { service in
            service.connections.map {
                .init(service: service.name, account: $0.account, keyringID: $0.keyringID, isOn: $0.enabled)
            }
        }
        self.originalMessage = model.message
        self.shareMessage = originalMessage
        self.sharingLimit = model.sharingLimit
        self.delegate = delegate
        self.coreDataStack = coreDataStack
        self.service = blogService ?? BlogService(coreDataStack: coreDataStack)
        self.canInteractWithDisabledConnections = model.enabledConnectionsCount < (sharingLimit?.remaining ?? .max)

        super.init(style: .insetGrouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.navigationTitle

        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: Constants.accountCellIdentifier)

        // setting a custom spacer view will override the default 34pt padding from the grouped table view style.
        tableView.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 0, height: Constants.tableTopPadding))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // manually configure preferredContentSize for precise drawer sizing.
        let bottomInset = max(UIApplication.shared.mainWindow?.safeAreaInsets.bottom ?? 0, Constants.defaultBottomInset)
        let contentHeight = tableView.contentSize.height + bottomInset + Constants.additionalBottomInset
        preferredContentSize = CGSize(width: tableView.contentSize.width,
                                      height: max(contentHeight, Constants.minContentHeight))
        onContentHeightUpdated?()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // when the vertical size class changes, ensure that we are displaying the max drawer height on compact size
        // or revert to collapsed mode otherwise.
        if let previousVerticalSizeClass = previousTraitCollection?.verticalSizeClass,
           previousVerticalSizeClass != traitCollection.verticalSizeClass {
            presentedVC?.transition(to: traitCollection.verticalSizeClass == .compact ? .expanded : .collapsed)
        }
    }

    deinit {
        // only call the delegate method if the user has made some changes.
        if hasChanges {
            delegate?.didFinish(with: connectionChanges, message: shareMessage)
        }
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

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let sharingLimit else {
            return nil
        }

        return PrepublishingSocialAccountsTableFooterView(remaining: sharingLimit.remaining,
                                                          showsWarning: shouldDisplayWarning,
                                                          onButtonTap: { [weak self] in
            self?.subscribeButtonTapped()
        })
    }
}

// MARK: - Private Helpers

private extension PrepublishingSocialAccountsViewController {

    var enabledCount: Int {
        connections
            .filter { connectionChanges[$0.keyringID] ?? $0.isOn }
            .count
    }

    var indexPathsForDisabledConnections: [IndexPath] {
        connections.indices.compactMap { index in
            valueForConnection(at: index) ? nil : IndexPath(row: index, section: .zero)
        }
    }

    var shouldDisplayWarning: Bool {
        connections.count >= (sharingLimit?.remaining ?? .max)
    }

    var hasChanges: Bool {
        !connectionChanges.isEmpty || shareMessage != originalMessage
    }

    func accountCell(for indexPath: IndexPath) -> UITableViewCell {
        guard var connection = connections[safe: indexPath.row],
              let cell = tableView.dequeueReusableCell(withIdentifier: Constants.accountCellIdentifier) as? SwitchTableViewCell else {
            return UITableViewCell()
        }

        cell.textLabel?.text = connection.account
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.imageView?.image = connection.imageForCell
        cell.on = valueForConnection(at: indexPath.row)
        cell.onChange = { [weak self] newValue in
            self?.updateConnection(at: indexPath.row, value: newValue)
        }

        let isInteractionAllowed = cell.on || canInteractWithDisabledConnections
        isInteractionAllowed ? cell.enable() : cell.disable()
        cell.imageView?.alpha = isInteractionAllowed ? 1.0 : Constants.disabledCellImageOpacity

        cell.accessibilityLabel = "\(connection.service.description), \(connection.account)"

        return cell
    }

    func valueForConnection(at index: Int) -> Bool {
        guard let connection = connections[safe: index] else {
            return false
        }
        return connectionChanges[connection.keyringID] ?? connection.isOn
    }

    func updateConnection(at index: Int, value: Bool) {
        guard let connection = connections[safe: index] else {
            return
        }

        let originalValue = connection.isOn

        if value == originalValue {
            connectionChanges.removeValue(forKey: connection.keyringID)
        } else {
            connectionChanges[connection.keyringID] = value
        }

        lastToggledRow = index
        toggleInteractivityIfNeeded()

        WPAnalytics.track(.jetpackSocialConnectionToggled, properties: ["source": Constants.trackingSource, "value": value])
    }

    func toggleInteractivityIfNeeded() {
        canInteractWithDisabledConnections = enabledCount < (sharingLimit?.remaining ?? .max)
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

    func subscribeButtonTapped() {
        guard let checkoutViewController = makeCheckoutViewController() else {
            return
        }

        WPAnalytics.track(.jetpackSocialUpgradeLinkTapped, properties: ["source": Constants.trackingSource])

        let navigationController = UINavigationController(rootViewController: checkoutViewController)
        show(navigationController, sender: nil)
    }

    func makeCheckoutViewController() -> UIViewController? {
        return coreDataStack.performQuery { [weak self] context in
            guard let self,
                  let blog = try? Blog.lookup(withID: self.blogID, in: context),
                  let host = blog.hostname,
                  let url = URL(string: "https://wordpress.com/checkout/\(host)/jetpack_social_basic_yearly") else {
                return nil
            }

            return WebViewControllerFactory.controller(url: url, blog: blog, source: Constants.webViewSource) {
                self.checkoutDismissed()
            }
        }
    }

    /// When the checkout web view is dismissed, try to sync the latest sharing limit in case the user did make
    /// a purchase. We can make this assumption if the returned `sharingLimit` is nil, which means there's no longer
    /// any sharing limit for the site.
    func checkoutDismissed() {
        assert(Thread.isMainThread, "\(#function) must be called from the main thread")

        guard let blog = try? Blog.lookup(withID: blogID, in: coreDataStack.mainContext),
              ReachabilityUtils.isInternetReachable() else {
            return
        }

        service.syncBlog(blog) { [weak self] in
            guard let self else {
                return
            }

            // re-fetch the blog after sync completes to check if the sharing limit for the blog has been removed.
            self.sharingLimit = self.coreDataStack.performQuery { context in
                guard let blog = try? Blog.lookup(withID: self.blogID, in: context) else {
                    return nil
                }
                return blog.sharingLimit
            }

        } failure: { error in
            DDLogError("Failed to sync blog after dismissing checkout webview due to error: \(error)")
        }
    }

    /// Convenient model that represents the user's Publicize connections.
    struct Connection {
        let service: PublicizeService.ServiceName
        let account: String
        let keyringID: Int
        let isOn: Bool

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

        static let tableTopPadding: CGFloat = 16.0
        static let minContentHeight: CGFloat = 300.0
        static let defaultBottomInset: CGFloat = 34.0
        static let additionalBottomInset: CGFloat = 16.0

        static let accountCellIdentifier = "AccountCell"
        static let messageCellIdentifier = "MessageCell"

        static let webViewSource = "prepublishing_social_accounts_subscribe"
        static let trackingSource = "pre_publishing"

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

extension PrepublishingSocialAccountsViewController: DrawerPresentable {

    var collapsedHeight: DrawerHeight {
        .intrinsicHeight
    }

    var scrollableView: UIScrollView? {
        tableView
    }
}

private extension PrepublishingAutoSharingModel {
    var enabledConnectionsCount: Int {
        services.flatMap { $0.connections }.filter { $0.enabled }.count
    }
}
