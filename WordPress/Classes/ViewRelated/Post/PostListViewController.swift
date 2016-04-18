import Foundation
import WordPressComAnalytics
import WordPressShared

@objc class PostListViewController : AbstractPostListViewController, UIViewControllerRestoration, PostCardTableViewCellDelegate {
    
    static private let postCardTextCellIdentifier = "PostCardTextCellIdentifier"
    static private let postCardImageCellIdentifier = "PostCardImageCellIdentifier"
    static private let postCardRestoreCellIdentifier = "PostCardRestoreCellIdentifier"
    static private let postCardTextCellNibName = "PostCardTextCell"
    static private let postCardImageCellNibName = "PostCardImageCell"
    static private let postCardRestoreCellNibName = "RestorePostTableViewCell"
    static private let postsViewControllerRestorationKey = "PostsViewControllerRestorationKey"
    static private let statsStoryboardName = "SiteStats"
    static private let currentPostListStatusFilterKey = "CurrentPostListStatusFilterKey"
    static private let currentPostAuthorFilterKey = "CurrentPostAuthorFilterKey"
    
    // TODO: low cap on first char!
    
    static private let statsCacheInterval = NSTimeInterval(300) // 5 minutes
    static private let postCardEstimatedRowHeight = Float(100.0)
    static private let postCardRestoreCellRowHeight = Float(54.0)
    static private let postListHeightForFooterView = CGFloat(34.0)
    
    @IBOutlet var textCellForLayout : PostCardTableViewCell!
    @IBOutlet var imageCellForLayout : PostCardTableViewCell!
    @IBOutlet weak var authorFilterSegmentedControl : UISegmentedControl!
    
    // MARK: Initializers & deinitializers
    
    deinit {
        PrivateSiteURLProtocol.unregisterPrivateSiteURLProtocol()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        PrivateSiteURLProtocol.registerPrivateSiteURLProtocol()
    }
    
    // MARK: - Convenience constructors
    
    class func controllerWithBlog(blog: Blog) -> PostListViewController {
        
        let storyBoard = UIStoryboard(name: "Posts", bundle: NSBundle.mainBundle())
        let controller = storyBoard.instantiateViewControllerWithIdentifier("PostListViewController") as! PostListViewController
        
        controller.blog = blog
        controller.restorationClass = self

        return controller
    }
    
    // MARK: - UIViewControllerRestoration
    
    class func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        
        let context = ContextManager.sharedInstance().mainContext
        
        guard let blogID = coder.decodeObjectForKey(postsViewControllerRestorationKey) as? String,
            let objectURL = NSURL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(objectURL),
            let restoredBlog = try? context.existingObjectWithID(objectID) as! Blog else {
                
            return nil
        }
        
        return self.controllerWithBlog(restoredBlog)
    }
    
    // MARK: - UIStateRestoring
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        
        let objectString = blog?.objectID.URIRepresentation().absoluteString
        
        coder.encodeObject(objectString, forKey:self.dynamicType.postsViewControllerRestorationKey)
        
        super.encodeRestorableStateWithCoder(coder)
    }
    
    // MARK: - UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.postListViewController = (segue.destinationViewController as! UITableViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Posts", comment: "Tile of the screen showing the list of posts for a blog.")
    }
    
    // MARK: - UITraitEnvironment
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        forceUpdateCellLayout(textCellForLayout)
        forceUpdateCellLayout(imageCellForLayout)
        
        tableViewHandler?.clearCachedRowHeights()
        
        if let tableView = tableView,
            let indexPaths = tableView.indexPathsForVisibleRows {
            
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
        }
    }
    
    func forceUpdateCellLayout(cell: PostCardTableViewCell) {
        // Force a layout pass to ensure that constrants are configured for the
        // proper size class.
        view.addSubview(cell)
        cell.removeFromSuperview()
    }
    
    // MARK: - Configuration
    
    override func heightForFooterView() -> CGFloat {
        return self.dynamicType.postListHeightForFooterView
    }
    
    func configureCellsForLayout() {
        
        let bundle = NSBundle.mainBundle()
        
        textCellForLayout = bundle.loadNibNamed(self.dynamicType.postCardTextCellNibName, owner: nil, options: nil)[0] as! PostCardTableViewCell
        forceUpdateCellLayout(textCellForLayout)
        
        imageCellForLayout = bundle.loadNibNamed(self.dynamicType.postCardImageCellNibName, owner: nil, options: nil)[0] as! PostCardTableViewCell
        forceUpdateCellLayout(imageCellForLayout)
    }
    
    func configureTableView() {
        
        assert(tableView != nil, "We expect tableView to never be nil at this point.")
        
        guard let tableView = tableView else {
            return
        }
        
        tableView.accessibilityIdentifier = "PostsTable"
        tableView.isAccessibilityElement = true
        tableView.separatorStyle = .None
        
        let bundle = NSBundle.mainBundle()
        
        // Register the cells
        let postCardTextCellNib = UINib(nibName: self.dynamicType.postCardTextCellNibName, bundle: bundle)
        tableView.registerNib(postCardTextCellNib, forCellReuseIdentifier: self.dynamicType.postCardTextCellIdentifier)
        
        let postCardImageCellNib = UINib(nibName: self.dynamicType.postCardImageCellNibName, bundle: bundle)
        tableView.registerNib(postCardImageCellNib, forCellReuseIdentifier: self.dynamicType.postCardImageCellIdentifier)
        
        let postCardRestoreCellNib = UINib(nibName: self.dynamicType.postCardRestoreCellNibName, bundle: bundle)
        tableView.registerNib(postCardRestoreCellNib, forCellReuseIdentifier: self.dynamicType.postCardRestoreCellIdentifier)
    }
    
    func noResultsTitleText() -> String {
        if syncHelper?.isSyncing == true {
            return NSLocalizedString("Fetching posts...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.");
        }
        
        let filter = currentPostListFilter()
        
        if let filter = filter {
            let titles = noResultsTitles()
            let title = titles[filter.filterType]
            return title ?? ""
        } else {
            return ""
        }
    }
    
    func noResultsTitles() -> [PostListStatusFilter:String] {
        if isSearching() {
            return noResultsTitlesWhenSearching()
        } else {
            return noResultsTitlesWhenFiltering()
        }
    }
    
    func noResultsTitlesWhenSearching() -> [PostListStatusFilter:String] {
        
        let draftMessage = String(format: NSLocalizedString("No drafts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let scheduledMessage = String(format: NSLocalizedString("No scheduled posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let trashedMessage = String(format: NSLocalizedString("No trashed posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let publishedMessage = String(format: NSLocalizedString("No posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        
        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }
    
    func noResultsTitlesWhenFiltering() -> [PostListStatusFilter:String] {
        
        let draftMessage = String(format: NSLocalizedString("No drafts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let scheduledMessage = String(format: NSLocalizedString("No scheduled posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let trashedMessage = String(format: NSLocalizedString("No trashed posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let publishedMessage = String(format: NSLocalizedString("No posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        
        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }
    
    func noResultsTitles(draft: String, scheduled: String, trashed: String, published: String) -> [PostListStatusFilter:String] {
        return [.Draft: draft,
                .Scheduled: scheduled,
                .Trashed: trashed,
                .Published: published]
    }
    
    func noResultsMessageText() -> String {
        if syncHelper?.isSyncing == true || isSearching() {
            return ""
        }
        
        let filter = currentPostListFilter()
        
        // currentPostListFilter() may return `nil` at this time (ie: it's been declared as
        // `nullable`).  This will probably change once we can migrate
        // AbstractPostListViewController to Swift, but for the time being we're defining a default
        // filter here.
        //
        // Diego Rey Mendez - 2016/04/18
        //
        let filterType = filter?.filterType ?? .Draft
        var message : String
        
        switch filterType {
        case .Draft:
            message = NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views drafts in the posts list and there are no posts")
            break
        case .Scheduled:
            message = NSLocalizedString("Would you like to schedule a draft to publish?", comment: "Displayed when the user views scheduled posts in the posts list and there are no posts")
            break
        case .Trashed:
            message = NSLocalizedString("Everything you write is solid gold.", comment: "Displayed when the user views trashed posts in the posts list and there are no posts")
            break
        default:
            message = NSLocalizedString("Would you like to publish your first post?", comment: "Displayed when the user views published posts in the posts list and there are no posts")
            break
        }
        
        return message
    }
    
    func noResultsButtonText() -> String? {
        if syncHelper?.isSyncing == true || isSearching() {
            return nil
        }
        
        let filter = currentPostListFilter()
        
        // currentPostListFilter() may return `nil` at this time (ie: it's been declared as
        // `nullable`).  This will probably change once we can migrate
        // AbstractPostListViewController to Swift, but for the time being we're defining a default
        // filter here.
        //
        // Diego Rey Mendez - 2016/04/18
        //
        let filterType = filter?.filterType ?? .Draft
        var title : String
        
        switch filterType {
        case .Scheduled:
            title = NSLocalizedString("Edit Drafts", comment: "Button title, encourages users to schedule a draft post to publish.")
            break
        case .Trashed:
            title = ""
            break
        default:
            title = NSLocalizedString("Start a Post", comment: "Button title, encourages users to create their first post on their blog.")
            break
        }
        
        return title
    }
    
    func configureAuthorFilter() {
        let onlyMe = NSLocalizedString("Only Me", comment: "Label for the post author filter. This fliter shows posts only authored by the current user.")
        let everyone = NSLocalizedString("Everyone", comment: "Label for the post author filter. This filter shows posts for all users on the blog.")
        
        WPStyleGuide.applyPostAuthorFilterStyle(authorFilterSegmentedControl)
        
        authorFilterSegmentedControl.setTitle(onlyMe, forSegmentAtIndex: 0)
        authorFilterSegmentedControl.setTitle(everyone, forSegmentAtIndex: 1)
    
        authorsFilterView?.backgroundColor = WPStyleGuide.lightGrey()
        
        if !canFilterByAuthor() {
            authorsFilterViewHeightConstraint?.constant = 0
            authorFilterSegmentedControl.hidden = true
        }
        
        if currentPostAuthorFilter() == .Mine {
            authorFilterSegmentedControl.selectedSegmentIndex = 0
        } else {
            authorFilterSegmentedControl.selectedSegmentIndex = 1
        }
    }
    
    // MARK: - Sync Methods
    
    override func postTypeToSync() -> String {
        return PostServiceTypePost
    }
    
    override func lastSyncDate() -> NSDate? {
        return blog?.lastPostsSync
    }
    
    // MARK: - Actions
    
    @IBAction func handleAuthorFilterChanged() {
        if authorFilterSegmentedControl.selectedSegmentIndex == (Int) (PostAuthorFilter.Mine.rawValue) {
            setCurrentPostAuthorFilter(.Mine)
        } else {
            setCurrentPostAuthorFilter(.Everyone)
        }
    }
    
    // MARK: - TableViewHandler
    
    func entityName() -> String {
        return NSStringFromClass(self.dynamicType)
    }
    
    func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()
        
        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
            predicates.append(basePredicate)
        }
        
        let typePredicate = NSPredicate(format: "postType = %@", postTypeToSync())
        predicates.append(typePredicate)
        
        let searchText = currentSearchTerm()
        var filterPredicate = currentPostListFilter()?.predicateForFetchRequest
        
        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
        // or posts that were recently deleted.
        if let recentlyTrashedPostObjectIDs = recentlyTrashedPostObjectIDs
            where searchText?.characters.count == 0 && recentlyTrashedPostObjectIDs.count > 0 {
            
            let trashedPredicate = NSPredicate(format: "SELF IN %@", recentlyTrashedPostObjectIDs)
            
            if let originalFilterPredicate = filterPredicate {
                filterPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [originalFilterPredicate, trashedPredicate])
            } else {
                filterPredicate = trashedPredicate
            }
        }
        
        if let filterPredicate = filterPredicate {
            predicates.append(filterPredicate)
        }
        
        if shouldShowOnlyMyPosts() {
            let myAuthorID = blog?.account.userID ?? 0
            
            // Brand new local drafts have an authorID of 0.
            let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
            predicates.append(authorPredicate)
        }
        
        if let searchText = searchText where searchText.characters.count > 0 {
            let searchPredicate = NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText)
            predicates.append(searchPredicate)
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }
    
    // MARK: - Table View Handling
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) as! Post
        
        if cellIdentifierForPost(post) == self.dynamicType.postCardRestoreCellIdentifier {
            return CGFloat(self.dynamicType.postCardRestoreCellRowHeight)
        }
        
        return CGFloat(self.dynamicType.postCardEstimatedRowHeight)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let width = CGRectGetWidth(tableView.bounds)
        return tableView(tableView, heightForRowAtIndexPath: indexPath, forWidth: width)
    }
   
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath, forWidth width: CGFloat) -> CGFloat {
        let post = tableViewHandler?.resultsController.objectAtIndexPath(indexPath)
        
        if cellIdentifierForPost(post) == self.dynamicType.postCardRestoreCellIdentifier {
            return CGFloat(self.dynamicType.postCardRestoreCellRowHeight)
        }
        
        var cell : PostCardTableViewCell!
        
        if post?.pathForDisplayImage.characters.count > 0 {
            cell = textCellForLayout
        } else {
            cell = imageCellForLayout
        }
        
        configureCell(cell, atIndexPath: indexPath)
        let size = cell.sizeThatFits(CGSizeMake(width, CGFloat.max))
        let height = ceil(size.height)
        
        return height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let post = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) else {
            return
        }

        if post.remoteStatus == AbstractPostRemoteStatusPushing {
            // Don't allow editing while pushing changes
            return
        }
        
        if post.status == PostStatusTrash {
            // No editing posts that are trashed.
            return
        }
        
        previewEditPost(post)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let post = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) as! Post
        
        let identifier = cellIdentifierForPost(post)
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        cell.accessoryType = .None
        cell.selectionStyle = .None
        
        if let postCell = cell as? PostCardCell {
            postCell.delegate = self
            
            if let post = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) as? WPPostContentViewProvider {
                let layoutOnly = (cell == imageCellForLayout) || (cell == textCellForLayout)
                
                postCell.configureCell?(post, layoutOnly: layoutOnly)
            }
        }
    }
    
    func cellIdentifierForPost(post: Post) -> String {
        var identifier : String
        
        if recentlyTrashedPostObjectIDs?.containsObject(post.objectID) == true && currentPostListFilter()?.filterType != .Trashed {
            identifier = self.dynamicType.postCardRestoreCellIdentifier
        } else if post.pathForDisplayImage.characters.count > 0 {
            identifier = self.dynamicType.postCardTextCellIdentifier
        } else {
            identifier = self.dynamicType.postCardImageCellIdentifier
        }
        
        return identifier
    }
    
    // MARK: - Post Actions
    
    func createPost() {
        if WPPostViewController.isNewEditorEnabled() {
            createPostInNewEditor()
        } else {
            createPostInOldEditor()
        }
    }
    
    func createPostInNewEditor() {
        let postViewController = WPPostViewController(draftForBlog: blog)
        
        postViewController.onClose = { [weak self] (viewController, changesSaved) -> () in
            if changesSaved {
                self?.setFilterWithPostStatus(viewController.post.status)
            }
            
            viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let navController = UINavigationController(rootViewController: postViewController)
        navController.restorationIdentifier = WPEditorNavigationRestorationID
        navController.restorationClass = WPPostViewController.self
        navController.toolbarHidden = false
        navController.modalPresentationStyle = .FullScreen
        
        presentViewController(navController, animated: true, completion: nil)
        
        WPAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
    }
    
    func createPostInOldEditor() {
        let editPostViewController = WPLegacyEditPostViewController(draftForLastUsedBlog: ())
        
        let navController = UINavigationController(rootViewController: editPostViewController)
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID
        navController.restorationClass = WPLegacyEditPostViewController.self
        navController.toolbarHidden = false
        navController.modalPresentationStyle = .FullScreen
        
        presentViewController(navController, animated: true, completion: nil)
        
        WPAnalytics.track(.EditorCreatedPost, withProperties: ["tap_source": "posts_view"], withBlog: blog)
    }
    
    func previewEditPost(apost: AbstractPost) {
        editPost(apost, withEditMode: kWPPostViewControllerModePreview)
    }
    
    func editPost(apost: AbstractPost) {
        editPost(apost, withEditMode: kWPPostViewControllerModeEdit)
    }
    
    func editPost(apost: AbstractPost, withEditMode mode: WPPostViewControllerMode) {
        WPAnalytics.track(.PostListEditAction, withProperties: propertiesForAnalytics())
        
        if WPPostViewController.isNewEditorEnabled() {
            let postViewController = WPPostViewController(post: apost, mode: mode)
            
            postViewController.onClose = {[weak self] viewController, changesSaved in
                
                if changesSaved {
                    self?.setFilterWithPostStatus(viewController.post.status)
                }
                
                viewController.navigationController?.popViewControllerAnimated(true)
            }
            
            postViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(postViewController, animated: true)
        } else {
            // In legacy mode, view means edit
            let editPostViewController = WPLegacyEditPostViewController(post: apost)
            let navController = UINavigationController(rootViewController: editPostViewController)
            navController.toolbarHidden = false // Fixes incorrect toolbar animation.
            navController.modalPresentationStyle = .FullScreen
            navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID
            navController.restorationClass = WPLegacyEditPostViewController.self
            
            presentViewController(navController, animated: true, completion: nil)
        }
    }
    
    func promptThatPostRestoredToFilter(filter: PostListFilter) {
        
    }
    
}

/*
 
 - (void)promptThatPostRestoredToFilter:(PostListFilter *)filter
 {
 NSString *message = NSLocalizedString(@"Post Restored to Drafts", @"Prompts the user that a restored post was moved to the drafts list.");
 switch (filter.filterType) {
 case PostListStatusFilterPublished:
 message = NSLocalizedString(@"Post Restored to Published", @"Prompts the user that a restored post was moved to the published list.");
 break;
 case PostListStatusFilterScheduled:
 message = NSLocalizedString(@"Post Restored to Scheduled", @"Prompts the user that a restored post was moved to the scheduled list.");
 break;
 default:
 break;
 }
 NSString *alertCancel = NSLocalizedString(@"OK", @"Title of an OK button. Pressing the button acknowledges and dismisses a prompt.");
 
 UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
 [alertController addCancelActionWithTitle:alertCancel handler:nil];
 [alertController presentFromRootViewController];
 }
 
 - (void)viewStatsForPost:(AbstractPost *)apost
 {
 // Check the blog
 Blog *blog = apost.blog;
 if (![blog supports:BlogFeatureStats]) {
 // Needs Jetpack.
 return;
 }
 
 [WPAnalytics track:WPAnalyticsStatPostListStatsAction withProperties:[self propertiesForAnalytics]];
 
 // Push the Stats Post Details ViewController
 NSString *identifier = NSStringFromClass([StatsPostDetailsTableViewController class]);
 BlogService *service = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
 NSBundle *statsBundle = [NSBundle bundleForClass:[WPStatsViewController class]];
 NSString *path = [statsBundle pathForResource:@"WordPressCom-Stats-iOS" ofType:@"bundle"];
 NSBundle *bundle = [NSBundle bundleWithPath:path];
 UIStoryboard *statsStoryboard   = [UIStoryboard storyboardWithName:StatsStoryboardName bundle:bundle];
 StatsPostDetailsTableViewController *controller = [statsStoryboard instantiateViewControllerWithIdentifier:identifier];
 NSAssert(controller, @"Couldn't instantiate StatsPostDetailsTableViewController");
 
 controller.postID = apost.postID;
 controller.postTitle = [apost titleForDisplay];
 controller.statsService = [[WPStatsService alloc] initWithSiteId:blog.dotComID
 siteTimeZone:[service timeZoneForBlog:blog]
 oauth2Token:blog.authToken
 andCacheExpirationInterval:StatsCacheInterval];
 
 [self.navigationController pushViewController:controller animated:YES];
 }
 
 
 #pragma mark - Filter related
 
 - (PostAuthorFilter)currentPostAuthorFilter
 {
 if (![self canFilterByAuthor]) {
 // No REST API, so we have to use XMLRPC and can't filter results by author.
 return PostAuthorFilterEveryone;
 }
 
 NSNumber *filter = [[NSUserDefaults standardUserDefaults] objectForKey:CurrentPostAuthorFilterKey];
 if (filter) {
 if (PostAuthorFilterEveryone == [filter integerValue]) {
 return PostAuthorFilterEveryone;
 }
 }
 
 return PostAuthorFilterMine;
 }
 
 - (void)setCurrentPostAuthorFilter:(PostAuthorFilter)filter
 {
 if (filter == [self currentPostAuthorFilter]) {
 return;
 }
 
 [WPAnalytics track:WPAnalyticsStatPostListAuthorFilterChanged withProperties:[self propertiesForAnalytics]];
 
 [[NSUserDefaults standardUserDefaults] setObject:@(filter) forKey:CurrentPostAuthorFilterKey];
 [NSUserDefaults resetStandardUserDefaults];
 
 [self.recentlyTrashedPostObjectIDs removeAllObjects];
 [self resetTableViewContentOffset];
 [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
 [self syncItemsWithUserInteraction:NO];
 }
 
 - (NSString *)keyForCurrentListStatusFilter
 {
 return CurrentPostListStatusFilterKey;
 }
 
 
 #pragma mark - Cell Delegate Methods
 
 - (void)cell:(PostCardTableViewCell *)cell receivedEditActionForProvider:(id<WPPostContentViewProvider>)contentProvider
 {
 AbstractPost *apost = (AbstractPost *)contentProvider;
 [self editPost:apost];
 }
 
 - (void)cell:(PostCardTableViewCell *)cell receivedViewActionForProvider:(id<WPPostContentViewProvider>)contentProvider
 {
 AbstractPost *apost = (AbstractPost *)contentProvider;
 [self viewPost:apost];
 }
 
 - (void)cell:(PostCardTableViewCell *)cell receivedStatsActionForProvider:(id<WPPostContentViewProvider>)contentProvider
 {
 AbstractPost *apost = (AbstractPost *)contentProvider;
 [self viewStatsForPost:apost];
 }
 
 - (void)cell:(PostCardTableViewCell *)cell receivedPublishActionForProvider:(id<WPPostContentViewProvider>)contentProvider
 {
 AbstractPost *apost = (AbstractPost *)contentProvider;
 [self publishPost:apost];
 }
 
 - (void)cell:(PostCardTableViewCell *)cell receivedTrashActionForProvider:(id<WPPostContentViewProvider>)contentProvider
 {
 AbstractPost *apost = (AbstractPost *)contentProvider;
 [self deletePost:apost];
 }
 
 - (void)cell:(PostCardTableViewCell *)cell receivedRestoreActionForProvider:(id<WPPostContentViewProvider>)contentProvider
 {
 AbstractPost *apost = (AbstractPost *)contentProvider;
 [self restorePost:apost];
 }
 */





