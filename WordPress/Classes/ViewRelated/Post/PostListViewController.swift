/*

#pragma mark - Lifecycle Methods


#pragma mark - Configuration

- (CGFloat)heightForFooterView
{
    return PostListHeightForFooterView;
    }
    
    - (void)configureCellsForLayout
        {
            self.textCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardTextCellNibName owner:nil options:nil] firstObject];
            [self forceUpdateCellLayout:self.textCellForLayout];
            
            self.imageCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardImageCellNibName owner:nil options:nil] firstObject];
            [self forceUpdateCellLayout:self.imageCellForLayout];
        }
        

    
    - (void)configureTableView
        {
            self.tableView.accessibilityIdentifier = @"PostsTable";
            self.tableView.isAccessibilityElement = YES;
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            
            // Register the cells
            UINib *postCardTextCellNib = [UINib nibWithNibName:PostCardTextCellNibName bundle:[NSBundle mainBundle]];
            [self.tableView registerNib:postCardTextCellNib forCellReuseIdentifier:PostCardTextCellIdentifier];
            
            UINib *postCardImageCellNib = [UINib nibWithNibName:PostCardImageCellNibName bundle:[NSBundle mainBundle]];
            [self.tableView registerNib:postCardImageCellNib forCellReuseIdentifier:PostCardImageCellIdentifier];
            
            UINib *postCardRestoreCellNib = [UINib nibWithNibName:PostCardRestoreCellNibName bundle:[NSBundle mainBundle]];
            [self.tableView registerNib:postCardRestoreCellNib forCellReuseIdentifier:PostCardRestoreCellIdentifier];
        }
        
        - (NSString *)noResultsTitleText
            {
                if (self.syncHelper.isSyncing) {
                    return NSLocalizedString(@"Fetching posts...", @"A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.");
                }
                PostListFilter *filter = [self currentPostListFilter];
                NSDictionary *titles = [self noResultsTitles];
                NSString *title = [titles stringForKey:@(filter.filterType)];
                return title;
            }
            
            - (NSDictionary *)noResultsTitles
                {
                    NSDictionary *titles;
                    if ([self isSearching]) {
                        titles = @{
                            @(PostListStatusFilterDraft):[NSString stringWithFormat:NSLocalizedString(@"No drafts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                            @(PostListStatusFilterScheduled):[NSString stringWithFormat:NSLocalizedString(@"No scheduled posts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                            @(PostListStatusFilterTrashed):[NSString stringWithFormat:NSLocalizedString(@"No trashed posts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                            @(PostListStatusFilterPublished):[NSString stringWithFormat:NSLocalizedString(@"No posts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                        };
                    } else {
                        titles = @{
                            @(PostListStatusFilterDraft):NSLocalizedString(@"You don't have any drafts.", @"Displayed when the user views drafts in the posts list and there are no posts"),
                            @(PostListStatusFilterScheduled):NSLocalizedString(@"You don't have any scheduled posts.", @"Displayed when the user views scheduled posts in the posts list and there are no posts"),
                            @(PostListStatusFilterTrashed):NSLocalizedString(@"You don't have any posts in your trash folder.", @"Displayed when the user views trashed in the posts list and there are no posts"),
                            @(PostListStatusFilterPublished):NSLocalizedString(@"You haven't published any posts yet.", @"Displayed when the user views published posts in the posts list and there are no posts"),
                        };
                    }
                    return titles;
                }
                
                - (NSString *)noResultsMessageText {
                    if (self.syncHelper.isSyncing || [self isSearching]) {
                        return [NSString string];
                    }
                    NSString *message;
                    PostListFilter *filter = [self currentPostListFilter];
                    switch (filter.filterType) {
                    case PostListStatusFilterDraft:
                        message = NSLocalizedString(@"Would you like to create one?", @"Displayed when the user views drafts in the posts list and there are no posts");
                        break;
                    case PostListStatusFilterScheduled:
                        message = NSLocalizedString(@"Would you like to schedule a draft to publish?", @"Displayed when the user views scheduled posts in the posts list and there are no posts");
                        break;
                    case PostListStatusFilterTrashed:
                        message = NSLocalizedString(@"Everything you write is solid gold.", @"Displayed when the user views trashed posts in the posts list and there are no posts");
                        break;
                    default:
                        message = NSLocalizedString(@"Would you like to publish your first post?", @"Displayed when the user views published posts in the posts list and there are no posts");
                        break;
                    }
                    return message;
                    }
                    
                    - (NSString *)noResultsButtonText
                        {
                            if (self.syncHelper.isSyncing || [self isSearching]) {
                                return nil;
                            }
                            NSString *title;
                            PostListFilter *filter = [self currentPostListFilter];
                            switch (filter.filterType) {
                            case PostListStatusFilterScheduled:
                                title = NSLocalizedString(@"Edit Drafts", @"Button title, encourages users to schedule a draft post to publish.");
                                break;
                            case PostListStatusFilterTrashed:
                                title = [NSString string];
                                break;
                            default:
                                title = NSLocalizedString(@"Start a Post", @"Button title, encourages users to create their first post on their blog.");
                                break;
                            }
                            return title;
                        }
                        
                        - (void)configureAuthorFilter
                            {
                                NSString *onlyMe = NSLocalizedString(@"Only Me", @"Label for the post author filter. This fliter shows posts only authored by the current user.");
                                NSString *everyone = NSLocalizedString(@"Everyone", @"Label for the post author filter. This filter shows posts for all users on the blog.");
                                [WPStyleGuide applyPostAuthorFilterStyle:self.authorFilterSegmentedControl];
                                [self.authorFilterSegmentedControl setTitle:onlyMe forSegmentAtIndex:0];
                                [self.authorFilterSegmentedControl setTitle:everyone forSegmentAtIndex:1];
                                self.authorsFilterView.backgroundColor = [WPStyleGuide lightGrey];
                                
                                if (![self canFilterByAuthor]) {
                                    self.authorsFilterViewHeightConstraint.constant = 0.0;
                                    self.authorFilterSegmentedControl.hidden = YES;
                                }
                                
                                if ([self currentPostAuthorFilter] == PostAuthorFilterMine) {
                                    self.authorFilterSegmentedControl.selectedSegmentIndex = 0;
                                } else {
                                    self.authorFilterSegmentedControl.selectedSegmentIndex = 1;
                                }
}


#pragma mark - Sync Methods

- (NSString *)postTypeToSync
{
    return PostServiceTypePost;
    }
    
    - (NSDate *)lastSyncDate
        {
            return self.blog.lastPostsSync;
}


#pragma mark - Actions

- (IBAction)handleAuthorFilterChanged:(id)sender
{
    if (self.authorFilterSegmentedControl.selectedSegmentIndex == PostAuthorFilterMine) {
        [self setCurrentPostAuthorFilter:PostAuthorFilterMine];
    } else {
        [self setCurrentPostAuthorFilter:PostAuthorFilterEveryone];
    }
}


#pragma mark - TableView Handler Delegate Methods

- (NSString *)entityName
{
    return NSStringFromClass([Post class]);
    }
    
    - (NSPredicate *)predicateForFetchRequest
        {
            NSMutableArray *predicates = [NSMutableArray array];
            
            NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"blog = %@ && revision = nil", self.blog];
            [predicates addObject:basePredicate];
            
            NSPredicate *typePredicate = [NSPredicate predicateWithFormat:@"postType = %@", [self postTypeToSync]];
            [predicates addObject:typePredicate];
            
            NSString *searchText = [self currentSearchTerm];
            NSPredicate *filterPredicate = [self currentPostListFilter].predicateForFetchRequest;
            
            // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
            // or posts that were recently deleted.
            if ([searchText length] == 0 && [self.recentlyTrashedPostObjectIDs count] > 0) {
                NSPredicate *trashedPredicate = [NSPredicate predicateWithFormat:@"SELF IN %@", self.recentlyTrashedPostObjectIDs];
                filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[filterPredicate, trashedPredicate]];
            }
            [predicates addObject:filterPredicate];
            
            if ([self shouldShowOnlyMyPosts]) {
                // Brand new local drafts have an authorID of 0.
                NSPredicate *authorPredicate = [NSPredicate predicateWithFormat:@"authorID = %@ || authorID = 0", self.blog.account.userID];
                [predicates addObject:authorPredicate];
            }
            
            if ([searchText length] > 0) {
                NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"postTitle CONTAINS[cd] %@", searchText];
                [predicates addObject:searchPredicate];
            }
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
            
            return predicate;
}

#pragma mark - Table View Handling

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([[self cellIdentifierForPost:post] isEqualToString:PostCardRestoreCellIdentifier]) {
        return PostCardRestoreCellRowHeight;
    }
    
    return PostCardEstimatedRowHeight;
    }
    
    - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
    }
    
    - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([[self cellIdentifierForPost:post] isEqualToString:PostCardRestoreCellIdentifier]) {
        return PostCardRestoreCellRowHeight;
    }
    
    PostCardTableViewCell *cell;
    if (![post.pathForDisplayImage length]) {
        cell = self.textCellForLayout;
    } else {
        cell = self.imageCellForLayout;
    }
    [self configureCell:cell atIndexPath:indexPath];
    CGSize size = [cell sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
    }
    
    - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AbstractPost *post = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
        // Don't allow editing while pushing changes
        return;
    }
    
    if ([post.status isEqualToString:PostStatusTrash]) {
        // No editing posts that are trashed.
        return;
    }
    
    [self previewEditPost:post];
    }
    
    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    
    NSString *identifier = [self cellIdentifierForPost:post];
    PostCardTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
    }
    
    - (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    id<PostCardCell>postCell = (id<PostCardCell>)cell;
    postCell.delegate = self;
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    
    BOOL layoutOnly = ([cell isEqual:self.imageCellForLayout] || [cell isEqual:self.textCellForLayout]);
    [postCell configureCell:post layoutOnly:layoutOnly];
    }
    
    - (NSString *)cellIdentifierForPost:(Post *)post
{
    NSString *identifier;
    if ([self.recentlyTrashedPostObjectIDs containsObject:post.objectID] && [self currentPostListFilter].filterType != PostListStatusFilterTrashed) {
        identifier = PostCardRestoreCellIdentifier;
    } else if (![post.pathForDisplayImage length]) {
        identifier = PostCardTextCellIdentifier;
    } else {
        identifier = PostCardImageCellIdentifier;
    }
    return identifier;
}


#pragma mark - Instance Methods

#pragma mark - Post Actions

- (void)createPost
{
    if ([WPPostViewController isNewEditorEnabled]) {
        [self createPostInNewEditor];
    } else {
        [self createPostInOldEditor];
    }
    }
    
    - (void)createPostInNewEditor
        {
            WPPostViewController *postViewController = [[WPPostViewController alloc] initWithDraftForBlog:self.blog];
            
            __weak __typeof(self) weakSelf = self;
            
            postViewController.onClose = ^void(WPPostViewController *viewController, BOOL changesSaved) {
                
                if (changesSaved) {
                    [weakSelf setFilterWithPostStatus:viewController.post.status];
                }
                
                [viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            };
            
            UINavigationController* __nonnull navController = [[UINavigationController alloc] initWithRootViewController:postViewController];
            navController.restorationIdentifier = WPEditorNavigationRestorationID;
            navController.restorationClass = [WPPostViewController class];
            
            [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [self presentViewController:navController animated:YES completion:nil];
            
            [WPAppAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{@"tap_source": @"posts_view"} withBlog:self.blog];
        }
        
        - (void)createPostInOldEditor
            {
                WPLegacyEditPostViewController *editPostViewController = [[WPLegacyEditPostViewController alloc] initWithDraftForLastUsedBlog];
                UINavigationController* __nonnull navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
                navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
                navController.restorationClass = [WPLegacyEditPostViewController class];
                
                [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
                navController.modalPresentationStyle = UIModalPresentationFullScreen;
                
                [self presentViewController:navController animated:YES completion:nil];
                
                [WPAppAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{@"tap_source": @"posts_view"} withBlog:self.blog];
            }
            
            - (void)previewEditPost:(AbstractPost *)apost
{
    [self editPost:apost withEditMode:kWPPostViewControllerModePreview];
    }
    
    - (void)editPost:(AbstractPost *)apost
{
    [self editPost:apost withEditMode:kWPPostViewControllerModeEdit];
    }
    
    - (void)editPost:(AbstractPost *)apost withEditMode:(WPPostViewControllerMode)mode
{
    [WPAnalytics track:WPAnalyticsStatPostListEditAction withProperties:[self propertiesForAnalytics]];
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *postViewController = [[WPPostViewController alloc] initWithPost:apost mode:mode];
        
        __weak __typeof(self) weakSelf = self;
        
        postViewController.onClose = ^void(WPPostViewController* viewController, BOOL changesSaved) {
            
            if (changesSaved) {
                [weakSelf setFilterWithPostStatus:viewController.post.status];
            }
            
            [viewController.navigationController popViewControllerAnimated:YES];
        };
        
        postViewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:postViewController animated:YES];
    } else {
        // In legacy mode, view means edit
        WPLegacyEditPostViewController *editPostViewController = [[WPLegacyEditPostViewController alloc] initWithPost:apost];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
        [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPostViewController class];
        
        [self presentViewController:navController animated:YES completion:nil];
    }
    }
    
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

import Foundation

@objc class PostListViewController2 : AbstractPostListViewController, UIViewControllerRestoration { //, PostCardTableViewCellDelegate,  {
    
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
    static private let postCardEstimatedRowHeight = CGFloat(100.0)
    static private let postCardRestoreCellRowHeight = CGFloat(54.0)
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
    
    class func controllerWithBlog(blog: Blog) -> PostListViewController2 {
        
        let storyBoard = UIStoryboard(name: "Posts", bundle: NSBundle.mainBundle())
        let controller = storyBoard.instantiateViewControllerWithIdentifier("PostListViewController") as! PostListViewController2
        
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
        super.postListViewController = segue.destinationViewController
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
        
        tableViewHandler.clearCachedRowHeights()
        tableView.reloadRowsAtIndexPaths(tableView.indexPathsForVisibleRows, withRowAnimation: .None)
    }
    
    func forceUpdateCellLayout(cell: PostCardTableViewCell) {
        // Force a layout pass to ensure that constrants are configured for the
        // proper size class.
        view.addSubview(cell)
        cell.removeFromSuperview()
    }
    
    /*
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
 {
 [super traitCollectionDidChange:previousTraitCollection];
 
 [self forceUpdateCellLayout:self.textCellForLayout];
 [self forceUpdateCellLayout:self.imageCellForLayout];
 
 [self.tableViewHandler clearCachedRowHeights];
 [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
 }
 */
}




