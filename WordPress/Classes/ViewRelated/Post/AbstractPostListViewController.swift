/*
 
#import <UIKit/UIKit.h>
#import "NavbarTitleDropdownButton.h"
#import "PostListFilter.h"
#import "WordPress-swift.h"

@class Blog;

@interface AbstractPostListViewController : UIViewController

/**
 *  Sets the filtering of this VC to show the posts with the specified status.
 *
 *  @param      status      The status of the type of post we want to show.
 */
- (void)setFilterWithPostStatus:(NSString* __nonnull)status;

- (NSString* _Nonnull)postTypeToSync;
- (NSDate* _Nullable)lastSyncDate;
- (void)syncItemsWithUserInteraction:(BOOL)userInteraction;
- (BOOL)canFilterByAuthor;
- (BOOL)shouldShowOnlyMyPosts;
- (PostAuthorFilter)currentPostAuthorFilter;
- (void)setCurrentPostAuthorFilter:(PostAuthorFilter)filter;
- (PostListFilter * _Nullable)currentPostListFilter;
- (CGFloat)heightForFooterView;
- (void)publishPost:(AbstractPost* _Nonnull)apost;
- (void)viewPost:(AbstractPost* _Nonnull)apost;
- (void)deletePost:(AbstractPost* _Nonnull)apost;
- (void)restorePost:(AbstractPost* _Nonnull)apost;
- (void)updateAndPerformFetchRequestRefreshingCachedRowHeights;
- (void)resetTableViewContentOffset;
- (BOOL)isSearching;
- (NSString* _Nullable)currentSearchTerm;
- (NSDictionary* _Nonnull)propertiesForAnalytics;
- (NSManagedObjectContext* _Nonnull)managedObjectContext;

@end

*/

import Foundation
import WordPressApi
import WordPressComAnalytics
import WordPressShared

class AbstractPostListViewController : UIViewController, WPContentSyncHelperDelegate, WPNoResultsViewDelegate, WPSearchControllerDelegate, WPSearchResultsUpdating, WPTableViewHandlerDelegate {
    
    typealias WPNoResultsView = WordPressShared.WPNoResultsView
    
    enum PostAuthorFilter {
        case Mine
        case Everyone
    }
    
    private static let PostsControllerRefreshInterval = NSTimeInterval(300)
    private static let HTTPErrorCodeForbidden = Int(403)
    private static let PostsFetchRequestBatchSize = Int(10)
    private static let PostsLoadMoreThreshold = Int(4)
    private static let PreferredFiltersPopoverContentSize = CGSize(width: 320.0, height: 220.0)
    
    static let heightForFooterView = 44.0
    
    var blog : Blog
    
    var postListViewController : UITableViewController
    var tableView : UITableView
    var refreshControl : UIRefreshControl?
    var tableViewHandler : WPTableViewHandler
    var syncHelper : WPContentSyncHelper
    var noResultsView : WPNoResultsView?
    var postListFooterView : PostListFooterView
    var animatedBox : WPAnimatedBox?
    
    @IBOutlet var filterButton : NavBarTitleDropdownButton!
    @IBOutlet var rightBarButtonView : UIView!
    @IBOutlet var searchButton : UIButton!
    @IBOutlet var addButton : UIButton!
    @IBOutlet var searchWrapperView : UIView! // Used on iPhone for presenting the search bar.
    @IBOutlet var authorsFilterView : UIView! // Search lives here on iPad
    @IBOutlet var authorsFilterViewHeightConstraint : NSLayoutConstraint!
    @IBOutlet var searchWrapperViewHeightConstraint : NSLayoutConstraint!
    
    var searchController : WPSearchController // Stand-in for UISearchController
    private var allPostListFilters = [NSString: NSArray]()
    private(set) var recentlyTrashedPostObjectIDs = [NSManagedObjectID]() // IDs of trashed posts. Cleared on refresh or when filter changes.
    
    private var needsRefreshCachedCellHeightsBeforeLayout = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = postListViewController.tableView;
        refreshControl = postListViewController.refreshControl
        
        refreshControl?.addTarget(self, action: #selector(AbstractPostListViewController.refresh(_:)), forControlEvents: .ValueChanged)
        
        configuerFilters()
        configureCellsForLayout()
        configureTableView()
        configureFooterView()
        configureSyncHelper()
        configureNavbar()
        configureSearchController()
        configureAuthorFilter()
        configureTableViewHandler()
        
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureNoResultsView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        automaticallySyncIfAppropriate()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AbstractPostListViewController.handleApplicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchController.active = false
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({[weak self] (context: UIViewControllerTransitionCoordinatorContext) -> () in
            if let strongSelf = self {
                if UIDevice.isPad() == false && strongSelf.searchWrapperViewHeightConstraint.constant > 0 {
                    strongSelf.searchWrapperViewHeightConstraint.constant = heightForSearchWrapperView()
                }
            }
        }, completion: nil)
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        let width = CGRectGetWidth(view.frame)
        tableViewHandler.refreshCachedRowHeightsForWidth(width)
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        needsRefreshCachedCellHeightsBeforeLayout = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if needsRefreshCachedCellHeightsBeforeLayout {
            needsRefreshCachedCellHeightsBeforeLayout = false
            
            let width = CGRectGetWidth(view.frame)
            
            tableViewHandler.refreshCachedRowHeightsForWidth(width)
            
            if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
                tableView.reloadRowsAtIndexPaths(indexPathsForVisibleRows, withRowAnimation: .None)
            }
        }
    }
    
    // MARK: - Multitasking Support
    
    func handleApplicationDidBecomeActive(notification: NSNotification) {
        needsRefreshCachedCellHeightsBeforeLayout = false
    }
    
    // MARK: - Configuration
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func configureNavbar() {
        // IMPORTANT: this code makes sure that the back button in WPPostViewController doesn't show
        // this VC's title.
        //
        let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let rightBarButtonItem = UIBarButtonItem(customView: rightBarButtonView)
        WPStyleGuide.setRightBarButtonItemWithCorrectSpacing(rightBarButtonItem, forNavigationItem:navigationItem)
        
        navigationItem.titleView = filterButton
        updateFilterTitle()
    }
    
    func configureCellsForLayout() {
        assert(false, "You should implement this method in the subclass")
    }
    
    func configureTableView() {
        assert(false, "You should implement this method in the subclass")
    }
    
    func configureFooterView() {
        
        let mainBundle = NSBundle.mainBundle()
        
        postListFooterView = mainBundle.loadNibNamed("PostListFooterView", owner: nil, options: nil)[0] as! PostListFooterView
        postListFooterView.showSpinner(false)
        
        var frame = postListFooterView.frame
        frame.size.height = heightForFooterView()
        
        postListFooterView.frame = frame
        tableView.tableFooterView = postListFooterView
    }
    
    func configureTableViewHandler() {
        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.cacheRowHeights = true
        tableViewHandler.delegate = self
        tableViewHandler.updateRowAnimation = .None
    }
    
    func configureSyncHelper() {
        syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
    }
    
    func getNoResultsView() -> WPNoResultsView {
        if noResultsView == nil {
            noResultsView = WPNoResultsView()
            noResultsView!.delegate = self
        }
        
        return noResultsView!
    }
    
    func configureNoResultsView() {
        guard isViewLoaded() == true else {
            return
        }
        
        let noResultsView = getNoResultsView()
        
        if tableViewHandler.resultsController.fetchedObjects?.count > 0 {
            noResultsView.removeFromSuperview()
            postListFooterView.hidden = false
            return
        }
        postListFooterView.hidden = true
        
        // Refresh the NoResultsView Properties
        noResultsView.titleText = noResultsTitleText()
        noResultsView.messageText = noResultsMessageText()
        noResultsView.accessoryView = noResultsAccessoryView()
        noResultsView.buttonTitle = noResultsButtonText()
        
        // Only add and animate no results view if it isn't already
        // in the table view
        if noResultsView.isDescendantOfView(tableView) == false {
            tableView.addSubviewWithFadeAnimation(noResultsView)
        } else {
            noResultsView.centerInSuperview()
        }
        
        tableView.sendSubviewToBack(noResultsView)
    }
    
    func noResultsTitleText() -> String {
        assert(false, "You should implement this method in the subclass")
    }
    
    func noResultsMessageText() -> String {
        assert(false, "You should implement this method in the subclass")
    }
    
    func noResultsAccessoryView() -> UIView {
        if syncHelper.isSyncing {
            if animatedBox == nil {
                animatedBox = WPAnimatedBox.newAnimatedBox()
            }
            
            return animatedBox!
        }
        
        return UIImageView(image: UIImage(named: "illustration-posts"))
    }
    
    func noResultsButtonText() -> String {
        assert(false, "You should implement this method in the subclass")
    }
    
    func configureAuthorFilter() {
        assert(false, "You should implement this method in the subclass")
    }
    
    func configureSearchController() {
        searchController = WPSearchController(searchResultsController: nil)
        
        let searchControllerConfigurator = WPSearchControllerConfigurator(searchController: searchController, withSearchWrapperView: searchWrapperView)
        searchControllerConfigurator.configureSearchControllerAndWrapperView()
        configureSearchBarPlaceholder()
        searchController.delegate = self
        searchController.searchResultsUpdater = self
    }
    
    func configureSearchBarPlaceholder() {
        // Adjust color depending on where the search bar is being presented.
        let placeholderColor = WPStyleGuide.wordPressBlue()
        let placeholderText = NSLocalizedString("Search", comment: "Placeholder text for the search bar on the post screen.")
        let attrPlacholderText = NSAttributedString(string: placeholderText, attributes: WPStyleGuide.defaultSearchBarTextAttributes(placeholderColor) as? [String:AnyObject])
        
        let defaultTextAttributes = WPStyleGuide.defaultSearchBarTextAttributes(UIColor.whiteColor()) as! [String:AnyObject]
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, self.dynamicType]).attributedPlaceholder = attrPlacholderText
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, self.dynamicType]).defaultTextAttributes = defaultTextAttributes
    }
    
    func configureSearchWrapper() {
        searchWrapperView.backgroundColor = WPStyleGuide.wordPressBlue()
    }
    
    func propertiesForAnalytics() -> [String:AnyObject] {
        var properties = [String:AnyObject]()
        
        properties["type"] = postTypeToSync()
        properties["filter"] = currentPostListFilter().title
        
        if let dotComID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }
        
        return properties
    }
    
    // MARK: - Actions
    
    @IBAction func refresh(sender: AnyObject) {
        syncItemsWithUserInteraction(true)
        
        WPAnalytics.track(track:WPAnalyticsStatPostListPullToRefresh, withProperties: propertiesForAnalytics())
    }
    
    @IBAction func handleAddButtonTapped(sender: AnyObject) {
        createPost()
    }
    
    @IBAction func handleSearchButtonTapped(sender: AnyObject) {
        toggleSearch()
    }
    
    @IBAction func didTapNoResultsView(noResultsView: WPNoResultsView) {
        WPAnalytics.track(WPAnalyticsStatPostListNoResultsButtonPressed, withProperties: propertiesForAnalytics())
        
        if currentPostListFilter().filterType == PostListStatusFilterScheduled {
            let index = indexForFilterWithType(PostListStatusFilterDraft)
            setCurrentFilterIndex(index)
            return
        }
        
        createPost()
    }
    
    @IBAction func didTapFilterButton(sender: AnyObject) {
        displayFilters()
    }

    // MARK: - Synching

    func automaticallySyncIfAppropriate() {
        // Only automatically refresh if the view is loaded and visible on the screen
        if isViewLoaded() == false || view.window == nil {
            DDLogVerbose("View is not visible and will not check for auto refresh.")
            return
        }
     
        // Do not start auto-sync if connection is down
        let appDelegate = WordPressAppDelegate.sharedInstance()
        
        if appDelegate.connectionAvailable == false {
            configureNoResultsView()
            return
        }
        
        let lastSynced = lastSyncDate
        if lastSynced == nil || ABS(lastSynced.timeIntervalSinceNow()) > PostsControllerRefreshInterval {
            // Update in the background
            syncItemsWithUserInteraction(false)
        } else {
            configureNoResultsView()
        }
    }
    
    func syncItemsWithUserInteraction(userInteraction: Bool) {
        syncHelper.syncContentWithUserInteraction(userInteraction)
        configureNoResultsView()
    }
    
    func updateFilter(filter: PostListFilter, withSyncedPosts posts:[AbstractPost], syncOptions options: PostServiceSyncOptions) {
        let oldestPost = posts[posts.count - 1]
        
        // Reset the filter to only show the latest sync point.
        filter.oldestPostDate = oldestPost.dateCreated()
        filter.hasMore = posts.count >= options.number.integerValue
        
        updateAndPerformFetchRequestRefreshingCachedRowHeights()
    }
    
    func numberOfPostsPerSync() -> UInt {
        return PostServiceDefaultNumberToSync
    }
    
    // MARK: - Sync Helper Delegate Methods
    
    func postTypeToSync() -> String {
        // Subclasses should override.
        return PostServiceTypeAny
    }
    
    func lastSyncDate() -> NSDate {
        return blog.lastPostsSync;
    }
    
    func syncHelper(syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: (Bool) -> (), failure: (NSError) -> ()) {
        
        if recentlyTrashedPostObjectIDs.count > 0 {
            recentlyTrashedPostObjectIDs.removeAll()
            updateAndPerformFetchRequestRefreshingCachedRowHeights()
        }
        
        let filter = currentPostListFilter()
        let author = shouldShowOnlyMyPosts() ? blog.account.userID : nil
        
        let postService = PostService(managedObjectContext: managedObjectContext)
        
        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses
        options.authorID = author
        options.number = numberOfPostsPerSync()
        options.purgesLocalSync = true
        
        postService.syncPostsOfType(
            postTypeToSync(),
            withOptions: options,
            forBlog: blog,
            success: {[weak self] (posts: [AbstractPost]) -> () in
                guard let strongSelf = self, let success = success else {
                    return
                }
                
                strongSelf.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                success(filter.hasMore)
            }, failure: {[weak self] (error: NSError) -> () in
                
                guard let strongSelf = self else {
                    return
                }
                
                if let failure = failure {
                    failure(error)
                }
                
                if userInteraction == true {
                    strongSelf.handleSyncFailure(error)
                }
        })
    }
    
    func syncHelper(syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        
        WPAnalytics.track(.PostListLoadedMore, withProperties: propertiesForAnalytics())
        postListFooterView.showSpinner(true)
        
        let filter = currentPostListFilter()
        let author = shouldShowOnlyMyPosts() ? blog.account.userID : nil
        
        let postService = PostService(managedObjectContext: managedObjectContext)
        
        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses
        options.authorID = author
        options.number = numberOfPostsPerSync()
        options.offset = tableViewHandler.resultsController.fetchedObjects?.count
        
        postService.syncPostsOfType(
            postTypeToSync(),
            withOptions: options,
            forBlog: blog,
            success: {[weak self] (posts: [AbstractPost]) -> () in
                guard let strongSelf = self, let success = success else {
                    return
                }
                
                strongSelf.updateFilter(filter, withSyncedPosts: posts, syncOptions: options)
                success(filter.hasMore)
            }, failure: {[weak self] (error: NSError) -> () in
                
                guard let strongSelf = self else {
                    return
                }
                
                if let failure = failure {
                    failure(error)
                }
                
                strongSelf.handleSyncFailure(error)
            })
    }
    
    func syncContentEnded() {
        refreshControl?.endRefreshing()
        postListFooterView.showSpinner(false)
        
        noResultsView?.removeFromSuperview()
        
        if tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            // This is a special case.  Core data can be a bit slow about notifying
            // NSFetchedResultsController delegates about changes to the fetched results.
            // To compensate, call configureNoResultsView after a short delay.
            // It will be redisplayed if necessary.
            
            performSelector(#selector(configureNoResultsView(_:)), withObject: self, afterDelay: 0.1)
        }
    }
    
    func handleSyncFailure(error: NSError) {
        if error.domain == WPXMLRPCClientErrorDomain
            && error.code == self.dynamicType.HTTPErrorCodeForbidden {
            promptForPassword()
            return
        }
        
        WPError.showNetworkingAlertWithError(error, title: NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails."))
    }
    
    func promptForPassword() {
        let message = NSLocalizedString("The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", comment: "")
        WPError.showAlertWithTitle(NSLocalizedString("Unable to Connect", comment: ""), message: message)
        
        // bad login/pass combination
        let editSiteViewController = SiteSettingsViewController(blog: blog)
        editSiteViewController.isCancellable = false
        
        let navController = UINavigationController(rootViewController: editSiteViewController)
        navController.navigationBar.translucent = false
        
        if UIDevice.isPad() {
            navController.modalTransitionStyle = .CrossDissolve
            navController.modalPresentationStyle = .FormSheet
        }
        
        presentViewController(navController, animated: true, completion: nil)
    }
    
    // MARK: - Search Controller Delegate Methods
    
    func presentSearchController(searchController: WPSearchController!) {
        WPAnalytics.track(.PostListSearchOpened, withProperties: propertiesForAnalytics())
        
        navigationController?.setNavigationBarHidden(true, animated: true) // Remove this line when switching to UISearchController.
        searchWrapperViewHeightConstraint.constant = heightForSearchWrapperView()
        
        UIView.animateWithDuration(SearchBarAnimationDuration, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: { [weak self] in
            self?.view.layoutIfNeeded()
            }, completion: { (finished: Bool) -> () in
                searchController.searchBar.becomeFirstResponder()
        })
    }
    
    func willDismissSearchController(searchController: WPSearchController!) {
        searchController.searchBar.resignFirstResponder()
        navigationController?.setNavigationBarHidden(false, animated: true) // Remove this line when switching to UISearchController
        searchWrapperViewHeightConstraint.constant = 0
        
        UIView.animateWithDuration(SearchBarAnimationDuration) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        
        searchController.searchBar.text = nil
        resetTableViewContentOffset()
        updateAndPerformFetchRequestRefreshingCachedRowHeights()
    }
    
    func updateSearchResultsForSearchController(searchController: WPSearchController!) {
        resetTableViewContentOffset()
        updateAndPerformFetchRequestRefreshingCachedRowHeights()
    }
    
}

/*
#import "AbstractPostListViewController.h"

#import "AbstractPost.h"
#import "SiteSettingsViewController.h"
#import "PostPreviewViewController.h"
#import "PostService.h"
#import "PostServiceOptions.h"
#import "SettingsSelectionViewController.h"
#import "UIView+Subviews.h"
#import "WordPressAppDelegate.h"
#import "WPAppAnalytics.h"
#import "WPSearchControllerConfigurator.h"
#import <WordPressApi/WordPressApi.h>

@interface AbstractPostListViewController() <WPContentSyncHelperDelegate, WPNoResultsViewDelegate, WPSearchControllerDelegate, WPSearchResultsUpdating, WPTableViewHandlerDelegate>
@end

@implementation AbstractPostListViewController


#pragma mark - TableView Handler Delegate Methods

- (NSString *)entityName
{
    AssertSubclassMethod();
    return nil;
    }
    
    - (NSManagedObjectContext *)managedObjectContext
        {
            return [[ContextManager sharedInstance] mainContext];
        }
        
        - (NSFetchRequest *)fetchRequest
            {
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
                fetchRequest.predicate = [self predicateForFetchRequest];
                fetchRequest.sortDescriptors = [self sortDescriptorsForFetchRequest];
                fetchRequest.fetchBatchSize = PostsFetchRequestBatchSize;
                fetchRequest.fetchLimit = [self numberOfPostsPerSync];
                return fetchRequest;
            }
            
            - (NSArray *)sortDescriptorsForFetchRequest
                {
                    // Ascending only for scheduled posts/pages.
                    BOOL ascending = self.currentPostListFilter.filterType == PostListStatusFilterScheduled;
                    NSSortDescriptor *sortDescriptorLocal = [NSSortDescriptor sortDescriptorWithKey:@"metaIsLocal" ascending:NO];
                    NSSortDescriptor *sortDescriptorImmediately = [NSSortDescriptor sortDescriptorWithKey:@"metaPublishImmediately" ascending:NO];
                    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:ascending];
                    return @[sortDescriptorLocal, sortDescriptorImmediately, sortDescriptorDate];
                }
                
                - (void)updateAndPerformFetchRequest
                    {
                        NSAssert([NSThread isMainThread], @"AbstractPostListViewController Error: NSFetchedResultsController accessed in BG");
                        NSPredicate *predicate = [self predicateForFetchRequest];
                        NSArray *sortDescriptors = [self sortDescriptorsForFetchRequest];
                        NSError *error = nil;
                        NSFetchRequest *fetchRequest = self.tableViewHandler.resultsController.fetchRequest;
                        
                        // Set the predicate based on filtering by the oldestPostDate and not searching.
                        PostListFilter *filter = [self currentPostListFilter];
                        if (filter.oldestPostDate && !self.isSearching) {
                            // Filter posts by any posts newer than the filter's oldestPostDate.
                            // Also include any posts that don't have a date set, such as local posts created without a connection.
                            NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"(date_created_gmt = NULL) OR (date_created_gmt >= %@)", filter.oldestPostDate];
                            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, datePredicate]];
                        }
                        
                        // Set up the fetchLimit based on filtering or searching
                        if (filter.oldestPostDate || self.isSearching) {
                            // If filtering by the oldestPostDate or searching, the fetchLimit should be disabled.
                            fetchRequest.fetchLimit = 0;
                        } else {
                            // If not filtering by the oldestPostDate or searching, set the fetchLimit to the default number of posts.
                            fetchRequest.fetchLimit = [self numberOfPostsPerSync];
                        }
                        
                        [fetchRequest setPredicate:predicate];
                        [fetchRequest setSortDescriptors:sortDescriptors];
                        
                        [self.tableViewHandler.resultsController performFetch:&error];
                        if (error) {
                            DDLogError(@"Error fetching posts after updating the fetch request predicate: %@", error);
                        }
                    }
                    
                    - (void)updateAndPerformFetchRequestRefreshingCachedRowHeights
                        {
                            [self updateAndPerformFetchRequest];
                            
                            CGFloat width = CGRectGetWidth(self.tableView.bounds);
                            [self.tableViewHandler refreshCachedRowHeightsForWidth:width];
                            
                            [self.tableView reloadData];
                            [self configureNoResultsView];
                        }
                        
                        - (void)resetTableViewContentOffset
                            {
                                // Reset the tableView contentOffset to the top before we make any dataSource changes.
                                CGPoint tableOffset = self.tableView.contentOffset;
                                tableOffset.y = -self.tableView.contentInset.top;
                                self.tableView.contentOffset = tableOffset;
                            }
                            
                            - (NSPredicate *)predicateForFetchRequest
                                {
                                    AssertSubclassMethod();
                                    return nil;
}


#pragma mark - Table View Handling

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssertSubclassMethod();
    }
    
    - (void)tableViewDidChangeContent:(UITableView *)tableView
{
    // After any change, make sure that the no results view is properly
    // configured.
    [self configureNoResultsView];
    }
    
    - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self isViewOnScreen] || self.isSearching) {
        return;
    }
    
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == self.tableView.numberOfSections) &&
        (indexPath.row + PostsLoadMoreThreshold >= [self.tableView numberOfRowsInSection:indexPath.section])) {
        
        // Only 3 rows till the end of table
        if ([self currentPostListFilter].hasMore) {
            [self.syncHelper syncMoreContent];
        }
    }
    }
    
    - (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    AssertSubclassMethod();
}


#pragma mark - Actions

- (void)publishPost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListPublishAction withProperties:[self propertiesForAnalytics]];
    apost.status = PostStatusPublish;
    apost.dateCreated = [NSDate date];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService uploadPost:apost
        success:nil
        failure:^(NSError *error) {
        if([error code] == HTTPErrorCodeForbidden) {
        [self promptForPassword];
        } else {
        [WPError showXMLRPCErrorAlert:error];
        }
        [self syncItemsWithUserInteraction:NO];
        }];
    }
    
    - (void)viewPost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListViewAction withProperties:[self propertiesForAnalytics]];
    apost = ([apost hasRevision]) ? apost.revision : apost;
    PostPreviewViewController *controller = [[PostPreviewViewController alloc] initWithPost:apost shouldHideStatusBar:NO];
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
    }
    
    - (void)deletePost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListTrashAction withProperties:[self propertiesForAnalytics]];
    NSManagedObjectID *postObjectID = apost.objectID;
    
    [self.recentlyTrashedPostObjectIDs addObject:postObjectID];
    
    // Update the fetch request *before* making the service call.
    [self updateAndPerformFetchRequest];
    
    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:apost];
    [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService trashPost:apost
    success:nil
    failure:^(NSError *error) {
    if([error code] == HTTPErrorCodeForbidden) {
    [self promptForPassword];
    } else {
    [WPError showXMLRPCErrorAlert:error];
    }
    
    [self.recentlyTrashedPostObjectIDs removeObject:postObjectID];
    [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
    }
    
    - (void)restorePost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListRestoreAction withProperties:[self propertiesForAnalytics]];
    // if the post was recently deleted, update the status helper and reload the cell to display a spinner
    NSManagedObjectID *postObjectID = apost.objectID;
    
    [self.recentlyTrashedPostObjectIDs removeObject:postObjectID];
    
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService restorePost:apost
        success:^() {
        // Make sure the post still exists.
        NSError *err;
        AbstractPost *post = (AbstractPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        if (err) {
        DDLogError(@"%@", err);
        }
        if (!post) {
        return;
        }
        
        // If the post was restored, see if it appears in the current filter.
        // If not, prompt the user to let it know under which filter it appears.
        PostListFilter *filter = [self filterThatDisplaysPostsWithStatus:post.status];
        if ([filter isEqual:[self currentPostListFilter]]) {
        return;
        }
        [self promptThatPostRestoredToFilter:filter];
        }
        failure:^(NSError *error) {
        if([error code] == 403) {
        [self promptForPassword];
        } else {
        [WPError showXMLRPCErrorAlert:error];
        }
        [self.recentlyTrashedPostObjectIDs addObject:postObjectID];
        }];
    }
    
    - (void)promptThatPostRestoredToFilter:(PostListFilter *)filter
{
    AssertSubclassMethod();
}


#pragma mark - Instance Methods

#pragma mark - Post Actions

- (void)createPost
{
    AssertSubclassMethod();
}

#pragma mark - Search related

- (void)toggleSearch
{
    self.searchController.active = !self.searchController.active;
    }
    
    - (CGFloat)heightForSearchWrapperView
        {
            UINavigationBar *navBar = self.navigationController.navigationBar;
            CGFloat height = CGRectGetHeight(navBar.frame) + [UIApplication sharedApplication].statusBarFrame.size.height;
            return MAX(height, SearchWrapperViewMinHeight);
        }
        
        - (BOOL)isSearching
            {
                return self.searchController.isActive && [[self currentSearchTerm] length]> 0;
            }
            
            - (NSString *)currentSearchTerm
                {
                    return self.searchController.searchBar.text;
}


#pragma mark - Filter related

- (BOOL)canFilterByAuthor
{
    return [self.blog isMultiAuthor] && self.blog.account.userID && [self.blog isHostedAtWPcom];
    }
    
    - (BOOL)shouldShowOnlyMyPosts
        {
            PostAuthorFilter filter = [self currentPostAuthorFilter];
            return filter == PostAuthorFilterMine;
        }
        
        - (PostAuthorFilter)currentPostAuthorFilter
            {
                return PostAuthorFilterEveryone;
            }
            
            - (void)setCurrentPostAuthorFilter:(PostAuthorFilter)filter
{
    // Noop. The default implementation is read only.
    // Subclasses may override the getter and setter for their own filter storage.
    }
    
    - (NSArray *)availablePostListFilters
        {
            PostAuthorFilter currentAuthorFilter = [self currentPostAuthorFilter];
            NSString *authorFilterKey = [NSString stringWithFormat:@"filter_key_%@", [[NSNumber numberWithUnsignedInteger:currentAuthorFilter] stringValue]];
            
            if (![self.allPostListFilters objectForKey:authorFilterKey]) {
                [self.allPostListFilters setObject:[PostListFilter newPostListFilters] forKey:authorFilterKey];
            }
            
            return [self.allPostListFilters objectForKey:authorFilterKey];
        }
        
        - (PostListFilter *)currentPostListFilter
            {
                return self.availablePostListFilters[[self currentFilterIndex]];
            }
            
            - (PostListFilter *)filterThatDisplaysPostsWithStatus:(NSString *)postStatus
{
    NSUInteger index = [self indexOfFilterThatDisplaysPostsWithStatus:postStatus];
    
    return self.availablePostListFilters[index];
    }
    
    
    - (NSUInteger)indexOfFilterThatDisplaysPostsWithStatus:(NSString *)postStatus
{
    __block NSUInteger index = 0;
    __block BOOL found = NO;
    
    [self.availablePostListFilters enumerateObjectsUsingBlock:^(PostListFilter* _Nonnull filter, NSUInteger idx, BOOL* _Nonnull stop) {
        if ([filter.statuses containsObject:postStatus]) {
        index = idx;
        found = YES;
        *stop = YES;
        }
        }];
    
    if (!found) {
        // The draft filter is the catch all by convention.
        index = [self indexForFilterWithType:PostListStatusFilterDraft];
    }
    
    return index;
    }
    
    - (NSInteger)indexForFilterWithType:(PostListStatusFilter)filterType
{
    NSInteger index = [self.availablePostListFilters indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        PostListFilter *filter = (PostListFilter *)obj;
        return filter.filterType == filterType;
        }];
    return index;
    }
    
    - (NSString *)keyForCurrentListStatusFilter
        {
            AssertSubclassMethod();
            return nil;
        }
        
        - (NSInteger)currentFilterIndex
            {
                NSNumber *filter = [[NSUserDefaults standardUserDefaults] objectForKey:[self keyForCurrentListStatusFilter]];
                if (!filter || [filter integerValue] >= [self.availablePostListFilters count]) {
                    return 0; // first item is the default
                }
                return [filter integerValue];
            }
            
            - (void)setCurrentFilterIndex:(NSInteger)newIndex
{
    NSInteger index = [self currentFilterIndex];
    if (newIndex == index) {
        return;
    }
    [WPAnalytics track:WPAnalyticsStatPostListStatusFilterChanged withProperties:[self propertiesForAnalytics]];
    [[NSUserDefaults standardUserDefaults] setObject:@(newIndex) forKey:[self keyForCurrentListStatusFilter]];
    [NSUserDefaults resetStandardUserDefaults];
    
    [self.recentlyTrashedPostObjectIDs removeAllObjects];
    [self updateFilterTitle];
    [self resetTableViewContentOffset];
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
    }
    
    - (void)updateFilterTitle
        {
            [self.filterButton setAttributedTitleForTitle:[self currentPostListFilter].title];
        }
        
        - (void)displayFilters
            {
                NSArray *titles = [self.availablePostListFilters wp_map:^id(PostListFilter *filter) {
                    return filter.title;
                    }];
                NSDictionary *dict = @{
                    SettingsSelectionDefaultValueKey   : [self.availablePostListFilters firstObject],
                    SettingsSelectionTitleKey          : NSLocalizedString(@"Filters", @"Title of the list of post status filters."),
                    SettingsSelectionTitlesKey         : titles,
                    SettingsSelectionValuesKey         : self.availablePostListFilters,
                    SettingsSelectionCurrentValueKey   : [self currentPostListFilter]
                };
                
                SettingsSelectionViewController *controller = [[SettingsSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDictionary:dict];
                controller.onItemSelected = ^(NSDictionary *selectedValue) {
                    [self setCurrentFilterIndex:[self.availablePostListFilters indexOfObject:selectedValue]];
                    [self dismissViewControllerAnimated:YES completion:nil];
                };
                
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                if ([UIDevice isPad]) {
                    [self displayFilterPopover:navController];
                } else {
                    [self displayFilterModal:navController];
                }
            }
            
            - (void)displayFilterPopover:(UIViewController *)controller
{
    controller.preferredContentSize = PreferredFiltersPopoverContentSize;
    
    CGRect titleRect = self.navigationItem.titleView.frame;
    titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];
    
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIPopoverPresentationController *presentationController = controller.popoverPresentationController;
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.sourceView = self.navigationController.view;
    presentationController.sourceRect = titleRect;
    }
    
    - (void)displayFilterModal:(UIViewController *)controller
{
    controller.modalPresentationStyle = UIModalPresentationPageSheet;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:controller animated:YES completion:nil];
    }
    
    
    - (void)setFilterWithPostStatus:(NSString* __nonnull)status
{
    NSUInteger index = [self indexOfFilterThatDisplaysPostsWithStatus:status];
    
    [self setCurrentFilterIndex:index];
}

@end
*/








