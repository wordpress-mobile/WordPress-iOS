import Foundation
import CoreData
import Gridicons
import SVProgressHUD
import WordPressShared
import WordPressUI

///
///
protocol NotificationsNavigationDataSource: AnyObject {
    func notification(succeeding note: Notification) -> Notification?
    func notification(preceding note: Notification) -> Notification?
}

// MARK: - Renders a given Notification entity, onscreen
//
class NotificationDetailsViewController: UIViewController, NoResultsViewHost {

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
    @IBOutlet var replyTextView: CommentLargeButton!

    /// Embedded Media Downloader
    ///
    fileprivate var mediaDownloader = NotificationMediaDownloader()

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

    /// Used to present CommentDetailViewController when previous/next notification is a Comment.
    ///
    weak var notificationCommentDetailCoordinator: NotificationCommentDetailCoordinator?

    /// Notification being displayed
    ///
    var note: Notification! {
        didSet {
            guard oldValue != note && isViewLoaded else {
                return
            }
            confettiWasShown = false
            router = makeRouter()
            setupTableDelegates()
            refreshInterface()
            markAsReadIfNeeded()
        }
    }

    /// Whether a confetti animation was presented on this notification or not
    ///
    private var confettiWasShown = false

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

    var likesListController: LikesListController?

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
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupMainView()
        setupTableView()
        setupTableViewCells()
        setupTableDelegates()
        setupReplyTextView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectSelectedRowWithAnimation(true)
        refreshInterface()
        markAsReadIfNeeded()
        setupNotificationListeners()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showConfettiIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        tearDownNotificationListeners()
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
        adjustLayoutConstraintsIfNeeded()
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
            DDLogError("Failed dequeueing NoteBlockTableViewCell.")
            return UITableViewCell()
        }

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

        guard let cell = cell as? NoteBlockTableViewCell else {
            return
        }

        setupSeparators(cell, indexPath: indexPath)
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
        next.setImage(.gridicon(.arrowUp), for: .normal)
        next.addTarget(self, action: #selector(nextNotificationWasPressed), for: .touchUpInside)

        let previous = UIButton(type: .custom)
        previous.setImage(.gridicon(.arrowDown), for: .normal)
        previous.addTarget(self, action: #selector(previousNotificationWasPressed), for: .touchUpInside)

        previousNavigationButton = previous
        nextNavigationButton = next

        enableNavigationRightBarButtonItems()
    }

    func setupMainView() {
        view.backgroundColor = .systemBackground
    }

    func setupTableView() {
        tableView.separatorStyle            = .none
        tableView.keyboardDismissMode       = .interactive
        tableView.accessibilityIdentifier   = .notificationDetailsTableAccessibilityId
        tableView.accessibilityLabel        = NSLocalizedString("Notification Details Table", comment: "Notifications Details Accessibility Identifier")
        tableView.backgroundColor           = .systemBackground
    }

    func setupTableViewCells() {
        let cellClassNames: [NoteBlockTableViewCell.Type] = [
            NoteBlockHeaderTableViewCell.self,
            NoteBlockTextTableViewCell.self,
            NoteBlockCommentTableViewCell.self,
            NoteBlockImageTableViewCell.self,
            NoteBlockUserTableViewCell.self,
            NoteBlockButtonTableViewCell.self
        ]

        for cellClass in cellClassNames {
            let classname = cellClass.classNameWithoutNamespaces()
            let nib = UINib(nibName: classname, bundle: Bundle.main)

            tableView.register(nib, forCellReuseIdentifier: cellClass.reuseIdentifier())
        }

        tableView.register(LikeUserTableViewCell.defaultNib,
                           forCellReuseIdentifier: LikeUserTableViewCell.defaultReuseID)

    }

    /// Configure the delegate and data source for the table view based on notification type.
    /// This method may be called several times, especially upon previous/next button click
    /// since notification kind may change.
    func setupTableDelegates() {
        if note.kind == .like || note.kind == .commentLike,
           let likesListController = LikesListController(tableView: tableView, notification: note, delegate: self) {
            tableView.delegate = likesListController
            tableView.dataSource = likesListController
            self.likesListController = likesListController

            // always call refresh to ensure that the controller fetches the data.
            likesListController.refresh()

        } else {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    func setupReplyTextView() {
        let replyTextView = CommentLargeButton()

        replyTextView.placeholder = NSLocalizedString("Write a reply", comment: "Placeholder text for inline compose view")
        replyTextView.accessibilityLabel = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")

        replyTextView.onTap = {
            // TODO: (kean) remove the remaining .comment-related code
            wpAssertionFailure("Notifications have been using NotificationCommentDetailViewController since 2023")
        }

        replyTextView.setContentCompressionResistancePriority(.required, for: .vertical)

        self.replyTextView = replyTextView
    }

    func setupNotificationListeners() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(notificationWasUpdated), name: .NSManagedObjectContextObjectsDidChange, object: note.managedObjectContext)
    }

    func tearDownNotificationListeners() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: note.managedObjectContext)
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
        // Attach the Reply component only if the notification has a comment, and it can be replied to.
        //
        guard let block: FormattableCommentContent = note.contentGroup(ofKind: .comment)?.blockOfKind(.comment) else {
            return false
        }
        return block.action(id: ReplyToCommentAction.actionIdentifier())?.on ?? false
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
        case .image:
            return NoteBlockImageTableViewCell.reuseIdentifier()
        case .user:
            return NoteBlockUserTableViewCell.reuseIdentifier()
        case .button:
            return NoteBlockButtonTableViewCell.reuseIdentifier()
        default:
            assertionFailure("Unmanaged group kind: \(blockGroup.kind)")
            return NoteBlockTextTableViewCell.reuseIdentifier()
        }
    }

    func setupSeparators(_ cell: NoteBlockTableViewCell, indexPath: IndexPath) {
        cell.isBadge = note.isBadge
        cell.isLastRow = (indexPath.row >= note.headerAndBodyContentGroups.count - 1)

        cell.refreshSeparators()
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
        case let cell as NoteBlockImageTableViewCell:
            setupImageCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockTextTableViewCell:
            setupTextCell(cell, blockGroup: blockGroup, at: indexPath)
        case let cell as NoteBlockButtonTableViewCell:
            setupButtonCell(cell, blockGroup: blockGroup)
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

        cell.attributedHeaderTitle = nil
        cell.attributedHeaderDetails = nil

        guard let gravatarBlock: NotificationTextContent = blockGroup.blockOfKind(.image),
            let snippetBlock: NotificationTextContent = blockGroup.blockOfKind(.text) else {
                return
        }

        cell.attributedHeaderTitle = formatter.render(content: gravatarBlock, with: HeaderContentStyles())
        cell.attributedHeaderDetails = formatter.render(content: snippetBlock, with: HeaderDetailsContentStyles())

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

        // Add comment author's name to Reply placeholder.
        let placeholderFormat = NSLocalizedString("Reply to %1$@",
                                                  comment: "Placeholder text for replying to a comment. %1$@ is a placeholder for the comment author's name.")
        replyTextView.placeholder = String(format: placeholderFormat, cell.name ?? String())

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

    func setupImageCell(_ cell: NoteBlockImageTableViewCell, blockGroup: FormattableContentGroup) {
        guard let imageBlock = blockGroup.blocks.first as? NotificationTextContent else {
            assertionFailure("Missing Image Block for Notification [\(note.notificationId)")
            return
        }

        let mediaURL = imageBlock.media.first?.mediaURL
        cell.downloadImage(mediaURL)

        if note.isViewMilestone {
            cell.backgroundImage = UIImage(named: Assets.confettiBackground)
        }
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
        let text: NSAttributedString

        if note.isBadge {
            let isFirstTextGroup = indexPath.row == indexOfFirstContentGroup(ofKind: .text)
            text = formatter.render(content: textBlock, with: BadgeContentStyles(cachingKey: "Badge-\(indexPath)", isTitle: isFirstTextGroup))
            cell.isTitle = isFirstTextGroup
        } else {
            text = formatter.render(content: textBlock, with: RichTextContentStyles(key: "Rich-Text-\(indexPath)"))
        }

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

    func setupButtonCell(_ cell: NoteBlockButtonTableViewCell, blockGroup: FormattableContentGroup) {
        guard let textBlock = blockGroup.blocks.first as? NotificationTextContent else {
            assertionFailure("Missing Text Block for Notification \(note.notificationId)")
            return
        }

        cell.title = textBlock.text

        if let linkRange = textBlock.ranges.map({ $0 as? LinkContentRange }).first,
           let url = linkRange?.url {
            cell.action = { [weak self] in
                guard let `self` = self, self.isViewOnScreen() else {
                    return
                }

                self.displayURL(url)
            }
        }
    }
}

// MARK: - Notification Helpers
//
extension NotificationDetailsViewController {
    @objc func notificationWasUpdated(_ notification: Foundation.Notification) {
        let updated = notification.userInfo?[NSUpdatedObjectsKey]   as? Set<NSManagedObject> ?? Set()
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deleted = notification.userInfo?[NSDeletedObjectsKey]   as? Set<NSManagedObject> ?? Set()

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
        guard let url else {
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

    func displayUserProfile(_ user: LikeUser, from indexPath: IndexPath) {
        let userProfileVC = UserProfileSheetViewController(user: user)
        userProfileVC.blogUrlPreviewedSource = "notif_like_list_user_profile"
        userProfileVC.modalPresentationStyle = .popover
        userProfileVC.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath) ?? view
        userProfileVC.popoverPresentationController?.adaptiveSheetPresentationController.prefersGrabberVisible = true
        userProfileVC.popoverPresentationController?.adaptiveSheetPresentationController.detents = [.medium()]
        present(userProfileVC, animated: true)

        WPAnalytics.track(.userProfileSheetShown, properties: ["source": "like_notification_list"])
    }

}

// MARK: - Helpers
//
private extension NotificationDetailsViewController {

    func contentGroup(for indexPath: IndexPath) -> FormattableContentGroup {
        return note.headerAndBodyContentGroups[indexPath.row]
    }

    func indexOfFirstContentGroup(ofKind kind: FormattableContentGroup.Kind) -> Int? {
        return note.headerAndBodyContentGroups.firstIndex(where: { $0.kind == kind })
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
}

// MARK: - Milestone notifications
//
private extension NotificationDetailsViewController {

    func showConfettiIfNeeded() {
        guard note.isViewMilestone,
              !confettiWasShown,
              let view = UIApplication.shared.mainWindow,
              let frame = navigationController?.view.frame else {
            return
        }
        // This method will remove any existing `ConfettiView` before adding a new one
        // This ensures that when we navigate through notifications, if there is an
        // ongoging animation, it will be removed and replaced by a new one
        ConfettiView.cleanupAndAnimate(on: view, frame: frame) { confettiView in

            // removing this instance when the animation completes, will prevent
            // the animation to suddenly stop if users navigate away from the note
            confettiView.removeFromSuperview()
        }

        confettiWasShown = true
    }
}

// MARK: - Navigation Helpers
//
extension NotificationDetailsViewController {
    @IBAction func previousNotificationWasPressed() {
        guard let previous = dataSource?.notification(preceding: note) else {
            return
        }

        WPAnalytics.track(.notificationsPreviousTapped)
        refreshView(with: previous)
    }

    @IBAction func nextNotificationWasPressed() {
        guard let next = dataSource?.notification(succeeding: note) else {
            return
        }

        WPAnalytics.track(.notificationsNextTapped)
        refreshView(with: next)
    }

    private func refreshView(with note: Notification) {
        onSelectedNoteChange?(note)
        trackDetailsOpened(for: note)

        if note.kind == .comment {
            showCommentDetails(with: note)
            return
        }

        hideNoResults()
        self.note = note
        showConfettiIfNeeded()
    }

    private func showCommentDetails(with note: Notification) {
        guard let commentDetailViewController = notificationCommentDetailCoordinator?.createViewController(with: note) else {
            DDLogError("Notification Details: failed creating Comment Detail view.")
            return
        }

        notificationCommentDetailCoordinator?.onSelectedNoteChange = self.onSelectedNoteChange

        let navigationController = navigationController // important to keep reference
        commentDetailViewController.navigationItem.largeTitleDisplayMode = .never
        navigationController?.popViewController(animated: false)
        navigationController?.pushViewController(commentDetailViewController, animated: false)
    }

    var shouldEnablePreviousButton: Bool {
        return dataSource?.notification(preceding: note) != nil
    }

    var shouldEnableNextButton: Bool {
        return dataSource?.notification(succeeding: note) != nil
    }
}

// MARK: - LikesListController Delegate
//
extension NotificationDetailsViewController: LikesListControllerDelegate {

    func didSelectHeader() {
        displayNotificationSource()
    }

    func didSelectUser(_ user: LikeUser, at indexPath: IndexPath) {
        displayUserProfile(user, from: indexPath)
    }

    func showErrorView(title: String, subtitle: String?) {
        hideNoResults()
        configureAndDisplayNoResults(on: tableView,
                                     title: title,
                                     subtitle: subtitle,
                                     image: "wp-illustration-notifications")
    }

}

// MARK: - Private Properties
//
private extension NotificationDetailsViewController {
    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var actionsService: NotificationActionsService {
        return NotificationActionsService(coreDataStack: ContextManager.shared)
    }

    enum ContentMedia {
        static let richBlockTypes           = Set(arrayLiteral: FormattableContentKind.text, FormattableContentKind.comment)
        static let duration                 = TimeInterval(0.25)
        static let delay                    = TimeInterval(0)
        static let options: UIView.AnimationOptions = [.overrideInheritedDuration, .beginFromCurrentState]
    }

    enum Settings {
        static let numberOfSections         = 1
        static let estimatedRowHeight       = CGFloat(44)
    }

    enum Assets {
        static let confettiBackground       = "notifications-confetti-background"
    }
}

// MARK: - Tracks
extension NotificationDetailsViewController {
    /// Tracks notification details opened
    private func trackDetailsOpened(for note: Notification) {
        let properties = ["notification_type": note.type ?? "unknown"]
        WPAnalytics.track(.openedNotificationDetails, withProperties: properties)
    }
}

// MARK: - Accessibility Id Strings
//
private extension String {
    static let notificationDetailsTableAccessibilityId = "notifications-details-table"
    static let replyTextViewAccessibilityId = "reply-text-view"
}
