import UIKit
import Gridicons
import WordPressShared
import WordPressUI

final class ReaderSavedPostsViewController: UITableViewController {
    private enum Strings {
        static let title = NSLocalizedString("Saved Posts", comment: "Title for list of posts saved for later")
    }

    private enum UndoCell {
        static let nibName = "ReaderSavedPostUndoCell"
        static let reuseIdentifier = "ReaderUndoCellReuseIdentifier"
        static let height: CGFloat = 44
    }

    fileprivate var noResultsView: WPNoResultsView!
    fileprivate var footerView: PostListFooterView!
    fileprivate let heightForFooterView = CGFloat(34.0)
    fileprivate let estimatedHeightsCache = NSCache<AnyObject, AnyObject>()

    /// Content management
    private let content = ReaderTableContent()
    /// Configuration of table view and registration of cells
    private let tableConfiguration = ReaderTableConfiguration()
    /// Configuration of cells
    private let cellConfiguration = ReaderCellConfiguration()
    /// Actions
    private var postCellActions: ReaderSavedPostCellActions?

    fileprivate lazy var displayContext: NSManagedObjectContext = ContextManager.sharedInstance().newMainContextChildContext()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title

        setupTableView()
        setupFooterView()
        setupNoResultsView()
        setupContentHandler()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        updateAndPerformFetchRequest()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        centerResultsStatusViewIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshNoResultsView()
    }

    deinit {
        postCellActions?.clearRemovedPosts()
    }

    func centerResultsStatusViewIfNeeded() {
        if noResultsView.isDescendant(of: tableView) {
            noResultsView.centerInSuperview()
        }
    }

    // MARK: - Setup

    fileprivate func setupTableView() {
        tableConfiguration.setup(tableView)
        setupUndoCell(tableView)
    }

    private func setupUndoCell(_ tableView: UITableView) {
        let nib = UINib(nibName: UndoCell.nibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: UndoCell.reuseIdentifier)
    }

    func undoCell(_ tableView: UITableView) -> ReaderSavedPostUndoCell {
        return tableView.dequeueReusableCell(withIdentifier: UndoCell.reuseIdentifier) as! ReaderSavedPostUndoCell
    }

    fileprivate func setupContentHandler() {
        content.initializeContent(tableView: tableView, delegate: self)
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


    @objc public func configurePostCardCell(_ cell: UITableViewCell, post: ReaderPost) {
        if postCellActions == nil {
            postCellActions = ReaderSavedPostCellActions(context: managedObjectContext(), origin: self, topic: post.topic, visibleConfirmation: false)
            postCellActions?.delegate = self
        }

        cellConfiguration.configurePostCardCell(cell,
                                                withPost: post,
                                                topic: post.topic,
                                                delegate: postCellActions,
                                                loggedInActionVisibility: .hidden)
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
        refreshNoResultsView()
    }

    private func refreshNoResultsView() {
        if content.isEmpty {
            displayNoResultsView()
        } else {
            hideNoResultsView()
        }
    }

    private func displayNoResultsView() {
        if !noResultsView.isDescendant(of: tableView) {
            tableView.addSubview(withFadeAnimation: noResultsView)
            noResultsView.translatesAutoresizingMaskIntoConstraints = false
            tableView.pinSubviewAtCenter(noResultsView)
        }

        configureNoResultsText()

        noResultsView.isUserInteractionEnabled = false
        noResultsView.accessoryView = nil
    }

    private func configureNoResultsText() {
        noResultsView.titleText = NSLocalizedString("No posts saved – yet!", comment: "Message displayed in Reader Saved Posts view if a user hasn't yet saved any posts.")

        var messageText = NSMutableAttributedString(string: NSLocalizedString("Tap [bookmark-outline] to save a post to your list.", comment: "A hint displayed in the Saved Posts section of the Reader. The '[bookmark-outline]' placeholder will be replaced by an icon at runtime – please leave that string intact."))

        // We're setting this once here so that the attributed text
        // gets the correct font attributes added to it. The font
        // is used by the attributed string `replace(_:with:)` method
        // below to correctly position the icon.
        noResultsView.attributedMessageText = messageText
        messageText = NSMutableAttributedString(attributedString: noResultsView.attributedMessageText)

        let icon = Gridicon.iconOfType(.bookmarkOutline, withSize: CGSize(width: 18, height: 18))
        messageText.replace("[bookmark-outline]", with: icon)
        noResultsView.attributedMessageText = messageText

        noResultsView.accessibilityLabel = NSLocalizedString("No posts saved – yet! Tap the Save Post button to save a post to your list.", comment: "Alternative accessibility text displayed to Voiceover users on the Reader Saved Posts screen.")
    }

    @objc func hideNoResultsView() {
        noResultsView.removeFromSuperview()
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
        guard let posts = content.content as? [ReaderPost] else {
            DDLogError("[ReaderStreamViewController tableView:cellForRowAtIndexPath:] fetchedObjects was nil.")
            return UITableViewCell()
        }
        let post = posts[indexPath.row]

        if post.isCross() {
            let cell = tableConfiguration.crossPostCell(tableView)
            cellConfiguration.configureCrossPostCell(cell,
                                                     withContent: content,
                                                     atIndexPath: indexPath)
            return cell
        }


        if postCellActions?.postIsRemoved(post) == true {
            let cell = undoCell(tableView)
            configureUndoCell(cell, with: post)
            return cell
        }

        let cell = tableConfiguration.postCardCell(tableView)
        configurePostCardCell(cell, post: post)
        return cell
    }

    private func configureUndoCell(_ cell: ReaderSavedPostUndoCell, with post: ReaderPost) {
        cell.title.text = post.titleForDisplay()
        cell.delegate = self
    }

    override public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Cache the cell's layout height as the currently known height, for estimation.
        // See estimatedHeightForRowAtIndexPath
        estimatedHeightsCache.setObject(cell.frame.height as AnyObject, forKey: indexPath as AnyObject)

        guard cell.isKind(of: ReaderPostCardCell.self) || cell.isKind(of: ReaderCrossPostCell.self) else {
            return
        }

        guard let posts = content.content as? [ReaderPost] else {
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
        guard let posts = content.content as? [ReaderPost] else {
            DDLogError("[ReaderStreamViewController tableView:didSelectRowAtIndexPath:] fetchedObjects was nil.")
            return
        }

        let apost = posts[indexPath.row]
        guard let post = postInMainContext(apost) else {
            return
        }

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

        trackSavedPostNavigation()

        navigationController?.pushFullscreenViewController(controller, animated: true)

        tableView.deselectRow(at: indexPath, animated: false)
    }


    public func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // Do nothing
    }
}

extension ReaderSavedPostsViewController: ReaderSavedPostCellActionsDelegate {
    func willRemove(_ cell: ReaderPostCardCell) {
        if let cellIndex = tableView.indexPath(for: cell) {
            tableView.reloadRows(at: [cellIndex], with: .fade)
        }
    }
}

extension ReaderSavedPostsViewController: ReaderPostUndoCellDelegate {
    func readerCellWillUndo(_ cell: ReaderSavedPostUndoCell) {
        if let cellIndex = tableView.indexPath(for: cell),
            let post: ReaderPost = content.object(at: cellIndex) {
                postCellActions?.restoreUnsavedPost(post)
                tableView.reloadRows(at: [cellIndex], with: .fade)
        }
    }
}
