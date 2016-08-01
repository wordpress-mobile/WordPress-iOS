import Foundation
import CoreData
import Simperium
import SVProgressHUD
import WordPressShared



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
        guard let block = note.blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
            return false
        }

        return block.isActionOn(NoteActionReplyKey) && !WPDeviceIdentification.isiPad()
    }
}



// MARK: - Suggestions View Helpers
//
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


// MARK: - Edition Helpers
//
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



// MARK: - Style Helpers
//
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



// MARK: - UITableViewCell Subclass Setup
//
extension NotificationDetailsViewController
{
    func setupCell(cell: NoteBlockTableViewCell, blockGroup: NotificationBlockGroup) {
        // Temporarily force margins for WPTableViewCell hack.
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
        guard let type = note.type, let resourceURL = note.resourceURL() else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        do {
            switch type {
            case NoteTypeFollow:
                try displayStreamWithSiteID(note.metaSiteID)
            case NoteTypeLike:
                fallthrough
            case NoteTypeMatcher:
                fallthrough
            case NoteTypePost:
                try displayReaderWithPostId(note.metaPostID, siteID: note.metaSiteID)
            case NoteTypeComment:
                fallthrough
            case NoteTypeCommentLike:
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

        switch range.type {
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
extension NotificationDetailsViewController
{
    func downloadAndResizeMedia(indexPath: NSIndexPath, blockGroup: NotificationBlockGroup) {
        //  Notes:
        //  -   We'll *only* download Media for Text and Comment Blocks
        //  -   Plus, we'll also resize the downloaded media cache *if needed*. This is meant to adjust images to
        //      better fit onscreen, whenever the device orientation changes (and in turn, the maxMediaEmbedWidth changes too).
        //
        let richBlockTypes = Set(arrayLiteral: [NoteBlockType.Text.rawValue, NoteBlockType.Comment.rawValue])
        let imageUrls = blockGroup.imageUrlsForBlocksOfTypes(richBlockTypes)

        let completion = {
            // Workaround:
            // Performing the reload call, multiple times, without the UIViewAnimationOptionBeginFromCurrentState might
            // lead to a state in which the cell remains not visible.
            //
            let duration    = NSTimeInterval(0.25)
            let delay       = NSTimeInterval(0)
            let options     : UIViewAnimationOptions = [.OverrideInheritedDuration, .BeginFromCurrentState]

            UIView.animateWithDuration(duration, delay: delay, options: options, animations: { [weak self] in
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
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            return
        }

        let service = ReaderSiteService(managedObjectContext: mainContext)
        service.followSiteWithID(siteID, success: nil) { [weak self] error in
            block.removeActionOverrideForKey(NoteActionFollowKey)
            self?.reloadData()
        }

        block.setActionOverrideValue(true, forKey: NoteActionFollowKey)
        WPAppAnalytics.track(.NotificationsSiteFollowAction, withBlogID: block.metaSiteID)
    }

    func unfollowSiteWithBlock(block: NotificationBlock) {
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            return
        }

        let service = ReaderSiteService(managedObjectContext: mainContext)
        service.unfollowSiteWithID(siteID, success: nil) { [weak self] error in
            block.removeActionOverrideForKey(NoteActionFollowKey)
            self?.reloadData()
        }

        block.setActionOverrideValue(false, forKey: NoteActionFollowKey)
        WPAppAnalytics.track(.NotificationsSiteUnfollowAction, withBlogID: siteID)
    }

    func likeCommentWithBlock(block: NotificationBlock) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        // If the associated comment is *not* approved, let's attempt to auto-approve it, automatically
        if block.isCommentApproved() == false {
            approveCommentWithBlock(block)
        }

        // Proceed toggling the Like field
        let service = CommentService(managedObjectContext: mainContext)
        service.likeCommentWithID(commentID, siteID: siteID, success: nil) { [weak self] error in
            block.removeActionOverrideForKey(NoteActionLikeKey)
            self?.reloadData()
        }

        block.setActionOverrideValue(true, forKey: NoteActionLikeKey)
        WPAppAnalytics.track(.NotificationsCommentLiked, withBlogID: siteID)
    }

    func unlikeCommentWithBlock(block: NotificationBlock) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: mainContext)
        service.unlikeCommentWithID(commentID, siteID: siteID, success: nil) { [weak self] error in
            block.removeActionOverrideForKey(NoteActionLikeKey)
            self?.reloadData()
        }

        block.setActionOverrideValue(false, forKey: NoteActionLikeKey)
        WPAppAnalytics.track(.NotificationsCommentUnliked, withBlogID: siteID)
    }

    func approveCommentWithBlock(block: NotificationBlock) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: mainContext)
        service.approveCommentWithID(commentID, siteID: siteID, success: nil) { [weak self] error in
            block.removeActionOverrideForKey(NoteActionApproveKey)
            self?.reloadData()
        }

        block.setActionOverrideValue(true, forKey: NoteActionApproveKey)
        tableView.reloadData()
        WPAppAnalytics.track(.NotificationsCommentApproved, withBlogID: siteID)
    }

    func unapproveCommentWithBlock(block: NotificationBlock) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: mainContext)
        service.unapproveCommentWithID(commentID, siteID: siteID, success: nil) { [weak self] error in
            block.removeActionOverrideForKey(NoteActionApproveKey)
            self?.reloadData()
        }

        block.setActionOverrideValue(false, forKey: NoteActionApproveKey)
        tableView.reloadData()
        WPAppAnalytics.track(.NotificationsCommentUnapproved, withBlogID: siteID)
    }

    func spamCommentWithBlock(block: NotificationBlock) {
        precondition(onDeletionRequestCallback != nil)

        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        // Spam Action
        onDeletionRequestCallback? { onCompletion in
            let mainContext = ContextManager.sharedInstance().mainContext
            let service = CommentService(managedObjectContext: mainContext)

            service.spamCommentWithID(commentID, siteID: siteID, success: {
                onCompletion(true)
            }, failure: { error in
                onCompletion(false)
            })

            WPAppAnalytics.track(.NotificationsCommentFlaggedAsSpam, withBlogID: siteID)
        }

        // We're thru
        navigationController?.popToRootViewControllerAnimated(true)
    }

    func trashCommentWithBlock(block: NotificationBlock) {
        precondition(onDeletionRequestCallback != nil)

        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        // Hit the DeletionRequest Callback
        onDeletionRequestCallback? { onCompletion in
            let mainContext = ContextManager.sharedInstance().mainContext
            let service = CommentService(managedObjectContext: mainContext)

            service.deleteCommentWithID(commentID, siteID: siteID, success: {
                onCompletion(true)
            }, failure: { error in
                onCompletion(false)
            })

            WPAppAnalytics.track(.NotificationsCommentTrashed, withBlogID: siteID)
        }

        // We're thru
        navigationController?.popToRootViewControllerAnimated(true)
    }
}



// MARK: - Replying Comments
//
extension NotificationDetailsViewController
{
    func editReplyWithBlock(block: NotificationBlock) {
        guard let siteID = note.metaSiteID else {
            return
        }

        let editViewController = EditReplyViewController.newReplyViewControllerForSiteID(siteID)
        editViewController.onCompletion = { (hasNewContent, newContent) in
            self.dismissViewControllerAnimated(true, completion: {
                if hasNewContent {
                    self.sendReplyWithBlock(block, content: newContent)
                }
            })
        }

        let navController = UINavigationController(rootViewController: editViewController)
        navController.modalPresentationStyle = .FormSheet
        navController.modalTransitionStyle = .CoverVertical
        navController.navigationBar.translucent = false
        presentViewController(navController, animated: true, completion: nil)
    }

    func sendReplyWithBlock(block: NotificationBlock, content: String) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: mainContext)
        service.replyToCommentWithID(commentID, siteID: siteID, content: content, success: {
            let message = NSLocalizedString("Reply Sent!", comment: "The app successfully sent a comment")
            SVProgressHUD.showSuccessWithStatus(message)
        }, failure: { error in
            self.handleReplyErrorWithBlock(block, content: content)
        })
    }

    func handleReplyErrorWithBlock(block: NotificationBlock, content: String) {
        let message     = NSLocalizedString("There has been an unexpected error while sending your reply",
                                            comment: "Reply Failure Message")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancels an Action")
        let retryTitle  = NSLocalizedString("Try Again", comment: "Retries sending a reply")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addCancelActionWithTitle(cancelTitle)
        alertController.addDefaultActionWithTitle(retryTitle) { action in
            self.sendReplyWithBlock(block, content: content)
        }

        // Note: This viewController might not be visible anymore
        alertController.presentFromRootViewController()
    }
}



// MARK: - Editing Comments
//
extension NotificationDetailsViewController
{
    func editCommentWithBlock(block: NotificationBlock) {
        let editViewController = EditCommentViewController.newEditViewController()
        editViewController.content = block.text
        editViewController.onCompletion = { (hasNewContent, newContent) in
            self.dismissViewControllerAnimated(true, completion: {
                if hasNewContent {
                    self.updateCommentWithBlock(block, content: newContent)
                }
            })
        }

        let navController = UINavigationController(rootViewController: editViewController)
        navController.modalPresentationStyle = .FormSheet
        navController.modalTransitionStyle = .CoverVertical
        navController.navigationBar.translucent = false

        presentViewController(navController, animated: true, completion: nil)
    }

    func updateCommentWithBlock(block: NotificationBlock, content: String) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        // Local Override: Temporary hack until Simperium reflects the REST op
        block.textOverride = content
        reloadData()

        // Hit the backend
        let service = CommentService(managedObjectContext: mainContext)
        service.updateCommentWithID(commentID, siteID: siteID, content: content, success: nil) { [weak self] error in
            self?.handleCommentUpdateErrorWithBlock(block, content: content)
        }
    }

    func handleCommentUpdateErrorWithBlock(block: NotificationBlock, content: String) {
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



// MARK: - UIScrollViewDelegate
//
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



// MARK: - SuggestionsTableViewDelegate
//
extension NotificationDetailsViewController: SuggestionsTableViewDelegate
{
    public func suggestionsTableView(suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        replyTextView.replaceTextAtCaret(text, withText: suggestion)
        suggestionsTableView.showSuggestionsForWord(String())
    }
}



// MARK: - Gestures Recognizer Delegate
//
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

    enum DisplayError: ErrorType {
        case MissingParameter
        case UnsupportedFeature
        case UnsupportedType
    }

    enum Settings {
        static let expirationFiveMinutes = NSTimeInterval(60 * 5)
    }
}
