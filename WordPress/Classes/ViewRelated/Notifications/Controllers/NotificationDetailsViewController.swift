import Foundation
import CoreData
import Simperium
import SVProgressHUD
import WordPressShared



/// Renders a given Notification entity, onscreen. Whenever the Notification is remotely updated,
/// this class will automatically take care of refreshing the UI for you, thanks to Simperium's Awesomeness
///
class NotificationDetailsViewController: UIViewController
{
    // MARK: - Properties

    /// StackView: Top-Level Entity
    ///
    @IBOutlet var stackView: UIStackView!

    /// TableView
    ///
    @IBOutlet var tableView: UITableView!

    /// Pins the StackView to the top of the view
    ///
    @IBOutlet var topLayoutConstraint: NSLayoutConstraint!

    /// Pins the StackView at the center of the view
    ///
    @IBOutlet var centerLayoutConstraint: NSLayoutConstraint!

    /// Pins the StackView to the bottom of the view
    ///
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!

    /// RelpyTextView
    ///
    @IBOutlet var replyTextView: ReplyTextView!

    /// Reply Suggestions
    ///
    @IBOutlet var suggestionsTableView: SuggestionsTableView!

    /// Embedded Media Downloader
    ///
    private var mediaDownloader = NotificationMediaDownloader()

    /// Keyboard Manager: Aids in the Interactive Dismiss Gesture
    ///
    private var keyboardManager: KeyboardDismissHelper!

    /// Notification to-be-displayed
    ///
    private var note: Notification!

    /// Arranged collection of groups to render
    ///
    private var blockGroups = [NotificationBlockGroup]()

    /// Whenever the user performs a destructive action, the Deletion Request Callback will be called,
    /// and a closure that will effectively perform the deletion action will be passed over.
    /// In turn, the Deletion Action block also expects (yet another) callback as a parameter, to be called
    /// in the eventuallity of a failure.
    ///
    var onDeletionRequestCallback: NotificationDeletion.Request?


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        // Failsafe: Manually nuke the tableView dataSource and delegate. Make sure not to force a loadView event!
        guard isViewLoaded() else {
            return
        }

        tableView.delegate = nil
        tableView.dataSource = nil
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        restorationClass = self.dynamicType
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
        setupNotificationListeners()

        AppRatingUtility.incrementSignificantEventForSection("notifications")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectSelectedRowWithAnimation(true)
        keyboardManager.startListeningToKeyboardNotifications()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager.stopListeningToKeyboardNotifications()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustLayoutConstraintsIfNeeded()
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
        adjustLayoutConstraintsIfNeeded()
    }


    /// Renders the details view, for any given notification
    ///
    /// -   Parameter notification: The Notification to display.
    ///
    func setupWithNotification(notification: Notification) {
        note = notification

        loadViewIfNeeded()
        attachReplyViewIfNeeded()
        attachSuggestionsViewIfNeeded()
        attachEditActionIfNeeded()
        reloadData()
    }

    private func reloadData() {
        // Hide the header, if needed
        var mergedGroups = [NotificationBlockGroup]()

        if let header = note.headerBlockGroup {
            mergedGroups.append(header)
        }

        mergedGroups.appendContentsOf(note.bodyBlockGroups)
        blockGroups = mergedGroups

        // Reload UI
        title = note.title
        tableView.reloadData()
        adjustLayoutConstraintsIfNeeded()
    }
}



// MARK: - State Restoration
//
extension NotificationDetailsViewController: UIViewControllerRestoration
{
    class func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        let context = ContextManager.sharedInstance().mainContext
        guard let noteURI = coder.decodeObjectForKey(Restoration.noteIdKey) as? NSURL,
            let objectID = context.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(noteURI) else
        {
            return nil
        }

        let notification = try? context.existingObjectWithID(objectID)
        guard let restoredNotification = notification as? Notification else {
            return nil
        }

        let storyboard = coder.decodeObjectForKey(UIStateRestorationViewControllerStoryboardKey) as? UIStoryboard
        guard let vc = storyboard?.instantiateViewControllerWithIdentifier(Restoration.restorationIdentifier) as? NotificationDetailsViewController else {
            return nil
        }

        vc.setupWithNotification(restoredNotification)

        return vc
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeObject(note.objectID.URIRepresentation(), forKey: Restoration.noteIdKey)
    }
}



// MARK: - UITableView Methods
//
extension NotificationDetailsViewController: UITableViewDelegate, UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Settings.numberOfSections
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockGroups.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let blockGroup = blockGroupForIndexPath(indexPath)
        let layoutIdentifier = layoutIdentifierForGroup(blockGroup)

        guard let tableViewCell = tableView.dequeueReusableCellWithIdentifier(layoutIdentifier) as? NoteBlockTableViewCell else {
            fatalError()
        }

        downloadAndResizeMedia(indexPath, blockGroup: blockGroup)
        setupCell(tableViewCell, blockGroup: blockGroup)

        return tableViewCell.layoutHeightWithWidth(tableView.bounds.width)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let blockGroup = blockGroupForIndexPath(indexPath)
        let reuseIdentifier = reuseIdentifierForGroup(blockGroup)
        guard let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? NoteBlockTableViewCell else {
            fatalError()
        }

        setupSeparators(cell, indexPath: indexPath)
        setupCell(cell, blockGroup: blockGroup)

        return cell
    }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let group = blockGroupForIndexPath(indexPath)

        switch group.kind {
        case .Header:
            displayNotificationSource()
        case .User:
            let targetURL = group.blockOfKind(.User)?.metaLinksHome
            displayURL(targetURL)
        case .Footer:
            // By convention, the last range is the one that always contains the targetURL
            let targetURL = group.blockOfKind(.Text)?.ranges.last?.url
            displayURL(targetURL)
        default:
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }
}



// MARK: - Setup Helpers
//
extension NotificationDetailsViewController
{
    func setupNavigationBar() {
        // Don't show the notification title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(),
                                                           style: .Plain,
                                                           target: nil,
                                                           action: nil)
    }

    func setupMainView() {
        view.backgroundColor = WPStyleGuide.itsEverywhereGrey()
    }

    func setupTableView() {
        tableView.separatorStyle            = .None
        tableView.keyboardDismissMode       = .Interactive
        tableView.backgroundColor           = WPStyleGuide.greyLighten30()
        tableView.accessibilityIdentifier   = NSLocalizedString("Notification Details Table", comment: "Notifications Details Accessibility Identifier")
        tableView.backgroundColor           = WPStyleGuide.itsEverywhereGrey()
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
            let nib = UINib(nibName: classname, bundle: NSBundle.mainBundle())

            tableView.registerNib(nib, forCellReuseIdentifier: cellClass.reuseIdentifier())
            tableView.registerNib(nib, forCellReuseIdentifier: cellClass.layoutIdentifier())
        }
    }

    func setupReplyTextView() {
        let replyTextView = ReplyTextView(width: view.frame.width)
        replyTextView.placeholder = NSLocalizedString("Write a reply…", comment: "Placeholder text for inline compose view")
        replyTextView.replyText = NSLocalizedString("Reply", comment: "").uppercaseString
        replyTextView.accessibilityIdentifier = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
        replyTextView.delegate = self
        replyTextView.onReply = { [weak self] content in
            guard let block = self?.note.blockGroupOfKind(.Comment)?.blockOfKind(.Comment) else {
                return
            }
            self?.replyCommentWithBlock(block, content: content)
        }

        replyTextView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Vertical)

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
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self,
                       selector: #selector(notificationWasUpdated),
                       name: NSManagedObjectContextObjectsDidChangeNotification,
                       object: note.managedObjectContext)
    }
}



// MARK: - Reply View Helpers
//
extension NotificationDetailsViewController
{
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
        guard let block = note.blockGroupOfKind(.Comment)?.blockOfKind(.Comment) else {
            return false
        }

        return block.isActionOn(.Reply) && !WPDeviceIdentification.isiPad()
    }
}



// MARK: - Suggestions View Helpers
//
private extension NotificationDetailsViewController
{
    func attachSuggestionsViewIfNeeded() {
        guard shouldAttachSuggestionsView else {
            suggestionsTableView.removeFromSuperview()
            return
        }

        view.addSubview(suggestionsTableView)

        NSLayoutConstraint.activateConstraints([
            suggestionsTableView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            suggestionsTableView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            suggestionsTableView.bottomAnchor.constraintEqualToAnchor(replyTextView.topAnchor)
        ])
    }

    var shouldAttachSuggestionsView: Bool {
        guard let siteID = note.metaSiteID else {
            return false
        }

        let suggestionsService = SuggestionService()
        return shouldAttachReplyView && suggestionsService.shouldShowSuggestionsForSiteID(siteID)
    }
}


// MARK: - Edition Helpers
//
private extension NotificationDetailsViewController
{
    func attachEditActionIfNeeded() {
        guard shouldAttachEditAction else {
            return
        }

        let title = NSLocalizedString("Edit", comment: "Verb, start editing")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: title,
                                                            style: .Plain,
                                                            target: self,
                                                            action: #selector(editButtonWasPressed))
    }

    var shouldAttachEditAction: Bool {
        // Note: Approve Action is actually a synonym for 'Edition' (Based on Calypso's basecode)
        let block = note.blockGroupOfKind(.Comment)?.blockOfKind(.Comment)
        return block?.isActionOn(.Approve) ?? false
    }

    @objc @IBAction func editButtonWasPressed() {
        // Note: Approve Action is actually a synonym for 'Edition' (Based on Calypso's basecode)
        guard let block = note.blockGroupOfKind(.Comment)?.blockOfKind(.Comment) where block.isActionOn(.Approve) else {
            return
        }

        displayCommentEditorWithBlock(block)
    }
}



// MARK: - Layout Helpers
//
private extension NotificationDetailsViewController
{
    func adjustLayoutConstraintsIfNeeded() {
        // Badge Notifications should be centered, and display no cell separators
        let shouldCenterVertically = note.isBadge

        topLayoutConstraint.active = !shouldCenterVertically
        bottomLayoutConstraint.active = !shouldCenterVertically
        centerLayoutConstraint.active = shouldCenterVertically

        // Lock Scrolling for Badge Notifications
        tableView.scrollEnabled = !shouldCenterVertically
    }

    func layoutIdentifierForGroup(blockGroup: NotificationBlockGroup) -> String {
        switch blockGroup.kind {
        case .Header:
            return NoteBlockHeaderTableViewCell.layoutIdentifier()
        case .Footer:
            return NoteBlockTextTableViewCell.layoutIdentifier()
        case .Subject:
            fallthrough
        case .Text:
            return NoteBlockTextTableViewCell.layoutIdentifier()
        case .Comment:
            return NoteBlockCommentTableViewCell.layoutIdentifier()
        case .Actions:
            return NoteBlockActionsTableViewCell.layoutIdentifier()
        case .Image:
            return NoteBlockImageTableViewCell.layoutIdentifier()
        case .User:
            return NoteBlockUserTableViewCell.layoutIdentifier()
        }
    }

    func reuseIdentifierForGroup(blockGroup: NotificationBlockGroup) -> String {
        switch blockGroup.kind {
        case .Header:
            return NoteBlockHeaderTableViewCell.reuseIdentifier()
        case .Footer:
            return NoteBlockTextTableViewCell.reuseIdentifier()
        case .Subject:
            fallthrough
        case .Text:
            return NoteBlockTextTableViewCell.reuseIdentifier()
        case .Comment:
            return NoteBlockCommentTableViewCell.reuseIdentifier()
        case .Actions:
            return NoteBlockActionsTableViewCell.reuseIdentifier()
        case .Image:
            return NoteBlockImageTableViewCell.reuseIdentifier()
        case .User:
            return NoteBlockUserTableViewCell.reuseIdentifier()
        }
    }
}



// MARK: - UITableViewCell Subclass Setup
//
private extension NotificationDetailsViewController
{
    func setupCell(cell: NoteBlockTableViewCell, blockGroup: NotificationBlockGroup) {
        // Temporarily force margins for WPTableViewCell hack.
        cell.forceCustomCellMargins = true

        switch cell {
        case let cell as NoteBlockHeaderTableViewCell:
            setupHeaderCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockTextTableViewCell where blockGroup.kind == .Footer:
            setupFooterCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockUserTableViewCell:
            setupUserCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockCommentTableViewCell:
            setupCommentCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockActionsTableViewCell:
            setupActionsCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockImageTableViewCell:
            setupImageCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockTextTableViewCell:
            setupTextCell(cell, blockGroup: blockGroup)
        default:
            assertionFailure("NotificationDetails: Please, add support for \(cell)")
        }
    }

    func setupHeaderCell(cell: NoteBlockHeaderTableViewCell, blockGroup: NotificationBlockGroup) {
        // Note:
        // We're using a UITableViewCell as a Header, instead of UITableViewHeaderFooterView, because:
        // -   UITableViewCell automatically handles highlight / unhighlight for us
        // -   UITableViewCell's taps don't require a Gestures Recognizer. No big deal, but less code!
        //
        let gravatarBlock = blockGroup.blockOfKind(.Image)
        let snippetBlock = blockGroup.blockOfKind(.Text)

        cell.attributedHeaderTitle = gravatarBlock?.attributedHeaderTitleText
        cell.headerDetails = snippetBlock?.text

        // Download the Gravatar (If Needed!)
        guard cell.isLayoutCell() == false else {
            return
        }

        let mediaURL = gravatarBlock?.media.first?.mediaURL
        cell.downloadGravatarWithURL(mediaURL)
    }

    func setupFooterCell(cell: NoteBlockTextTableViewCell, blockGroup: NotificationBlockGroup) {
        guard let textBlock = blockGroup.blocks.first else {
            assertionFailure("Missing Text Block for Notification [\(note.simperiumKey)")
            return
        }

        cell.attributedText = textBlock.attributedFooterText
        cell.isTextViewSelectable = false
        cell.isTextViewClickable = false
    }

    func setupUserCell(cell: NoteBlockUserTableViewCell, blockGroup: NotificationBlockGroup) {
        guard let userBlock = blockGroup.blocks.first else {
            assertionFailure("Missing User Block for Notification [\(note.simperiumKey)]")
            return
        }

        let hasHomeURL = userBlock.metaLinksHome != nil
        let hasHomeTitle = (userBlock.metaTitlesHome?.isEmpty == false) ?? false

        // Setup: Properties
        cell.accessoryType = hasHomeURL ? .DisclosureIndicator : .None
        cell.name = userBlock.text
        cell.blogTitle = hasHomeTitle ? userBlock.metaTitlesHome : userBlock.metaLinksHome?.host
        cell.isFollowEnabled = userBlock.isActionEnabled(.Follow)
        cell.isFollowOn = userBlock.isActionOn(.Follow)

        // Setup: Callbacks
        cell.onFollowClick = { [weak self] in
            self?.followSiteWithBlock(userBlock)
        }

        cell.onUnfollowClick = { [weak self] in
            self?.unfollowSiteWithBlock(userBlock)
        }

        // Download the Gravatar (If Needed!)
        guard cell.isLayoutCell() == false else {
            return
        }

        let mediaURL = userBlock.media.first?.mediaURL
        cell.downloadGravatarWithURL(mediaURL)
    }

    func setupCommentCell(cell: NoteBlockCommentTableViewCell, blockGroup: NotificationBlockGroup) {
        // Note:
        // The main reason why it's a very good idea *not* to reuse NoteBlockHeaderTableViewCell, just to display the
        // gravatar, is because we're implementing a custom behavior whenever the user approves/ unapproves the comment.
        //
        //  -   Font colors are updated.
        //  -   A left separator is displayed.
        //
        guard let commentBlock = blockGroup.blockOfKind(.Comment) else {
            assertionFailure("Missing Comment Block for Notification [\(note.simperiumKey)]")
            return
        }

        guard let userBlock = blockGroup.blockOfKind(.User) else {
            assertionFailure("Missing User Block for Notification [\(note.simperiumKey)]")
            return
        }

        // Merge the Attachments with their ranges: [NSRange: UIImage]
        let mediaMap = mediaDownloader.imagesForUrls(commentBlock.imageUrls)
        let mediaRanges = commentBlock.buildRangesToImagesMap(mediaMap)

        let text = commentBlock.attributedRichText.stringByEmbeddingImageAttachments(mediaRanges)

        // Setup: Properties
        cell.name                   = userBlock.text
        cell.timestamp              = note.timestampAsDate.shortString()
        cell.site                   = userBlock.metaTitlesHome ?? userBlock.metaLinksHome?.host
        cell.attributedCommentText  = text.trimTrailingNewlines()
        cell.isApproved             = commentBlock.isCommentApproved
        cell.isRepliedComment       = note.isRepliedComment

        // Setup: Callbacks
        cell.onDetailsClick = { [weak self] sender in
            guard let homeURL = userBlock.metaLinksHome else {
                return
            }

            self?.displayURL(homeURL)
        }

        cell.onUrlClick = { [weak self] url in
            self?.displayURL(url)
        }

        cell.onAttachmentClick = { [weak self] attachment in
            guard let image = attachment.image else {
                return
            }

            self?.displayFullscreenImage(image)
        }

        // Download the Gravatar (If Needed!)
        guard cell.isLayoutCell() == false else {
            return
        }

        let mediaURL = userBlock.media.first?.mediaURL
        cell.downloadGravatarWithURL(mediaURL)
    }

    func setupActionsCell(cell: NoteBlockActionsTableViewCell, blockGroup: NotificationBlockGroup) {
        guard let commentBlock = blockGroup.blockOfKind(.Comment) else {
            assertionFailure("Missing Comment Block for Notification \(note.simperiumKey)")
            return
        }

        // Setup: Properties
        cell.isReplyEnabled     = WPDeviceIdentification.isiPad() && commentBlock.isActionOn(.Reply)
        cell.isLikeEnabled      = commentBlock.isActionEnabled(.Like)
        cell.isApproveEnabled   = commentBlock.isActionEnabled(.Approve)
        cell.isTrashEnabled     = commentBlock.isActionEnabled(.Trash)
        cell.isSpamEnabled      = commentBlock.isActionEnabled(.Spam)
        cell.isLikeOn           = commentBlock.isActionOn(.Like)
        cell.isApproveOn        = commentBlock.isActionOn(.Approve)

        // Setup: Callbacks
        cell.onReplyClick = { [weak self] _ in
            self?.displayReplyEditorWithBlock(commentBlock)
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
    }

    func setupImageCell(cell: NoteBlockImageTableViewCell, blockGroup: NotificationBlockGroup) {
        guard cell.isLayoutCell() == false else {
            return
        }

        guard let imageBlock = blockGroup.blocks.first else {
            assertionFailure("Missing Image Block for Notification [\(note.simperiumKey)")
            return
        }

        let mediaURL = imageBlock.media.first?.mediaURL
        cell.downloadImageWithURL(mediaURL)
    }

    func setupTextCell(cell: NoteBlockTextTableViewCell, blockGroup: NotificationBlockGroup) {
        guard let textBlock = blockGroup.blocks.first else {
            assertionFailure("Missing Text Block for Notification \(note.simperiumKey)")
            return
        }

        // Merge the Attachments with their ranges: [NSRange: UIImage]
        let mediaMap = mediaDownloader.imagesForUrls(textBlock.imageUrls)
        let mediaRanges = textBlock.buildRangesToImagesMap(mediaMap)

        // Load the attributedText
        let text = note.isBadge ? textBlock.attributedBadgeText : textBlock.attributedRichText

        // Setup: Properties
        cell.attributedText = text.stringByEmbeddingImageAttachments(mediaRanges)

        // Setup: Callbacks
        cell.onUrlClick = { [weak self] url in
            self?.displayURL(url)
        }
    }

    func setupSeparators(cell: NoteBlockTableViewCell, indexPath: NSIndexPath) {
        cell.isBadge = note.isBadge
        cell.isLastRow = (indexPath.row >= blockGroups.count - 1)
    }
}



// MARK: - Notification Helpers
//
extension NotificationDetailsViewController
{
    func notificationWasUpdated(notification: NSNotification) {
        let updated   = notification.userInfo?[NSUpdatedObjectsKey]   as? Set<NSManagedObject> ?? Set()
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deleted   = notification.userInfo?[NSDeletedObjectsKey]   as? Set<NSManagedObject> ?? Set()

        // Reload the table, if *our* notification got updated
        if updated.contains(note) || refreshed.contains(note) {
            reloadData()
        }

        // Dismiss this ViewController if *our* notification... just got deleted
        if deleted.contains(note) {
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
}



// MARK: - Resources
//
extension NotificationDetailsViewController
{
    func displayURL(url: NSURL?) {
        guard let url = url else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        // Attempt to infer the NotificationRange associated: Recover Metadata + Push Native Views!
        //
        do {
            let range = note.notificationRangeWithUrl(url)
            try displayResourceWithRange(range)
        } catch {
            displayWebViewWithURL(url)
        }
    }

    func displayNotificationSource() {
        guard let resourceURL = note.resourceURL else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        do {
            switch note.kind {
            case .Follow:
                try displayStreamWithSiteID(note.metaSiteID)
            case .Like:
                fallthrough
            case .Matcher:
                fallthrough
            case .Post:
                try displayReaderWithPostId(note.metaPostID, siteID: note.metaSiteID)
            case .Comment:
                fallthrough
            case .CommentLike:
                try displayCommentsWithPostId(note.metaPostID, siteID: note.metaSiteID)
            default:
                throw DisplayError.UnsupportedType
            }
        } catch {
            displayWebViewWithURL(resourceURL)
        }
    }



    // MARK: - Displaying Ranges!

    private func displayResourceWithRange(range: NotificationRange?) throws {
        guard let range = range else {
            throw DisplayError.MissingParameter
        }

        switch range.kind {
        case .Site:
            try displayStreamWithSiteID(range.siteID)
        case .Post:
            try displayReaderWithPostId(range.postID, siteID: range.siteID)
        case .Comment:
            try displayCommentsWithPostId(range.postID, siteID: range.siteID)
        case .Stats:
            try displayStatsWithSiteID(range.siteID)
        case .Follow:
            try displayFollowersWithSiteID(range.siteID)
        case .User:
            try displayStreamWithSiteID(range.siteID)
        default:
            throw DisplayError.UnsupportedType
        }
    }


    // MARK: - Private Helpers

    private func displayReaderWithPostId(postID: NSNumber?, siteID: NSNumber?) throws {
        guard let postID = postID, let siteID = siteID else {
            throw DisplayError.MissingParameter
        }

        let readerViewController = ReaderDetailViewController.controllerWithPostID(postID, siteID: siteID)
        navigationController?.pushViewController(readerViewController, animated: true)
    }

    private func displayCommentsWithPostId(postID: NSNumber?, siteID: NSNumber?) throws {
        guard let postID = postID, let siteID = siteID else {
            throw DisplayError.MissingParameter
        }

        let commentsViewController = ReaderCommentsViewController(postID: postID, siteID: siteID)
        commentsViewController.allowsPushingPostDetails = true
        navigationController?.pushViewController(commentsViewController, animated: true)
    }

    private func displayStatsWithSiteID(siteID: NSNumber?) throws {
        guard let blog = blogWithBlogID(siteID) where blog.supports(.Stats) else {
            throw DisplayError.MissingParameter
        }

        let statsViewController = StatsViewController()
        statsViewController.blog = blog
        navigationController?.pushViewController(statsViewController, animated: true)
    }

    private func displayFollowersWithSiteID(siteID: NSNumber?) throws {
        guard let blog = blogWithBlogID(siteID) else {
            throw DisplayError.MissingParameter
        }

        let statsViewController = newStatsViewController()
        statsViewController.selectedDate = NSDate()
        statsViewController.statsSection = .Followers
        statsViewController.statsSubSection = .FollowersDotCom
        statsViewController.statsService = newStatsServiceWithBlog(blog)
        navigationController?.pushViewController(statsViewController, animated: true)
    }

    private func displayStreamWithSiteID(siteID: NSNumber?) throws {
        guard let siteID = siteID else {
            throw DisplayError.MissingParameter
        }

        let browseViewController = ReaderStreamViewController.controllerWithSiteID(siteID, isFeed: false)
        navigationController?.pushViewController(browseViewController, animated: true)
    }

    private func displayWebViewWithURL(url: NSURL) {
        let webViewController = WPWebViewController.authenticatedWebViewController(url)
        let navController = UINavigationController(rootViewController: webViewController)
        presentViewController(navController, animated: true, completion: nil)
    }

    private func displayFullscreenImage(image: UIImage) {
        let imageViewController = WPImageViewController(image: image)
        imageViewController.modalTransitionStyle = .CrossDissolve
        imageViewController.modalPresentationStyle = .FullScreen
        presentViewController(imageViewController, animated: true, completion: nil)
    }
}



// MARK: - Helpers
//
private extension NotificationDetailsViewController
{
    func blockGroupForIndexPath(indexPath: NSIndexPath) -> NotificationBlockGroup {
        return blockGroups[indexPath.row]
    }

    func blogWithBlogID(blogID: NSNumber?) -> Blog? {
        guard let blogID = blogID else {
            return nil
        }

        let service = BlogService(managedObjectContext: mainContext)
        return service.blogByBlogId(blogID)
    }

    func newStatsViewController() -> StatsViewAllTableViewController {
        let statsBundle = NSBundle(forClass: WPStatsViewController.self)
        guard let path = statsBundle.pathForResource("WordPressCom-Stats-iOS", ofType: "bundle"),
            let bundle = NSBundle(path: path) else
        {
            fatalError("Error loading Stats Bundle")
        }

        let storyboard = UIStoryboard(name: "SiteStats", bundle: bundle)
        let identifier = StatsViewAllTableViewController.classNameWithoutNamespaces()
        let statsViewController = storyboard.instantiateViewControllerWithIdentifier(identifier)

        return statsViewController as! StatsViewAllTableViewController
    }

    func newStatsServiceWithBlog(blog: Blog) -> WPStatsService {
        let blogService = BlogService(managedObjectContext: mainContext)
        return WPStatsService(siteId: blog.dotComID,
                              siteTimeZone: blogService.timeZoneForBlog(blog),
                              oauth2Token: blog.authToken,
                              andCacheExpirationInterval: Settings.expirationFiveMinutes)
    }
}



// MARK: - Media Download Helpers
//
private extension NotificationDetailsViewController
{
    func downloadAndResizeMedia(indexPath: NSIndexPath, blockGroup: NotificationBlockGroup) {
        //  Notes:
        //  -   We'll *only* download Media for Text and Comment Blocks
        //  -   Plus, we'll also resize the downloaded media cache *if needed*. This is meant to adjust images to
        //      better fit onscreen, whenever the device orientation changes (and in turn, the maxMediaEmbedWidth changes too).
        //
        let imageUrls = blockGroup.imageUrlsFromBlocksInKindSet(Media.richBlockTypes)

        let completion = {
            // Workaround: Performing the reload call, multiple times, without the .BeginFromCurrentState might
            // lead to a state in which the cell remains not visible.
            //
            UIView.animateWithDuration(Media.duration, delay: Media.delay, options: Media.options, animations: { [weak self] in
                self?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }, completion: nil)
        }

        mediaDownloader.downloadMedia(urls: imageUrls, maximumWidth: maxMediaEmbedWidth, completion: completion)
        mediaDownloader.resizeMediaWithIncorrectSize(maxMediaEmbedWidth, completion: completion)
    }

    var maxMediaEmbedWidth: CGFloat {
        let textPadding = NoteBlockTextTableViewCell.defaultLabelPadding
        let portraitWidth = WPDeviceIdentification.isiPad() ? WPTableViewFixedWidth : view.bounds.width
        let maxWidth = portraitWidth - (textPadding.left + textPadding.right)

        return maxWidth
    }
}



// MARK: - Action Handlers
//
private extension NotificationDetailsViewController
{
    func followSiteWithBlock(block: NotificationBlock) {
        actionsService.followSiteWithBlock(block)
        WPAppAnalytics.track(.NotificationsSiteFollowAction, withBlogID: block.metaSiteID)
    }

    func unfollowSiteWithBlock(block: NotificationBlock) {
        actionsService.unfollowSiteWithBlock(block)
        WPAppAnalytics.track(.NotificationsSiteUnfollowAction, withBlogID: block.metaSiteID)
    }

    func likeCommentWithBlock(block: NotificationBlock) {
        actionsService.likeCommentWithBlock(block)
        WPAppAnalytics.track(.NotificationsCommentLiked, withBlogID: block.metaSiteID)
    }

    func unlikeCommentWithBlock(block: NotificationBlock) {
        actionsService.unlikeCommentWithBlock(block)
        WPAppAnalytics.track(.NotificationsCommentUnliked, withBlogID: block.metaSiteID)
    }

    func approveCommentWithBlock(block: NotificationBlock) {
        actionsService.approveCommentWithBlock(block)
        WPAppAnalytics.track(.NotificationsCommentApproved, withBlogID: block.metaSiteID)
    }

    func unapproveCommentWithBlock(block: NotificationBlock) {
        actionsService.unapproveCommentWithBlock(block)
        WPAppAnalytics.track(.NotificationsCommentUnapproved, withBlogID: block.metaSiteID)
    }

    func spamCommentWithBlock(block: NotificationBlock) {
        precondition(onDeletionRequestCallback != nil)

        onDeletionRequestCallback? { onCompletion in
            let mainContext = ContextManager.sharedInstance().mainContext
            let service = NotificationActionsService(managedObjectContext: mainContext)
            service.spamCommentWithBlock(block) { success in
                onCompletion(success)
            }

            WPAppAnalytics.track(.NotificationsCommentFlaggedAsSpam, withBlogID: block.metaSiteID)
        }

        // We're thru
        navigationController?.popToRootViewControllerAnimated(true)
    }

    func trashCommentWithBlock(block: NotificationBlock) {
        precondition(onDeletionRequestCallback != nil)

        // Hit the DeletionRequest Callback
        onDeletionRequestCallback? { onCompletion in
            let mainContext = ContextManager.sharedInstance().mainContext
            let service = NotificationActionsService(managedObjectContext: mainContext)
            service.deleteCommentWithBlock(block) { success in
                onCompletion(success)
            }

            WPAppAnalytics.track(.NotificationsCommentTrashed, withBlogID: block.metaSiteID)
        }

        // We're thru
        navigationController?.popToRootViewControllerAnimated(true)
    }

    func replyCommentWithBlock(block: NotificationBlock, content: String) {
        actionsService.replyCommentWithBlock(block, content: content, completion: { success in
            guard success else {
                self.displayReplyErrorWithBlock(block, content: content)
                return
            }

            let message = NSLocalizedString("Reply Sent!", comment: "The app successfully sent a comment")
            SVProgressHUD.showSuccessWithStatus(message)
        })
    }

    func updateCommentWithBlock(block: NotificationBlock, content: String) {
        actionsService.updateCommentWithBlock(block, content: content, completion: { success in
            guard success == false else {
                return
            }
            self.displayCommentUpdateErrorWithBlock(block, content: content)
        })
    }
}



// MARK: - Replying Comments
//
private extension NotificationDetailsViewController
{
    func displayReplyEditorWithBlock(block: NotificationBlock) {
        guard let siteID = note.metaSiteID else {
            return
        }

        let editViewController = EditReplyViewController.newReplyViewControllerForSiteID(siteID)
        editViewController.onCompletion = { (hasNewContent, newContent) in
            self.dismissViewControllerAnimated(true, completion: {
                guard hasNewContent else {
                    return
                }

                self.replyCommentWithBlock(block, content: newContent)
            })
        }

        let navController = UINavigationController(rootViewController: editViewController)
        navController.modalPresentationStyle = .FormSheet
        navController.modalTransitionStyle = .CoverVertical
        navController.navigationBar.translucent = false
        presentViewController(navController, animated: true, completion: nil)
    }

    func displayReplyErrorWithBlock(block: NotificationBlock, content: String) {
        let message     = NSLocalizedString("There has been an unexpected error while sending your reply",
                                            comment: "Reply Failure Message")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancels an Action")
        let retryTitle  = NSLocalizedString("Try Again", comment: "Retries sending a reply")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addCancelActionWithTitle(cancelTitle)
        alertController.addDefaultActionWithTitle(retryTitle) { action in
            self.replyCommentWithBlock(block, content: content)
        }

        // Note: This viewController might not be visible anymore
        alertController.presentFromRootViewController()
    }
}



// MARK: - Editing Comments
//
private extension NotificationDetailsViewController
{
    func displayCommentEditorWithBlock(block: NotificationBlock) {
        let editViewController = EditCommentViewController.newEditViewController()
        editViewController.content = block.text
        editViewController.onCompletion = { (hasNewContent, newContent) in
            self.dismissViewControllerAnimated(true, completion: {
                guard hasNewContent else {
                    return
                }

                self.updateCommentWithBlock(block, content: newContent)
            })
        }

        let navController = UINavigationController(rootViewController: editViewController)
        navController.modalPresentationStyle = .FormSheet
        navController.modalTransitionStyle = .CoverVertical
        navController.navigationBar.translucent = false

        presentViewController(navController, animated: true, completion: nil)
    }

    func displayCommentUpdateErrorWithBlock(block: NotificationBlock, content: String) {
        let message     = NSLocalizedString("There has been an unexpected error while updating your comment",
                                            comment: "Displayed whenever a Comment Update Fails")
        let cancelTitle = NSLocalizedString("Give Up", comment: "Cancel")
        let retryTitle  = NSLocalizedString("Try Again", comment: "Retry")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addCancelActionWithTitle(cancelTitle) { action in
            block.textOverride = nil
            self.reloadData()
        }
        alertController.addDefaultActionWithTitle(retryTitle) { action in
            self.updateCommentWithBlock(block, content: content)
        }

        // Note: This viewController might not be visible anymore
        alertController.presentFromRootViewController()
    }
}



// MARK: - UITextViewDelegate
//
extension NotificationDetailsViewController: ReplyTextViewDelegate
{
    func textView(textView: UITextView, didTypeWord word: String) {
        suggestionsTableView.showSuggestionsForWord(word)
    }
}



// MARK: - UIScrollViewDelegate
//
extension NotificationDetailsViewController: UIScrollViewDelegate
{
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        keyboardManager.scrollViewWillBeginDragging(scrollView)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        keyboardManager.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        keyboardManager.scrollViewWillEndDragging(scrollView, withVelocity: velocity)
    }
}



// MARK: - SuggestionsTableViewDelegate
//
extension NotificationDetailsViewController: SuggestionsTableViewDelegate
{
    func suggestionsTableView(suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        replyTextView.replaceTextAtCaret(text, withText: suggestion)
        suggestionsTableView.showSuggestionsForWord(String())
    }
}



// MARK: - Private Properties
//
private extension NotificationDetailsViewController
{
    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var actionsService: NotificationActionsService {
        return NotificationActionsService(managedObjectContext: mainContext)
    }

    enum DisplayError: ErrorType {
        case MissingParameter
        case UnsupportedFeature
        case UnsupportedType
    }

    enum Media {
        static let richBlockTypes           = Set(arrayLiteral: NotificationBlock.Kind.Text, NotificationBlock.Kind.Comment)
        static let duration                 = NSTimeInterval(0.25)
        static let delay                    = NSTimeInterval(0)
        static let options                  : UIViewAnimationOptions = [.OverrideInheritedDuration, .BeginFromCurrentState]
    }

    enum Restoration {
        static let noteIdKey                = Notification.classNameWithoutNamespaces()
        static let restorationIdentifier    = NotificationDetailsViewController.classNameWithoutNamespaces()
    }

    enum Settings {
        static let numberOfSections         = 1
        static let expirationFiveMinutes    = NSTimeInterval(60 * 5)
    }
}
