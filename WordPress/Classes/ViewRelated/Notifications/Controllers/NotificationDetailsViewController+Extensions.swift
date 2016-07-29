import Foundation
import CoreData
import Simperium
import WordPressShared



/// Setup Helpers
///
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

    func setupMediaDownloader() {
        // TODO: Nuke this method as soon as the Header is 100% Swift
        mediaDownloader = NotificationMediaDownloader()
    }

    func setupReplyTextView() {
        let replyTextView = ReplyTextView(width: view.frame.width)
        replyTextView.placeholder = NSLocalizedString("Write a reply…", comment: "Placeholder text for inline compose view")
        replyTextView.replyText = NSLocalizedString("Reply", comment: "").uppercaseString
        replyTextView.accessibilityIdentifier = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
        replyTextView.delegate = self
        replyTextView.onReply = { [weak self] content in
            guard let block = self?.note.blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
                return
            }
            self?.sendReplyWithBlock(block, content: content)
        }

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



/// Reply View Helpers
///
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
        guard let block = note.blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
            return false
        }

        return block.isActionOn(NoteActionReplyKey) && !WPDeviceIdentification.isiPad()
    }
}



/// Suggestions View Helpers
///
extension NotificationDetailsViewController
{
    // TODO: This should be private
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

    private  var shouldAttachSuggestionsView: Bool {
        guard let siteID = note.metaSiteID else {
            return false
        }

        let suggestionsService = SuggestionService()
        return shouldAttachReplyView && suggestionsService.shouldShowSuggestionsForSiteID(siteID)
    }
}


/// Edition Helpers
///
extension NotificationDetailsViewController
{
    // TODO: This should be Private once ready
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

    private var shouldAttachEditAction: Bool {
        let block = note.blockGroupOfType(.Comment)?.blockOfType(.Comment)
        return block?.isActionOn(NoteActionEditKey) ?? false
    }

    @IBAction func editButtonWasPressed() {
        guard let block = note.blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
            return
        }

        if block.isActionOn(NoteActionEditKey) {
            editCommentWithBlock(block)
        }
    }
}



/// Style Helpers
///
extension NotificationDetailsViewController
{
    // TODO: This should be private once ready
    func adjustLayoutConstraintsIfNeeded() {
        // Badge Notifications should be centered, and display no cell separators
        let shouldCenterVertically = note.isBadge

        topLayoutConstraint.active = !shouldCenterVertically
        bottomLayoutConstraint.active = !shouldCenterVertically
        centerLayoutConstraint.active = shouldCenterVertically

        // Lock Scrolling for Badge Notifications
        tableView.scrollEnabled = !shouldCenterVertically
    }
}



/// UITableViewCell Subclass Setup
///
extension NotificationDetailsViewController
{
    func setupCell(cell: NoteBlockTableViewCell, blockGroup: NotificationBlockGroup) {
        // Temporarily force margins for WPTableViewCell hack.
        // Brent C. Jul/19/2016
        cell.forceCustomCellMargins = true

        switch cell {
        case let cell as NoteBlockHeaderTableViewCell:
            setupHeaderCell(cell, blockGroup: blockGroup)
        case let cell as NoteBlockTextTableViewCell where blockGroup.type == .Footer:
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
        let gravatarBlock = blockGroup.blockOfType(.Image)
        let snippetBlock = blockGroup.blockOfType(.Text)

        cell.attributedHeaderTitle = gravatarBlock?.attributedHeaderTitleText()
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

        cell.attributedText = textBlock.attributedFooterText()
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
        cell.isFollowEnabled = userBlock.isActionEnabled(NoteActionFollowKey)
        cell.isFollowOn = userBlock.isActionOn(NoteActionFollowKey)

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
        guard let commentBlock = blockGroup.blockOfType(.Comment) else {
            assertionFailure("Missing Comment Block for Notification [\(note.simperiumKey)]")
            return
        }

        guard let userBlock = blockGroup.blockOfType(.User) else {
            assertionFailure("Missing User Block for Notification [\(note.simperiumKey)]")
            return
        }

        // Merge the Attachments with their ranges: [NSRange: UIImage]
        let mediaMap = mediaDownloader.imagesForUrls(commentBlock.imageUrls())
        let mediaRanges = commentBlock.buildRangesToImagesMap(mediaMap)

        let text = commentBlock.attributedRichText().stringByEmbeddingImageAttachments(mediaRanges)

        // Setup: Properties
        cell.name                   = userBlock.text
        cell.timestamp              = note.timestampAsDate.shortString()
        cell.site                   = userBlock.metaTitlesHome ?? userBlock.metaLinksHome?.host
        cell.attributedCommentText  = text.trimTrailingNewlines()
        cell.isApproved             = commentBlock.isCommentApproved()
        cell.hasReply               = note.hasReply

        // Setup: Callbacks
        cell.onDetailsClick = { [weak self] sender in
            guard let homeURL = userBlock.metaLinksHome else {
                return
            }

            self?.openURL(homeURL)
        }

        cell.onUrlClick = { [weak self] url in
            self?.openURL(url)
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
        guard let commentBlock = blockGroup.blockOfType(.Comment) else {
            assertionFailure("Missing Comment Block for Notification \(note.simperiumKey)")
            return
        }

        // Setup: Properties
        cell.isReplyEnabled     = WPDeviceIdentification.isiPad() && commentBlock.isActionOn(NoteActionReplyKey)
        cell.isLikeEnabled      = commentBlock.isActionEnabled(NoteActionLikeKey)
        cell.isApproveEnabled   = commentBlock.isActionEnabled(NoteActionApproveKey)
        cell.isTrashEnabled     = commentBlock.isActionEnabled(NoteActionTrashKey)
        cell.isSpamEnabled      = commentBlock.isActionEnabled(NoteActionSpamKey)
        cell.isLikeOn           = commentBlock.isActionOn(NoteActionLikeKey)
        cell.isApproveOn        = commentBlock.isActionOn(NoteActionApproveKey)

        // Setup: Callbacks
        cell.onReplyClick = { [weak self] sender in
            self?.editReplyWithBlock(commentBlock)
        }

        cell.onLikeClick = { [weak self] sender in
            self?.likeCommentWithBlock(commentBlock)
        }

        cell.onUnlikeClick = { [weak self] sender in
            self?.unlikeCommentWithBlock(commentBlock)
        }

        cell.onApproveClick = { [weak self] sender in
            self?.approveCommentWithBlock(commentBlock)
        }

        cell.onUnapproveClick = { [weak self] sender in
            self?.unapproveCommentWithBlock(commentBlock)
        }

        cell.onTrashClick = { [weak self] sender in
            self?.trashCommentWithBlock(commentBlock)
        }

        cell.onSpamClick = { [weak self] sender in
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
        let mediaMap = mediaDownloader.imagesForUrls(textBlock.imageUrls())
        let mediaRanges = textBlock.buildRangesToImagesMap(mediaMap)

        // Load the attributedText
        let text = note.isBadge ? textBlock.attributedBadgeText() : textBlock.attributedRichText()

        // Setup: Properties
        cell.attributedText = text.stringByEmbeddingImageAttachments(mediaRanges)

        // Setup: Callbacks
        cell.onUrlClick = { [weak self] url in
            self?.openURL(url)
        }
    }

    func setupSeparators(cell: NoteBlockTableViewCell, indexPath: NSIndexPath) {
        cell.isBadge = note.isBadge
        cell.isLastRow = (indexPath.row >= blockGroups.count - 1)
    }
}



/// Notification Helpers
///
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



/// Resources
///
extension NotificationDetailsViewController
{
    func openURL(url: NSURL) {
        // Attempt to match the URL with any NotificationRange contained within the note, and.. recover the metadata!
        //
        guard let range = note.notificationRangeWithUrl(url) else {
            displayWebViewWithURL(url)
            return
        }

        if let postID = range.postID, let siteID = range.siteID where range.isPost {
            displayReaderWithPostId(postID, siteID: siteID)
            return
        }

        if let postID = range.postID, let siteID = range.siteID where range.isComment {
            displayCommentsWithPostId(postID, siteID: siteID)
            return
        }

        if let blog = blogWithBlogID(range.siteID) where blog.supports(.Stats) && range.isStats {
            displayStatsWithBlog(blog)
            return
        }

        if let blog = blogWithBlogID(note.metaSiteID) where blog.isHostedAtWPcom && range.isFollow {
            displayFollowersWithBlog(blog)
            return
        }

        if let siteID = range.siteID where range.isUser {
            displayBrowseSiteWithID(siteID)
            return
        }

        tableView.deselectSelectedRowWithAnimation(true)
    }

    func openNotificationSource() {
        if let siteID = note.metaSiteID where note.isFollow {
            displayBrowseSiteWithID(siteID)
            return
        }

        if let postID = note.metaPostID, let siteID = note.metaSiteID, let _ = note.metaCommentID {
            displayCommentsWithPostId(postID, siteID: siteID)
            return
        }

        if let postID = note.metaPostID, let siteID = note.metaSiteID {
            displayReaderWithPostId(postID, siteID: siteID)
            return
        }

        if let notificationURL = note.url, let resourceURL = NSURL(string: notificationURL) {
            displayWebViewWithURL(resourceURL)
            return
        }

        tableView.deselectSelectedRowWithAnimation(true)
    }


    // MARK: - Private Helpers

    private func displayReaderWithPostId(postID: NSNumber, siteID: NSNumber) {
        let readerViewController = ReaderDetailViewController.controllerWithPostID(postID, siteID: siteID)
        navigationController?.pushViewController(readerViewController, animated: true)
    }

    private func displayCommentsWithPostId(postID: NSNumber, siteID: NSNumber) {
        let commentsViewController = ReaderCommentsViewController(postID: postID, siteID: siteID)
        commentsViewController.allowsPushingPostDetails = true
        navigationController?.pushViewController(commentsViewController, animated: true)
    }

    private func displayStatsWithBlog(blog: Blog) {
        precondition(blog.supports(.Stats))

        let statsViewController = StatsViewController()
        statsViewController.blog = blog
        navigationController?.pushViewController(statsViewController, animated: true)
    }

    private func displayFollowersWithBlog(blog: Blog) {
        precondition(blog.isHostedAtWPcom)

        let statsViewController = newStatsViewController()
        statsViewController.selectedDate = NSDate()
        statsViewController.statsSection = .Followers
        statsViewController.statsSubSection = .FollowersDotCom
        statsViewController.statsService = newStatsServiceWithBlog(blog)
        navigationController?.pushViewController(statsViewController, animated: true)
    }

    private func displayWebViewWithURL(url: NSURL) {
        let webViewController = WPWebViewController.authenticatedWebViewController(url)
        let navController = UINavigationController(rootViewController: webViewController)
        presentViewController(navController, animated: true, completion: nil)
    }

    private func displayBrowseSiteWithID(siteID: NSNumber) {
        let browseViewController = ReaderStreamViewController.controllerWithSiteID(siteID, isFeed: false)
        navigationController?.pushViewController(browseViewController, animated: true)
    }

    private func displayFullscreenImage(image: UIImage) {
        let imageViewController = WPImageViewController(image: image)
        imageViewController.modalTransitionStyle = .CrossDissolve
        imageViewController.modalPresentationStyle = .FullScreen
        presentViewController(imageViewController, animated: true, completion: nil)
    }
}



/// Helpers
///
private extension NotificationDetailsViewController
{
    func blogWithBlogID(blogID: NSNumber?) -> Blog? {
        guard let blogID = blogID else {
            return nil
        }

        let service = BlogService(managedObjectContext: mainContext)
        return service.blogByBlogId(blogID)
    }

    func newStatsViewController() -> StatsViewAllTableViewController {
        let identifier = StatsViewAllTableViewController.classNameWithoutNamespaces()
        let bundle = NSBundle(forClass: WPStatsViewController.self)
        let storyboard = UIStoryboard(name: "SiteStats", bundle: bundle)
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



/// UITextViewDelegate
///
extension NotificationDetailsViewController: ReplyTextViewDelegate
{
    public func textViewDidBeginEditing(textView: UITextView) {
        tableGesturesRecognizer.enabled = true
    }

    public func textViewDidEndEditing(textView: UITextView) {
        tableGesturesRecognizer.enabled = false
    }

    public func textView(textView: UITextView, didTypeWord word: String) {
        suggestionsTableView.showSuggestionsForWord(word)
    }
}



/// UIScrollViewDelegate
///
extension NotificationDetailsViewController: UIScrollViewDelegate
{
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        keyboardManager.scrollViewWillBeginDragging(scrollView)
    }

    public func scrollViewDidScroll(scrollView: UIScrollView) {
        keyboardManager.scrollViewDidScroll(scrollView)
    }

    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        keyboardManager.scrollViewWillEndDragging(scrollView, withVelocity: velocity)
    }
}



/// SuggestionsTableViewDelegate
///
extension NotificationDetailsViewController: SuggestionsTableViewDelegate
{
    public func suggestionsTableView(suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        replyTextView.replaceTextAtCaret(text, withText: suggestion)
        suggestionsTableView.showSuggestionsForWord(String())
    }
}



/// Gestures Recognizer Delegate
///
extension NotificationDetailsViewController: UIGestureRecognizerDelegate
{
    @IBAction public func dismissKeyboardIfNeeded(sender: AnyObject) {
        view.endEditing(true)
    }

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Note: the tableViewGestureRecognizer may compete with another GestureRecognizer. Make sure it doesn't get cancelled
        return true
    }
}


// MARK: - Private Properties
//
private extension NotificationDetailsViewController
{
    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    enum Settings {
        static let expirationFiveMinutes = NSTimeInterval(60 * 5)
    }
}
