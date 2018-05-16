import UIKit
import WordPressShared
import WordPressUI

@objc class ReaderSavedPostsViewController: UITableViewController {
    private enum Strings {
        static let title = NSLocalizedString("Saved Posts", comment: "Title for list of posts saved for later")
    }
    fileprivate var noResultsView: WPNoResultsView!
    //fileprivate var tableViewHandler: WPTableViewHandler!
    fileprivate var footerView: PostListFooterView!
    fileprivate let heightForFooterView = CGFloat(34.0)
    fileprivate let estimatedHeightsCache = NSCache<AnyObject, AnyObject>()

    private let tableConfiguration = ReaderTableConfiguration()
    private let content = ReaderTableContent()

    fileprivate lazy var displayContext: NSManagedObjectContext = ContextManager.sharedInstance().newMainContextChildContext()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title

        setupTableView()
        setupFooterView()
        setupNoResultsView()
        setupContentViewHandler()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        updateAndPerformFetchRequest()
    }

    // MARK: - Setup

    fileprivate func setupTableView() {
        tableConfiguration.setup(tableView)
    }


    fileprivate func setupContentViewHandler() {
        content.initializeContent(tableView: tableView, delegate: self)
//        tableViewHandler = WPTableViewHandler(tableView: tableView)
//        tableViewHandler.cacheRowHeights = false
//        tableViewHandler.updateRowAnimation = .none
//        tableViewHandler.delegate = self
    }

    /// The fetch request can need a different predicate depending on how the content
    /// being displayed has changed (blocking sites for instance).  Call this method to
    /// update the fetch request predicate and then perform a new fetch.
    ///
    fileprivate func updateAndPerformFetchRequest() {
        content.updateAndPerformFetchRequest(predicate: predicateForFetchRequest())
    }

    fileprivate func setupNoResultsView() {
        noResultsView = WPNoResultsView()
    }

    fileprivate func setupFooterView() {
        guard let footer = tableConfiguration.footer() as? PostListFooterView else {
            assertionFailure()
            return
        }

        footerView = footer
        footerView.showSpinner(false)
        var frame = footerView.frame
        frame.size.height = heightForFooterView
        footerView.frame = frame
        tableView.tableFooterView = footerView
        footerView.isHidden = true
    }


    // MARK: - Helpers for TableViewHandler


    @objc func predicateForFetchRequest() -> NSPredicate {
        return NSPredicate(format: "isSavedForLater == YES")
    }


    @objc func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        let sortDescriptor = NSSortDescriptor(key: "sortRank", ascending: false)
        return [sortDescriptor]
    }


    @objc open func configurePostCardCell(_ cell: UITableViewCell, post: ReaderPost) {
        guard let topic = post.topic else {
            return
        }

        // To help avoid potential crash: https://github.com/wordpress-mobile/WordPress-iOS/issues/6757
        guard !post.isDeleted else {
            return
        }

        let postCell = cell as! ReaderPostCardCell

        // TODO: Enable post cell delegate / implement delegate methods in a helper
        postCell.delegate = self
        postCell.hidesFollowButton = ReaderHelpers.topicIsFollowing(topic)
        // TODO: Allow logged in features
        //        postCell.enableLoggedInFeatures = isLoggedIn
        postCell.headerBlogButtonIsEnabled = !ReaderHelpers.isTopicSite(topic)
        postCell.configureCell(post)
    }


    @objc open func configureCrossPostCell(_ cell: ReaderCrossPostCell, atIndexPath indexPath: IndexPath) {
        if content.isNull() {
            return
        }
        cell.accessoryType = .none
        cell.selectionStyle = .none

        guard let posts = content.content() as? [ReaderPost] else {
            return
        }

        let post = posts[indexPath.row]
        cell.configureCell(post)
    }


    @objc open func configureBlockedCell(_ cell: ReaderBlockedSiteCell, atIndexPath indexPath: IndexPath) {
        if content.isNull() {
            return
        }
        cell.accessoryType = .none
        cell.selectionStyle = .none

        guard let posts = content.content() as? [ReaderPost] else {
            return
        }
        let post = posts[indexPath.row]
        cell.setSiteName(post.blogName)
    }
}

// MARK: - WPTableViewHandlerDelegate

extension ReaderSavedPostsViewController: WPTableViewHandlerDelegate {

    // MARK: - Fetched Results Related

    public func managedObjectContext() -> NSManagedObjectContext {
        return displayContext
    }


    public func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        return fetchRequest
    }


    public func tableViewDidChangeContent(_ tableView: UITableView) {
        if content.isEmpty() {
            // TODO: Implement no results view
            //            displayNoResultsView()
        }
    }

    // MARK: - TableView Related

    public override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // When using UITableViewAutomaticDimension for auto-sizing cells, UITableView
        // likes to reload rows in a strange way.
        // It uses the estimated height as a starting value for reloading animations.
        // So this estimated value needs to be as accurate as possible to avoid any "jumping" in
        // the cell heights during reload animations.
        // Note: There may (and should) be a way to get around this, but there is currently no obvious solution.
        // Brent C. August 8/2016
        if let height = estimatedHeightsCache.object(forKey: indexPath as AnyObject) as? CGFloat {
            // Return the previously known height as it was cached via willDisplayCell.
            return height
        }
        return tableConfiguration.estimatedRowHeight()
    }


    override public func tableView(_ aTableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let posts = content.content() as? [ReaderPost] else {
            DDLogError("[ReaderStreamViewController tableView:cellForRowAtIndexPath:] fetchedObjects was nil.")
            return UITableViewCell()
        }
        let post = posts[indexPath.row]

        //        if recentlyBlockedSitePostObjectIDs.contains(post.objectID) {
        //            let cell = tableView.dequeueReusableCell(withIdentifier: readerBlockedCellReuseIdentifier) as! ReaderBlockedSiteCell
        //            configureBlockedCell(cell, atIndexPath: indexPath)
        //            return cell
        //        }

        if post.isCross() {
            let cell = tableConfiguration.crossPostCell(tableView)
            configureCrossPostCell(cell, atIndexPath: indexPath)
            return cell
        }

        let cell = tableConfiguration.postCardCell(tableView)
        configurePostCardCell(cell, post: post)
        return cell
    }

    override public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Cache the cell's layout height as the currently known height, for estimation.
        // See estimatedHeightForRowAtIndexPath
        estimatedHeightsCache.setObject(cell.frame.height as AnyObject, forKey: indexPath as AnyObject)

        guard cell.isKind(of: ReaderPostCardCell.self) || cell.isKind(of: ReaderCrossPostCell.self) else {
            return
        }

        guard let posts = content.content() as? [ReaderPost] else {
            DDLogError("[ReaderStreamViewController tableView:willDisplayCell:] fetchedObjects was nil.")
            return
        }
        // Bump the render tracker if necessary.
        let post = posts[indexPath.row]
        if !post.rendered, let railcar = post.railcarDictionary() {
            post.rendered = true
            WPAppAnalytics.track(.trainTracksRender, withProperties: railcar)
        }
    }


    /// Retrieve an instance of the specified post from the main NSManagedObjectContext.
    ///
    /// - Parameters:
    ///     - post: The post to retrieve.
    ///
    /// - Returns: The post fetched from the main context or nil if the post does not exist in the context.
    ///
    @objc func postInMainContext(_ post: ReaderPost) -> ReaderPost? {
        guard let post = (try? ContextManager.sharedInstance().mainContext.existingObject(with: post.objectID)) as? ReaderPost else {
            DDLogError("Error retrieving an exsting post from the main context by its object ID.")
            return nil
        }
        return post
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let posts = content.content() as? [ReaderPost] else {
            DDLogError("[ReaderStreamViewController tableView:didSelectRowAtIndexPath:] fetchedObjects was nil.")
            return
        }

        let apost = posts[indexPath.row]
        guard let post = postInMainContext(apost) else {
            return
        }

        //        if recentlyBlockedSitePostObjectIDs.contains(apost.objectID) {
        //            unblockSiteForPost(apost)
        //            return
        //        }

        if let topic = post.topic, ReaderHelpers.isTopicSearchTopic(topic) {
            WPAppAnalytics.track(.readerSearchResultTapped)

            // We can use `if let` when `ReaderPost` adopts nullability.
            let railcar = apost.railcarDictionary()
            if railcar != nil {
                WPAppAnalytics.trackTrainTracksInteraction(.readerSearchResultTapped, withProperties: railcar)
            }
        }

        var controller: ReaderDetailViewController
        if post.sourceAttributionStyle() == .post &&
            post.sourceAttribution.postID != nil &&
            post.sourceAttribution.blogID != nil {

            controller = ReaderDetailViewController.controllerWithPostID(post.sourceAttribution.postID!, siteID: post.sourceAttribution.blogID!)

        } else if post.isCross() {
            controller = ReaderDetailViewController.controllerWithPostID(post.crossPostMeta.postID, siteID: post.crossPostMeta.siteID)

        } else {
            controller = ReaderDetailViewController.controllerWithPost(post)

        }

        navigationController?.pushFullscreenViewController(controller, animated: true)

        tableView.deselectRow(at: indexPath, animated: false)
    }


    public func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // Do nothing
    }
}

extension ReaderSavedPostsViewController: ReaderPostCellDelegate {
    func readerCell(_ cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        HeaderAction().execute(post: post, origin: self)
    }

    func readerCell(_ cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        CommentAction().execute(post: post, origin: self)
    }

    func readerCell(_ cell: ReaderPostCardCell, followActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        toggleFollowingForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        toggleSavedForLater(for: post)
    }

    func readerCell(_ cell: ReaderPostCardCell, shareActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        guard let post = provider as? ReaderPost else {
            return
        }
        sharePost(post, fromView: sender)
    }

    func readerCell(_ cell: ReaderPostCardCell, visitActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        visitSiteForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        toggleLikeForPost(post)
    }

    func readerCell(_ cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {
        //TODO
        //TO BE IMPLEMENTED WHEN LOGGED IN FEATURES ARE ALLOWED
//        guard let post = provider as? ReaderPost else {
//            return
//        }
//
//        MenuAction(logged: isLoggedIn).execute(post: post, context: managedObjectContext(), readerTopic: readerTopic, anchor: sender, vc: self)
    }

    func readerCell(_ cell: ReaderPostCardCell, attributionActionForProvider provider: ReaderPostContentProvider) {
        guard let post = provider as? ReaderPost else {
            return
        }
        showAttributionForPost(post)
    }

    func readerCellImageRequestAuthToken(_ cell: ReaderPostCardCell) -> String? {
        //TODO
        //return imageRequestAuthToken
        return nil
    }

    fileprivate func toggleFollowingForPost(_ post: ReaderPost) {
        let siteTitle = post.blogNameForDisplay()
        let siteID = post.siteID
        let toFollow = !post.isFollowing

        FollowAction().execute(with: post, context: managedObjectContext()) { [weak self] in
            if toFollow {
                self?.dispatchSubscribingNotificationNotice(with: siteTitle, siteID: siteID)
            }
        }
    }

    fileprivate func toggleSavedForLater(for post: ReaderPost) {
        SaveForLaterAction(visibleConfirmation: false).execute(with: post, context: managedObjectContext())
    }

    fileprivate func visitSiteForPost(_ post: ReaderPost) {
        VisitSiteAction().execute(with: post, context: ContextManager.sharedInstance().mainContext, origin: self)
    }

    fileprivate func showAttributionForPost(_ post: ReaderPost) {
        ShowAttributionAction().execute(with: post, context: managedObjectContext(), origin: self)
    }


    fileprivate func toggleLikeForPost(_ post: ReaderPost) {
        LikeAction().execute(with: post, context: managedObjectContext())
    }

    fileprivate func sharePost(_ post: ReaderPost, fromView anchorView: UIView) {
        ShareAction().execute(with: post, context: managedObjectContext(), anchor: anchorView, vc: self)
    }

}
