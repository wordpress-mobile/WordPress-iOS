import Foundation
import CoreData
import Gridicons
import SVProgressHUD
import WordPressShared


///
///
protocol NotificationsNavigationDataSource: class {
    func notification(succeeding note: Notification) -> Notification?
    func notification(preceding note: Notification) -> Notification?
}


// MARK: - Renders a given Notification entity, onscreen
//
class NotificationDetailsViewController: UIViewController {
    // MARK: - Properties

    let formatter = FormattableContentFormatter()

    /// StackView: Top-Level Entity
    ///
    @IBOutlet var stackView: UIStackView!

    /// TableView
    ///
    @IBOutlet var tableView: UITableView!

    /// Pins the StackView to the top of the view (Relationship: = 0)
    ///
    @IBOutlet var topLayoutConstraint: NSLayoutConstraint!

    /// Pins the StackView to the bottom of the view (Relationship: = 0)
    ///
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!

    /// Pins the StackView to the top of the view (Relationship: >= 0)
    ///
    @IBOutlet var badgeTopLayoutConstraint: NSLayoutConstraint!

    /// Pins the StackView to the bottom of the view (Relationship: >= 0)
    ///
    @IBOutlet var badgeBottomLayoutConstraint: NSLayoutConstraint!

    /// Pins the StackView at the center of the view
    ///
    @IBOutlet var badgeCenterLayoutConstraint: NSLayoutConstraint!

    /// RelpyTextView
    ///
    @IBOutlet var replyTextView: ReplyTextView!

    /// Reply Suggestions
    ///
    @IBOutlet var suggestionsTableView: SuggestionsTableView!

    /// Embedded Media Downloader
    ///
    fileprivate var mediaDownloader = NotificationMediaDownloader()

    /// Keyboard Manager: Aids in the Interactive Dismiss Gesture
    ///
    fileprivate var keyboardManager: KeyboardDismissHelper?

    /// Cached values used for returning the estimated row heights of autosizing cells.
    ///
    fileprivate let estimatedRowHeightsCache = NSCache<AnyObject, AnyObject>()

    /// Previous NavBar Navigation Button
    ///
    var previousNavigationButton: UIButton!

    /// Next NavBar Navigation Button
    ///
    var nextNavigationButton: UIButton!

    /// Arrows Navigation Datasource
    ///
    weak var dataSource: NotificationsNavigationDataSource?

    /// Notification to-be-displayed
    ///
    var note: Notification! {
        didSet {
            guard oldValue != note && isViewLoaded else {
                return
            }

            router = makeRouter()
            refreshInterface()
            markAsReadIfNeeded()
        }
    }

    lazy var coordinator: ContentCoordinator = {
        return DefaultContentCoordinator(controller: self, context: mainContext)
    }()

    lazy var router: NotificationContentRouter = {
        return makeRouter()
    }()

    /// Whenever the user performs a destructive action, the Deletion Request Callback will be called,
    /// and a closure that will effectively perform the deletion action will be passed over.
    /// In turn, the Deletion Action block also expects (yet another) callback as a parameter, to be called
    /// in the eventuallity of a failure.
    ///
    var onDeletionRequestCallback: ((NotificationDeletionRequest) -> Void)?

    /// Closure to be executed whenever the notification that's being currently displayed, changes.
    /// This happens due to Navigation Events (Next / Previous)
    ///
    var onSelectedNoteChange: ((Notification) -> Void)?


    deinit {
        // Failsafe: Manually nuke the tableView dataSource and delegate. Make sure not to force a loadView event!
        guard isViewLoaded else {
            return
        }

        tableView.delegate = nil
        tableView.dataSource = nil
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        restorationClass = type(of: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupMainView()
        setupTableView()
        setupTableViewCells()
        setupReplyTextView()
        setupSuggestionsView()
        setupKeyboardManager()

        Environment.current.appRatingUtility.incrementSignificantEvent(section: "notifications")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectSelectedRowWithAnimation(true)
        keyboardManager?.startListeningToKeyboardNotifications()

        refreshInterface()
        markAsReadIfNeeded()
        setupNotificationListeners()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager?.stopListeningToKeyboardNotifications()
        tearDownNotificationListeners()
        storeNotificationReplyIfNeeded()
        dismissNotice()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.refreshInterfaceIfNeeded()
        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        refreshNavigationBar()
    }

    private func makeRouter() -> NotificationContentRouter {
        return NotificationContentRouter(activity: note, coordinator: coordinator)
    }

    fileprivate func markAsReadIfNeeded() {
        guard !note.read else {
            return
        }

        NotificationSyncMediator()?.markAsRead(note)
    }

    fileprivate func refreshInterfaceIfNeeded() {
        guard isViewLoaded else {
            return
        }

        refreshInterface()
    }

    fileprivate func refreshInterface() {
        formatter.resetCache()
        tableView.reloadData()
        attachReplyViewIfNeeded()
        attachSuggestionsViewIfNeeded()
        adjustLayoutConstraintsIfNeeded()
        refreshNavigationBar()
    }

    fileprivate func refreshNavigationBar() {
        title = note.title

        if splitViewControllerIsHorizontallyCompact {
            enableNavigationRightBarButtonItems()
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }

    fileprivate func enableNavigationRightBarButtonItems() {

        // https://github.com/wordpress-mobile/WordPress-iOS/issues/6662#issue-207316186
        let buttonSize = CGFloat(24)
        let buttonSpacing = CGFloat(12)

        let width = buttonSize + buttonSpacing + buttonSize
        let height = buttonSize
        let buttons = UIStackView(arrangedSubviews: [nextNavigationButton, previousNavigationButton])
        buttons.axis = .horizontal
        buttons.spacing = buttonSpacing
        buttons.frame = CGRect(x: 0, y: 0, width: width, height: height)

        UIView.performWithoutAnimation {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttons)
        }

        previousNavigationButton.isEnabled = shouldEnablePreviousButton
        nextNavigationButton.isEnabled = shouldEnableNextButton

        previousNavigationButton.accessibilityLabel = NSLocalizedString("Previous notification", comment: "Accessibility label for the previous notification button")
        nextNavigationButton.accessibilityLabel = NSLocalizedString("Next notification", comment: "Accessibility label for the next notification button")
    }
}



// MARK: - State Restoration
//
extension NotificationDetailsViewController: UIViewControllerRestoration {
    class func viewController(withRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {
        let context = Environment.current.mainContext
        guard let noteURI = coder.decodeObject(forKey: Restoration.noteIdKey) as? URL,
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: noteURI) else {
                return nil
        }

        let notification = try? context.existingObject(with: objectID)
        guard let restoredNotification = notification as? Notification else {
            return nil
        }

        let storyboard = coder.decodeObject(forKey: UIApplication.stateRestorationViewControllerStoryboardKey) as? UIStoryboard
        guard let vc = storyboard?.instantiateViewController(withIdentifier: Restoration.restorationIdentifier) as? NotificationDetailsViewController else {
            return nil
        }

        vc.note = restoredNotification

        return vc
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(note.objectID.uriRepresentation(), forKey: Restoration.noteIdKey)
    }
}



// MARK: - UITableView Methods
//
extension NotificationDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Settings.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return note.headerAndBodyContentGroups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = contentGroup(for: indexPath)
        let reuseIdentifier = reuseIdentifierForGroup(group)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? NoteBlockTableViewCell else {
            fatalError()
        }

        setupSeparators(cell, indexPath: indexPath)

        setup(cell, withContentGroupAt: indexPath)

        return cell
    }

    func setup(_ cell: NoteBlockTableViewCell, withContentGroupAt indexPath: IndexPath) {
        let group = contentGroup(for: indexPath)
        setup(cell, with: group, at: indexPath)
        downloadAndResizeMedia(at: indexPath, from: group)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        estimatedRowHeightsCache.setObject(cell.frame.height as AnyObject, forKey: indexPath as AnyObject)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = estimatedRowHeightsCache.object(forKey: indexPath as AnyObject) as? CGFloat {
            return height
        }
        return Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = contentGroup(for: indexPath)
        displayContent(group)
    }

    func displayContent(_ contentGroup: FormattableContentGroup) {
        switch contentGroup.kind {
        case .header:
            displayNotificationSource()
        case .user:
            let content: FormattableUserContent? = contentGroup.blockOfKind(.user)
            let url = content?.metaLinksHome
            displayURL(url)
        case .footer:
            let content: FormattableTextContent? = contentGroup.blockOfKind(.text)
            let lastRange = content?.ranges.last as? LinkContentRange
            let url = lastRange?.url
            displayURL(url)
        default:
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }
}



// MARK: - Setup Helpers
//
extension NotificationDetailsViewController {
    func setupNavigationBar() {
        // Don't show the notification title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton

        let next = UIButton(type: .custom)
        next.setImage(Gridicon.iconOfType(.arrowUp), for: .normal)
        next.addTarget(self, action: #selector(nextNotificationWasPressed), for: .touchUpInside)

        let previous = UIButton(type: .custom)
        previous.setImage(Gridicon.iconOfType(.arrowDown), for: .normal)
        previous.addTarget(self, action: #selector(previousNotificationWasPressed), for: .touchUpInside)

        previousNavigationButton = previous
        nextNavigationButton = next

        enableNavigationRightBarButtonItems()
    }

    func setupMainView() {
        view.backgroundColor = .listBackground
    }

    func setupTableView() {
        tableView.separatorStyle            = .none
        tableView.keyboardDismissMode       = .interactive
        tableView.backgroundColor           = .neutral(.shade5)
        tableView.accessibilityIdentifier   = NSLocalizedString("Notification Details Table", comment: "Notifications Details Accessibility Identifier")
        tableView.backgroundColor           = .listBackground
    }

    func setupTableViewCells() {
        let cellClassNames: [NoteBlockTableViewCell.Type] = [
            NoteBlockHeaderTableViewCell.self,
            NoteBlockTextTableViewCell.self,
            NoteBlockActionsTableViewCell.self,
            NoteBlockCommentTableViewCell.self,
            NoteBlockImageTableViewCell.self,
            NoteBlockUserTableViewCell.self
        ]

        for cellClass in cellClassNames {
            let classname = cellClass.classNameWithoutNamespaces()
            let nib = UINib(nibName: classname, bundle: Bundle.main)

            tableView.register(nib, forCellReuseIdentifier: cellClass.reuseIdentifier())
        }
    }

    func setupReplyTextView() {
        let previousReply = NotificationReplyStore.shared.loadReply(for: note.notificationId)
        let replyTextView = ReplyTextView(width: view.frame.width)

        replyTextView.placeholder = NSLocalizedString("Write a reply…", comment: "Placeholder text for inline compose view")
        replyTextView.replyText = NSLocalizedString("Reply", comment: "Verb. A button title. Reply to a comment.").localizedUppercase
        replyTextView.text = previousReply
        replyTextView.accessibilityIdentifier = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
        replyTextView.delegate = self
        replyTextView.onReply = { [weak self] content in
            let group = self?.note.contentGroup(ofKind: .comment)
            guard let block: FormattableCommentContent = group?.blockOfKind(.comment) else {
                return
            }
            self?.replyCommentWithBlock(block, content: content)
        }

        replyTextView.setContentCompressionResistancePriority(.required, for: .vertical)

        self.replyTextView = replyTextView
    }

    func setupSuggestionsView() {
        suggestionsTableView = SuggestionsTableView()
        suggestionsTableView.siteID = note.metaSiteID
        suggestionsTableView.suggestionsDelegate = self
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupKeyboardManager() {
        precondition(replyTextView != nil)
        precondition(bottomLayoutConstraint != nil)

        keyboardManager = KeyboardDismissHelper(parentView: view,
                                                scrollView: tableView,
                                                dismissableControl: replyTextView,
                                                bottomLayoutConstraint: bottomLayoutConstraint)
    }

    func setupNotificationListeners() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(notificationWasUpdated),
                       name: .NSManagedObjectContextObjectsDidChange,
                       object: note.managedObjectContext)
    }

    func tearDownNotificationListeners() {
        let nc = NotificationCenter.default
        nc.removeObserver(self,
                          name: .NSManagedObjectContextObjectsDidChange,
                          object: note.managedObjectContext)
    }
}



// MARK: - Reply View Helpers
//
extension NotificationDetailsViewController {
    func attachReplyViewIfNeeded() {
        guard shouldAttachReplyView else {
            replyTextView.removeFromSuperview()
            return
        }

        stackView.addArrangedSubview(replyTextView)
    }

    var shouldAttachReplyView: Bool {
        // Attach the Reply component only if the noficiation has a comment, and it can be replied-to
        //
        guard let block: FormattableCommentContent = note.contentGroup(ofKind: .comment)?.blockOfKind(.comment) else {
            return false
        }
        return block.action(id: ReplyToCommentAction.actionIdentifier())?.on ?? false
    }

    func storeNotificationReplyIfNeeded() {
        guard let reply = replyTextView?.text, let notificationId = note?.notificationId, !reply.isEmpty else {
            return
        }

        NotificationReplyStore.shared.store(reply: reply, for: notificationId)
    }
}



// MARK: - Suggestions View Helpers
//
private extension NotificationDetailsViewController {
    func attachSuggestionsViewIfNeeded() {
        guard shouldAttachSuggestionsView else {
            suggestionsTableView.removeFromSuperview()
            return
        }

        view.addSubview(suggestionsTableView)

        NSLayoutConstraint.activate([
            suggestionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTableView.topAnchor.constraint(equalTo: view.topAnchor),
            suggestionsTableView.bottomAnchor.constraint(equalTo: replyTextView.topAnchor)
            ])
    }

    var shouldAttachSuggestionsView: Bool {
        guard let siteID = note.metaSiteID else {
            return false
        }

        let suggestionsService = SuggestionService()
        return shouldAttachReplyView && suggestionsService.shouldShowSuggestions(forSiteID: siteID)
    }
}



// MARK: - Layout Helpers
//
private extension NotificationDetailsViewController {
    func adjustLayoutConstraintsIfNeeded() {
        // Badge Notifications:
        //  -   Should be vertically centered
        //  -   Don't need cell separators
        //  -   Should have Vertical Scroll enabled only if the Table Content falls off the screen.
        //
        let requiresVerticalAlignment = note.isBadge

        topLayoutConstraint.isActive = !requiresVerticalAlignment
        bottomLayoutConstraint.isActive = !requiresVerticalAlignment

        badgeTopLayoutConstraint.isActive = requiresVerticalAlignment
        badgeBottomLayoutConstraint.isActive = requiresVerticalAlignment
        badgeCenterLayoutConstraint.isActive = requiresVerticalAlignment

        if requiresVerticalAlignment {
            tableView.isScrollEnabled = tableView.intrinsicContentSize.height > view.bounds.height
        } else {
            tableView.isScrollEnabled = true
        }
    }

    func reuseIdentifierForGroup(_ blockGroup: FormattableContentGroup) -> String {
        switch blockGroup.kind {
        case .header:
            return NoteBlockHeaderTableViewCell.reuseIdentifier()
        case .footer:
            return NoteBlockTextTableViewCell.reuseIdentifier()
        case .subject:
            fallthrough
        case .text:
            return NoteBlockTextTableViewCell.reuseIdentifier()
        case .comment:
            return NoteBlockCommentTableViewCell.reuseIdentifier()
        case .actions:
            return NoteBlockActionsTableViewCell.reuseIdentifier()
        case .image:
            return NoteBlockImageTableViewCell.reuseIdentifier()
        case .user:
            return NoteBlockUserTableViewCell.reuseIdentifier()
        default:
            assertionFailure("Unmanaged group kind: \(blockGroup.kind)")
            return NoteBlockTextTableViewCell.reuseIdentifier()
        }
    }

    func setupSeparators(_ cell: NoteBlockTableViewCell, indexPath: IndexPath) {
        cell.isBadge = note.isBadge
        cell.isLastRow = (indexPath.row >= note.headerAndBodyContentGroups.count - 1)
    }
}



// MARK: - UITableViewCell Subclass Setup
//
private extension NotificationDetailsViewController {
    func setup(_ cell: NoteBlockTableViewCell, with blockGroup: FormattableContentGroup, at indexPath: IndexPath) {
        switch cell {
        case let cell as NoteBlockHeaderTableViewCell:
            setupHeaderCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockTextTableViewCell where blockGroup is FooterContentGroup:
            setupFooterCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockUserTableViewCell:
            setupUserCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockCommentTableViewCell:
            setupCommentCell(cell, blockGroup: blockGroup, at: indexPath)
        case let cell as NoteBlockActionsTableViewCell:
            setupActionsCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockImageTableViewCell:
            setupImageCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockTextTableViewCell:
            setupTextCell(cell, blockGroup: blockGroup, at: indexPath)
        default:
            assertionFailure("NotificationDetails: Please, add support for \(cell)")
        }
    }

    func setupHeaderCell(_ cell: NoteBlockHeaderTableViewCell, blockGroup: FormattableContentGroup) {
        // Note:
        // We're using a UITableViewCell as a Header, instead of UITableViewHeaderFooterView, because:
        // -   UITableViewCell automatically handles highlight / unhighlight for us
        // -   UITableViewCell's taps don't require a Gestures Recognizer. No big deal, but less code!
        //

        let snippetBlock: NotificationTextContent? = blockGroup.blockOfKind(.text)
        cell.headerDetails = snippetBlock?.text
        cell.attributedHeaderTitle = nil

        guard let gravatarBlock: NotificationTextContent = blockGroup.blockOfKind(.image) else {
            return
        }

        cell.attributedHeaderTitle = formatter.render(content: gravatarBlock, with: HeaderContentStyles())
        // Download the Gravatar
        let mediaURL = gravatarBlock.media.first?.mediaURL
        cell.downloadAuthorAvatar(with: mediaURL)
    }

    func setupFooterCell(_ cell: NoteBlockTextTableViewCell, blockGroup: FormattableContentGroup) {
        guard let textBlock = blockGroup.blocks.first else {
            assertionFailure("Missing Text Block for Notification [\(note.notificationId)")
            return
        }

        cell.attributedText = formatter.render(content: textBlock, with: FooterContentStyles())
        cell.isTextViewSelectable = false
        cell.isTextViewClickable = false
    }

    func setupUserCell(_ cell: NoteBlockUserTableViewCell, blockGroup: FormattableContentGroup) {
        guard let userBlock = blockGroup.blocks.first as? FormattableUserContent else {
            assertionFailure("Missing User Block for Notification [\(note.notificationId)]")
            return
        }

        let hasHomeURL = userBlock.metaLinksHome != nil
        let hasHomeTitle = userBlock.metaTitlesHome?.isEmpty == false

        cell.accessoryType = hasHomeURL ? .disclosureIndicator : .none
        cell.name = userBlock.text
        cell.blogTitle = hasHomeTitle ? userBlock.metaTitlesHome : userBlock.metaLinksHome?.host
        cell.isFollowEnabled = userBlock.isActionEnabled(id: FollowAction.actionIdentifier())
        cell.isFollowOn = userBlock.isActionOn(id: FollowAction.actionIdentifier())

        cell.onFollowClick = { [weak self] in
            self?.followSiteWithBlock(userBlock)
        }

        cell.onUnfollowClick = { [weak self] in
            self?.unfollowSiteWithBlock(userBlock)
        }

        // Download the Gravatar
        let mediaURL = userBlock.media.first?.mediaURL
        cell.downloadGravatarWithURL(mediaURL)
    }

    func setupCommentCell(_ cell: NoteBlockCommentTableViewCell, blockGroup: FormattableContentGroup, at indexPath: IndexPath) {
        // Note:
        // The main reason why it's a very good idea *not* to reuse NoteBlockHeaderTableViewCell, just to display the
        // gravatar, is because we're implementing a custom behavior whenever the user approves/ unapproves the comment.
        //
        //  -   Font colors are updated.
        //  -   A left separator is displayed.
        //
        guard let commentBlock: FormattableCommentContent = blockGroup.blockOfKind(.comment) else {
            assertionFailure("Missing Comment Block for Notification [\(note.notificationId)]")
            return
        }

        guard let userBlock: FormattableUserContent = blockGroup.blockOfKind(.user) else {
            assertionFailure("Missing User Block for Notification [\(note.notificationId)]")
            return
        }

        // Merge the Attachments with their ranges: [NSRange: UIImage]
        let mediaMap = mediaDownloader.imagesForUrls(commentBlock.imageUrls)
        let mediaRanges = commentBlock.buildRangesToImagesMap(mediaMap)

        let styles = RichTextContentStyles(key: "RichText-\(indexPath)")
        let text = formatter.render(content: commentBlock, with: styles).stringByEmbeddingImageAttachments(mediaRanges)

        // Setup: Properties
        cell.name                   = userBlock.text
        cell.timestamp              = (note.timestampAsDate as NSDate).mediumString()
        cell.site                   = userBlock.metaTitlesHome ?? userBlock.metaLinksHome?.host
        cell.attributedCommentText  = text.trimNewlines()
        cell.isApproved             = commentBlock.isCommentApproved

        // Setup: Callbacks
        cell.onUserClick = { [weak self] in
            guard let homeURL = userBlock.metaLinksHome else {
                return
            }

            self?.displayURL(homeURL)
        }

        cell.onUrlClick = { [weak self] url in
            self?.displayURL(url as URL)
        }

        cell.onAttachmentClick = { [weak self] attachment in
            guard let image = attachment.image else {
                return
            }
            self?.router.routeTo(image)
        }

        cell.onTimeStampLongPress = { [weak self] in
            guard let urlString = self?.note.url,
            let url = URL(string: urlString) else {
                return
            }
            UIAlertController.presentAlertAndCopyCommentURLToClipboard(url: url)
        }

        // Download the Gravatar
        let mediaURL = userBlock.media.first?.mediaURL
        cell.downloadGravatarWithURL(mediaURL)
    }

    func setupActionsCell(_ cell: NoteBlockActionsTableViewCell, blockGroup: FormattableContentGroup) {
        guard let commentBlock: FormattableCommentContent = blockGroup.blockOfKind(.comment) else {
            assertionFailure("Missing Comment Block for Notification \(note.notificationId)")
            return
        }

        // Setup: Properties
        // Note: Approve Action is actually a synonym for 'Edit' (Based on Calypso's basecode)
        //
        cell.isReplyEnabled     = UIDevice.isPad() && commentBlock.isActionOn(id: ReplyToCommentAction.actionIdentifier())
        cell.isLikeEnabled      = commentBlock.isActionEnabled(id: LikeCommentAction.actionIdentifier())
        cell.isApproveEnabled   = commentBlock.isActionEnabled(id: ApproveCommentAction.actionIdentifier())
        cell.isTrashEnabled     = commentBlock.isActionEnabled(id: TrashCommentAction.actionIdentifier())
        cell.isSpamEnabled      = commentBlock.isActionEnabled(id: MarkAsSpamAction.actionIdentifier())
        cell.isEditEnabled      = commentBlock.isActionOn(id: ApproveCommentAction.actionIdentifier())
        cell.isLikeOn           = commentBlock.isActionOn(id: LikeCommentAction.actionIdentifier())
        cell.isApproveOn        = commentBlock.isActionOn(id: ApproveCommentAction.actionIdentifier())

        // Setup: Callbacks
        cell.onReplyClick = { [weak self] _ in
            self?.focusOnReplyTextViewWithBlock(commentBlock)
            WPAppAnalytics.track(.notificationsCommentRepliedTo)
        }

        cell.onLikeClick = { [weak self] _ in
            self?.likeCommentWithBlock(commentBlock)
        }

        cell.onUnlikeClick = { [weak self] _ in
            self?.unlikeCommentWithBlock(commentBlock)
        }

        cell.onApproveClick = { [weak self] _ in
            self?.approveCommentWithBlock(commentBlock)
        }

        cell.onUnapproveClick = { [weak self] _ in
            self?.unapproveCommentWithBlock(commentBlock)
        }

        cell.onTrashClick = { [weak self] _ in
            self?.trashCommentWithBlock(commentBlock)
        }

        cell.onSpamClick = { [weak self] _ in
            self?.spamCommentWithBlock(commentBlock)
        }

        cell.onEditClick = { [weak self] _ in
            self?.displayCommentEditorWithBlock(commentBlock)
        }
    }

    func setupImageCell(_ cell: NoteBlockImageTableViewCell, blockGroup: FormattableContentGroup) {
        guard let imageBlock = blockGroup.blocks.first as? NotificationTextContent else {
            assertionFailure("Missing Image Block for Notification [\(note.notificationId)")
            return
        }

        let mediaURL = imageBlock.media.first?.mediaURL
        cell.downloadImage(mediaURL)
    }

    func setupTextCell(_ cell: NoteBlockTextTableViewCell, blockGroup: FormattableContentGroup, at indexPath: IndexPath) {
        guard let textBlock = blockGroup.blocks.first as? NotificationTextContent else {
            assertionFailure("Missing Text Block for Notification \(note.notificationId)")
            return
        }

        // Merge the Attachments with their ranges: [NSRange: UIImage]
        let mediaMap = mediaDownloader.imagesForUrls(textBlock.imageUrls)
        let mediaRanges = textBlock.buildRangesToImagesMap(mediaMap)

        // Load the attributedText
        let text = note.isBadge ?
            formatter.render(content: textBlock, with: BadgeContentStyles(cachingKey: "Badge-\(indexPath)")) :
            formatter.render(content: textBlock, with: RichTextContentStyles(key: "Rich-Text-\(indexPath)"))

        // Setup: Properties
        cell.attributedText = text.stringByEmbeddingImageAttachments(mediaRanges)

        // Setup: Callbacks
        cell.onUrlClick = { [weak self] url in
            guard let `self` = self, self.isViewOnScreen() else {
                return
            }

            self.displayURL(url)
        }
    }
}



// MARK: - Notification Helpers
//
extension NotificationDetailsViewController {
    @objc func notificationWasUpdated(_ notification: Foundation.Notification) {
        let updated   = notification.userInfo?[NSUpdatedObjectsKey]   as? Set<NSManagedObject> ?? Set()
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deleted   = notification.userInfo?[NSDeletedObjectsKey]   as? Set<NSManagedObject> ?? Set()

        // Reload the table, if *our* notification got updated + Mark as Read since it's already onscreen!
        if updated.contains(note) || refreshed.contains(note) {
            refreshInterface()
            // We're being called when the managed context is saved
            // Let's defer any data changes or we will try to save within a save
            // and crash 💥
            DispatchQueue.main.async { [weak self] in
                self?.markAsReadIfNeeded()
            }
        } else {
            // Otherwise, refresh the navigation bar as the notes list might have changed
            refreshNavigationBar()
        }

        // Dismiss this ViewController if *our* notification... just got deleted
        if deleted.contains(note) {
            _ = navigationController?.popToRootViewController(animated: true)
        }
    }
}



// MARK: - Resources
//
private extension NotificationDetailsViewController {
    func displayURL(_ url: URL?) {
        guard let url = url else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }
        router.routeTo(url)
    }

    func displayNotificationSource() {
        do {
            try router.routeToNotificationSource()
        } catch {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }
}



// MARK: - Helpers
//
private extension NotificationDetailsViewController {

    func contentGroup(for indexPath: IndexPath) -> FormattableContentGroup {
        return note.headerAndBodyContentGroups[indexPath.row]
    }
}



// MARK: - Media Download Helpers
//
private extension NotificationDetailsViewController {

    /// Extracts all of the imageUrl's for the blocks of the specified kinds
    ///
    func imageUrls(from content: [FormattableContent], inKindSet kindSet: Set<FormattableContentKind>) -> Set<URL> {
        let filtered = content.filter { kindSet.contains($0.kind) }
        let imageUrls = filtered.compactMap { ($0 as? NotificationTextContent)?.imageUrls }.flatMap { $0 }
        return Set(imageUrls)
    }

    func downloadAndResizeMedia(at indexPath: IndexPath, from contentGroup: FormattableContentGroup) {
        //  Notes:
        //  -   We'll *only* download Media for Text and Comment Blocks
        //  -   Plus, we'll also resize the downloaded media cache *if needed*. This is meant to adjust images to
        //      better fit onscreen, whenever the device orientation changes (and in turn, the maxMediaEmbedWidth changes too).
        //
        let urls = imageUrls(from: contentGroup.blocks, inKindSet: ContentMedia.richBlockTypes)

        let completion = {
            // Workaround: Performing the reload call, multiple times, without the .BeginFromCurrentState might
            // lead to a state in which the cell remains not visible.
            //
            UIView.animate(withDuration: ContentMedia.duration, delay: ContentMedia.delay, options: ContentMedia.options, animations: { [weak self] in
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
                })
        }

        mediaDownloader.downloadMedia(urls: urls, maximumWidth: maxMediaEmbedWidth, completion: completion)
        mediaDownloader.resizeMediaWithIncorrectSize(maxMediaEmbedWidth, completion: completion)
    }

    var maxMediaEmbedWidth: CGFloat {
        let readableWidth = ceil(tableView.readableContentGuide.layoutFrame.size.width)
        return readableWidth > 0 ? readableWidth : view.frame.size.width
    }
}



// MARK: - Action Handlers
//
private extension NotificationDetailsViewController {
    func followSiteWithBlock(_ block: FormattableUserContent) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        actionsService.followSiteWithBlock(block)
        WPAppAnalytics.track(.notificationsSiteFollowAction, withBlogID: block.metaSiteID)
    }

    func unfollowSiteWithBlock(_ block: FormattableUserContent) {
        actionsService.unfollowSiteWithBlock(block)
        WPAppAnalytics.track(.notificationsSiteUnfollowAction, withBlogID: block.metaSiteID)
    }

    func likeCommentWithBlock(_ block: FormattableCommentContent) {
        guard let likeAction = block.action(id: LikeCommentAction.actionIdentifier()) else {
            return
        }
        let actionContext = ActionContext(block: block)
        likeAction.execute(context: actionContext)
        WPAppAnalytics.track(.notificationsCommentLiked, withBlogID: block.metaSiteID)
    }

    func unlikeCommentWithBlock(_ block: FormattableCommentContent) {
        guard let likeAction = block.action(id: LikeCommentAction.actionIdentifier()) else {
            return
        }
        let actionContext = ActionContext(block: block)
        likeAction.execute(context: actionContext)
        WPAppAnalytics.track(.notificationsCommentUnliked, withBlogID: block.metaSiteID)
    }

    func approveCommentWithBlock(_ block: FormattableCommentContent) {
        guard let approveAction = block.action(id: ApproveCommentAction.actionIdentifier()) else {
            return
        }

        let actionContext = ActionContext(block: block)
        approveAction.execute(context: actionContext)
        WPAppAnalytics.track(.notificationsCommentApproved, withBlogID: block.metaSiteID)
    }

    func unapproveCommentWithBlock(_ block: FormattableCommentContent) {
        guard let approveAction = block.action(id: ApproveCommentAction.actionIdentifier()) else {
            return
        }

        let actionContext = ActionContext(block: block)
        approveAction.execute(context: actionContext)
        WPAppAnalytics.track(.notificationsCommentUnapproved, withBlogID: block.metaSiteID)
    }

    func spamCommentWithBlock(_ block: FormattableCommentContent) {
        guard onDeletionRequestCallback != nil else {
            // callback probably missing due to state restoration. at least by
            // not crashing the user can tap the back button and try again
            return
        }

        guard let spamAction = block.action(id: MarkAsSpamAction.actionIdentifier()) else {
            return
        }

        let actionContext = ActionContext(block: block, completion: { [weak self] (request, success) in
            WPAppAnalytics.track(.notificationsCommentFlaggedAsSpam, withBlogID: block.metaSiteID)
            guard let request = request else {
                return
            }
            self?.onDeletionRequestCallback?(request)
        })

        spamAction.execute(context: actionContext)

        // We're thru
        _ = navigationController?.popToRootViewController(animated: true)
    }

    func trashCommentWithBlock(_ block: FormattableCommentContent) {
        guard onDeletionRequestCallback != nil else {
            // callback probably missing due to state restoration. at least by
            // not crashing the user can tap the back button and try again
            return
        }

        guard let trashAction = block.action(id: TrashCommentAction.actionIdentifier()) else {
            return
        }

        let actionContext = ActionContext(block: block, completion: { [weak self] (request, success) in
            WPAppAnalytics.track(.notificationsCommentTrashed, withBlogID: block.metaSiteID)
            guard let request = request else {
                return
            }
            self?.onDeletionRequestCallback?(request)
        })

        trashAction.execute(context: actionContext)

        // We're thru
        _ = navigationController?.popToRootViewController(animated: true)
    }

    func replyCommentWithBlock(_ block: FormattableCommentContent, content: String) {
        guard let replyAction = block.action(id: ReplyToCommentAction.actionIdentifier()) else {
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        let actionContext = ActionContext(block: block, content: content) { [weak self] (request, success) in
            if success {
                let message = NSLocalizedString("Reply Sent!", comment: "The app successfully sent a comment")
                self?.displayNotice(title: message)
            } else {
                generator.notificationOccurred(.error)
                self?.displayReplyError(with: block, content: content)
            }
        }

        replyAction.execute(context: actionContext)
    }

    func updateCommentWithBlock(_ block: FormattableCommentContent, content: String) {
        guard let editCommentAction = block.action(id: EditCommentAction.actionIdentifier()) else {
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        let actionContext = ActionContext(block: block, content: content) { [weak self] (request, success) in
            guard success == false else {
                return
            }

            generator.notificationOccurred(.error)
            self?.displayCommentUpdateErrorWithBlock(block, content: content)
        }

        editCommentAction.execute(context: actionContext)
    }
}

// MARK: - Replying Comments
//
private extension NotificationDetailsViewController {
    func focusOnReplyTextViewWithBlock(_ content: FormattableContent) {
        let _ = replyTextView.becomeFirstResponder()
    }

    func displayReplyError(with block: FormattableCommentContent, content: String) {
        let message = NSLocalizedString("There has been an unexpected error while sending your reply", comment: "Reply Failure Message")
        displayNotice(title: message)
    }
}



// MARK: - Editing Comments
//
private extension NotificationDetailsViewController {

    func updateComment(with commentContent: FormattableCommentContent, content: String) {
            self.updateCommentWithBlock(commentContent, content: content)
    }

    func displayCommentEditorWithBlock(_ block: FormattableCommentContent) {
        let editViewController = EditCommentViewController.newEdit()
        editViewController?.content = block.text
        editViewController?.onCompletion = { (hasNewContent, newContent) in
            self.dismiss(animated: true, completion: {
                guard hasNewContent else {
                    return
                }
                let newContent = newContent ?? ""
                self.updateComment(with: block, content: newContent)
            })
        }

        let navController = UINavigationController(rootViewController: editViewController!)
        navController.modalPresentationStyle = .formSheet
        navController.modalTransitionStyle = .coverVertical
        navController.navigationBar.isTranslucent = false

        present(navController, animated: true)
    }

    func displayCommentUpdateErrorWithBlock(_ block: FormattableCommentContent, content: String) {
        let message     = NSLocalizedString("There has been an unexpected error while updating your comment",
                                            comment: "Displayed whenever a Comment Update Fails")
        let cancelTitle = NSLocalizedString("Give Up", comment: "Cancel")
        let retryTitle  = NSLocalizedString("Try Again", comment: "Retry")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(cancelTitle) { action in
            block.textOverride = nil
            self.refreshInterface()
        }
        alertController.addDefaultActionWithTitle(retryTitle) { action in
            self.updateComment(with: block, content: content)
        }

        // Note: This viewController might not be visible anymore
        alertController.presentFromRootViewController()
    }
}



// MARK: - UITextViewDelegate
//
extension NotificationDetailsViewController: ReplyTextViewDelegate {
    func textView(_ textView: UITextView, didTypeWord word: String) {
        suggestionsTableView.showSuggestions(forWord: word)
    }
}



// MARK: - UIScrollViewDelegate
//
extension NotificationDetailsViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        keyboardManager?.scrollViewWillBeginDragging(scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        keyboardManager?.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        keyboardManager?.scrollViewWillEndDragging(scrollView, withVelocity: velocity)
    }
}



// MARK: - SuggestionsTableViewDelegate
//
extension NotificationDetailsViewController: SuggestionsTableViewDelegate {
    func suggestionsTableView(_ suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        replyTextView.replaceTextAtCaret(text as NSString?, withText: suggestion)
        suggestionsTableView.showSuggestions(forWord: String())
    }
}



// MARK: - Navigation Helpers
//
extension NotificationDetailsViewController {
    @IBAction func previousNotificationWasPressed() {
        guard let previous = dataSource?.notification(preceding: note) else {
            return
        }

        onSelectedNoteChange?(previous)
        note = previous
    }

    @IBAction func nextNotificationWasPressed() {
        guard let next = dataSource?.notification(succeeding: note) else {
            return
        }

        onSelectedNoteChange?(next)
        note = next
    }

    var shouldEnablePreviousButton: Bool {
        return dataSource?.notification(preceding: note) != nil
    }

    var shouldEnableNextButton: Bool {
        return dataSource?.notification(succeeding: note) != nil
    }
}



// MARK: - Private Properties
//
private extension NotificationDetailsViewController {
    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var actionsService: NotificationActionsService {
        return NotificationActionsService(managedObjectContext: mainContext)
    }

    enum DisplayError: Error {
        case missingParameter
        case unsupportedFeature
        case unsupportedType
    }

    enum ContentMedia {
        static let richBlockTypes           = Set(arrayLiteral: FormattableContentKind.text, FormattableContentKind.comment)
        static let duration                 = TimeInterval(0.25)
        static let delay                    = TimeInterval(0)
        static let options: UIView.AnimationOptions = [.overrideInheritedDuration, .beginFromCurrentState]
    }

    enum Restoration {
        static let noteIdKey                = Notification.classNameWithoutNamespaces()
        static let restorationIdentifier    = NotificationDetailsViewController.classNameWithoutNamespaces()
    }

    enum Settings {
        static let numberOfSections         = 1
        static let estimatedRowHeight       = CGFloat(44)
        static let expirationFiveMinutes    = TimeInterval(60 * 5)
    }
}
