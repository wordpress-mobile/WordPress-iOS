import Foundation

@objc class PageListViewController : AbstractPostListViewController, PageListTableViewCellDelegate, UIViewControllerRestoration {
    
    private static let pageSectionHeaderHeight = Float(24.0)
    private static let pageCellEstimatedRowHeight = Float(44.0)
    private static let pagesViewControllerRestorationKey = "PagesViewControllerRestorationKey"
    private static let pageCellIdentifier = "PageCellIdentifier"
    private static let pageCellNibName = "PageListTableViewCell"
    private static let restorePageCellIdentifier = "RestorePageCellIdentifier"
    private static let restorePageCellNibName = "RestorePageTableViewCell"
    private static let currentPageListStatusFilterKey = "CurrentPageListStatusFilterKey"
    
    private var cellForLayout : PageListTableViewCell
    
    
    // MARK: - Convenience constructors
    
    class func controllerWithBlog(blog: Blog) -> PageListViewController {
        
        let storyBoard = UIStoryboard(name: "Pages", bundle: NSBundle.mainBundle())
        let controller = storyBoard.instantiateViewControllerWithIdentifier("PageListViewController") as! PageListViewController
        
        controller.blog = blog
        controller.restorationClass = self
        
        return controller
    }
    
    // MARK: - UIViewControllerRestoration
    
    class func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        
        let context = ContextManager.sharedInstance().mainContext
        
        guard let blogID = coder.decodeObjectForKey(pagesViewControllerRestorationKey) as? String,
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
        
        coder.encodeObject(objectString, forKey:self.dynamicType.pagesViewControllerRestorationKey)
        
        super.encodeRestorableStateWithCoder(coder)
    }
    
    // MARK: - UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.postListViewController = (segue.destinationViewController as! UITableViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Pages", comment: "Tile of the screen showing the list of pages for a blog.")
    }
    
    // MARK: - Configuration
    
    private func configureCellsForLayout() {
        
        let bundle = NSBundle.mainBundle()
        
        cellForLayout = bundle.loadNibNamed(self.dynamicType.pageCellNibName, owner: nil, options: nil)[0] as! PageListTableViewCell
    }
    
    private func configureTableView() {
        
        guard let tableView = tableView else {
            return
        }
        
        tableView.accessibilityIdentifier = "PagesTable"
        tableView.isAccessibilityElement = true
        tableView.separatorStyle = .None
        
        let bundle = NSBundle.mainBundle()
        
        // Register the cells
        let pageCellNib = UINib(nibName: self.dynamicType.pageCellNibName, bundle: bundle)
        tableView.registerNib(pageCellNib, forCellReuseIdentifier: self.dynamicType.pageCellIdentifier)
        
        let restorePageCellNib = UINib(nibName: self.dynamicType.restorePageCellNibName, bundle: bundle)
        tableView.registerNib(restorePageCellNib, forCellReuseIdentifier: self.dynamicType.restorePageCellIdentifier)
    }
    
    private func noResultsTitleText() -> String {
        if syncHelper?.isSyncing == true {
            return NSLocalizedString("Fetching pages...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new pages.")
        }
        
        if let filter = currentPostListFilter() {
            let titles = noResultsTitles()
            let title = titles[filter.filterType]
            return title ?? ""
        } else {
            return ""
        }
    }
    
    private func noResultsTitles() -> [PostListStatusFilter:String] {
        if isSearching() {
            return noResultsTitlesWhenSearching()
        } else {
            return noResultsTitlesWhenFiltering()
        }
    }
    
    private func noResultsTitlesWhenSearching() -> [PostListStatusFilter:String] {
        
        let draftMessage = String(format: NSLocalizedString("No drafts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let scheduledMessage = String(format: NSLocalizedString("No scheduled pages match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let trashedMessage = String(format: NSLocalizedString("No trashed pages match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let publishedMessage = String(format: NSLocalizedString("No pages match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        
        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }
    
    private func noResultsTitlesWhenFiltering() -> [PostListStatusFilter:String] {
        
        let draftMessage = NSLocalizedString("You don't have any drafts.", comment: "Displayed when the user views drafts in the pages list and there are no pages")
        let scheduledMessage = NSLocalizedString("You don't have any scheduled pages.", comment: "Displayed when the user views scheduled pages in the pages list and there are no pages")
        let trashedMessage = NSLocalizedString("You don't have any posts in your trash folder.", comment: "Displayed when the user views trashed in the posts list and there are no posts")
        let publishedMessage = NSLocalizedString("You haven't published any pages yet.", comment: "Displayed when the user views published pages in the pages list and there are no pages")
        
        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }
    
    private func noResultsTitles(draft: String, scheduled: String, trashed: String, published: String) -> [PostListStatusFilter:String] {
        return [.Draft: draft,
                .Scheduled: scheduled,
                .Trashed: trashed,
                .Published: published]
    }
    
    private func noResultsMessageText() -> String {
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
            message = NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views drafts in the pages list and there are no pages")
            break
        case .Scheduled:
            message = NSLocalizedString("Would you like to schedule a draft to publish?", comment: "Displayed when the user views scheduled pages in the oages list and there are no pages")
            break
        case .Trashed:
            message = NSLocalizedString("Everything you write is solid gold.", comment: "Displayed when the user views trashed pages in the pages list and there are no pages")
            break
        default:
            message = NSLocalizedString("Would you like to publish your first page?", comment: "Displayed when the user views published pages in the pages list and there are no pages")
            break
        }
        
        return message
    }
    
    
    private func noResultsButtonText() -> String? {
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
        case .Trashed:
            title = ""
            break
        default:
            title = NSLocalizedString("Start a Page", comment: "Button title, encourages users to create their first page on their blog.")
            break
        }
        
        return title
    }
    
    private func configureAuthorFilter() {
        // Noop
    }
    
    // MARK: - Sync Methods
    
    override internal func postTypeToSync() -> String {
        return PostServiceTypePage
    }
    
    override internal func lastSyncDate() -> NSDate? {
        return blog?.lastPagesSync
    }
    
    // MARK: - TableView Handler Delegate Methods
    
    private func entityName() -> String {
        return String(Page.self)
    }
    
    
    private func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()
        
        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && original = nil", blog)
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
        
        if let searchText = searchText where searchText.characters.count > 0 {
            let searchPredicate = NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText)
            predicates.append(searchPredicate)
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }
    
    // MARK: - Table View Handling

    func sectionNameKeyPath() -> String {
        return NSStringFromSelector(#selector(Page.sectionIdentifier))
    }
    
    private func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(self.dynamicType.pageCellEstimatedRowHeight)
    }
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if let page = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) {
            if cellIdentifierForPage(page) == self.dynamicType.restorePageCellIdentifier {
                return CGFloat(self.dynamicType.pageCellEstimatedRowHeight)
            }
            
            let width = CGRectGetWidth(tableView.bounds)
            return self.tableView(tableView, heightForRowAtIndexPath: indexPath, forWidth: width)
        } else {
            return 0
        }
    }
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath, forWidth width: CGFloat) -> CGFloat {
        configureCell(cellForLayout, atIndexPath: indexPath)
        let size = cellForLayout.sizeThatFits(CGSizeMake(width, CGFloat.max))
        let height = ceil(size.height)
        
        return height
    }
    
    private func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(self.dynamicType.pageSectionHeaderHeight)
    }
    
    private func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    private func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView! {
        let sectionInfo = tableViewHandler?.resultsController.sections?[section]
        let nibName = NSStringFromClass(PageListSectionHeaderView.self)
        let headerView = NSBundle.mainBundle().loadNibNamed(nibName, owner: nil, options: nil)[0] as! PageListSectionHeaderView
        
        if let sectionInfo = sectionInfo {
            headerView.setTite(sectionInfo.name)
        }
        
        return headerView
    }
    
    private func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView! {
        return UIView(frame: CGRectZero)
    }
    
    private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let post = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) as? AbstractPost else {
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
        
        editPage(post)
    }
    
    private func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let page = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) as! Post
        
        let identifier = cellIdentifierForPost(page)
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        cell.accessoryType = .None
        cell.selectionStyle = .None
        
        if let pageCell = cell as? PageListTableViewCell {
            pageCell.delegate = self
            
            if let page = tableViewHandler?.resultsController.objectAtIndexPath(indexPath) as? Page {
                pageCell.configureCell(page)
            }
        }
    }
    
    private func cellIdentifierForPage(page: Page) -> String {
        var identifier : String
        
        if recentlyTrashedPostObjectIDs?.containsObject(page.objectID) == true && currentPostListFilter()?.filterType != .Trashed {
            identifier = self.dynamicType.restorePageCellIdentifier
        } else {
            identifier = self.dynamicType.pageCellIdentifier
        }
        
        return identifier
    }
    
    // MARK: - Post Actions
    
    private func createPost() {
        if EditPageViewController.isNewEditorEnabled() {
            createPostInNewEditor()
        } else {
            createPostInOldEditor()
        }
    }
}

/*
#pragma mark - Instance Methods

#pragma mark - Post Actions

- (void)createPost
{
    UINavigationController *navController;
    
    if ([EditPageViewController isNewEditorEnabled]) {
        EditPageViewController *postViewController = [[EditPageViewController alloc] initWithDraftForBlog:self.blog];
        navController = [[UINavigationController alloc] initWithRootViewController:postViewController];
        navController.restorationIdentifier = WPEditorNavigationRestorationID;
        navController.restorationClass = [EditPageViewController class];
    } else {
        WPLegacyEditPageViewController *editPostViewController = [[WPLegacyEditPageViewController alloc] initWithDraftForLastUsedBlog];
        navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPageViewController class];
    }
    
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:navController animated:YES completion:nil];
    
    [WPAppAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{@"tap_source": @"posts_view"} withBlog:self.blog];
    }
    
    - (void)editPage:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListEditAction withProperties:[self propertiesForAnalytics]];
    if ([EditPageViewController isNewEditorEnabled]) {
        EditPageViewController *pageViewController = [[EditPageViewController alloc] initWithPost:apost
            mode:kWPPostViewControllerModePreview];
        [self.navigationController pushViewController:pageViewController animated:YES];
    } else {
        // In legacy mode, view means edit
        WPLegacyEditPageViewController *editPageViewController = [[WPLegacyEditPageViewController alloc] initWithPost:apost];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPageViewController];
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPageViewController class];
        
        [self presentViewController:navController animated:YES completion:nil];
    }
    }
    
    - (void)draftPage:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListDraftAction withProperties:[self propertiesForAnalytics]];
    NSString *previousStatus = apost.status;
    apost.status = PostStatusDraft;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService uploadPost:apost
        success:nil
        failure:^(NSError *error) {
        apost.status = previousStatus;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        [WPError showXMLRPCErrorAlert:error];
        }];
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


#pragma mark - Filter related

- (NSString *)keyForCurrentListStatusFilter
{
    return CurrentPageListStatusFilterKey;
}


#pragma mark - Cell Delegate Methods

- (void)cell:(UITableViewCell *)cell receivedMenuActionFromButton:(UIButton *)button forProvider:(id<PostContentProvider>)contentProvider
{
    Page *page = (Page *)contentProvider;
    NSManagedObjectID *objectID = page.objectID;
    
    NSString *viewButtonTitle = NSLocalizedString(@"View", @"Label for a button that opens the page when tapped.");
    NSString *draftButtonTitle = NSLocalizedString(@"Move to Draft", @"Label for a button that moves a page to the draft folder");
    NSString *publishButtonTitle = NSLocalizedString(@"Publish Immediately", @"Label for a button that moves a page to the published folder, publishing with the current date/time.");
    NSString *trashButtonTitle = NSLocalizedString(@"Move to Trash", @"Label for a button that moves a page to the trash folder");
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Label for a cancel button");
    NSString *deleteButtonTitle = NSLocalizedString(@"Delete Permanently", @"Label for a button permanently deletes a page.");
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addCancelActionWithTitle:cancelButtonTitle handler:nil];
    PostListStatusFilter filter = [self currentPostListFilter].filterType;
    if (filter == PostListStatusFilterTrashed) {
        [alertController addActionWithTitle:publishButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self publishPost:page];
            }];
        [alertController addActionWithTitle:draftButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self draftPage:page];
            }];
        [alertController addActionWithTitle:deleteButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self deletePost:page];
            }];
        
    } else if (filter == PostListStatusFilterPublished) {
        [alertController addActionWithTitle:viewButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self viewPost:page];
            }];
        [alertController addActionWithTitle:draftButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self draftPage:page];
            }];
        [alertController addActionWithTitle:trashButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self deletePost:page];
            }];
        
    } else {
        // draft or scheduled
        [alertController addActionWithTitle:viewButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self viewPost:page];
            }];
        [alertController addActionWithTitle:publishButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self publishPost:page];
            }];
        [alertController addActionWithTitle:trashButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Page *page = [self pageForObjectID:objectID];
            [self deletePost:page];
            }];
    }
    
    [WPAnalytics track:WPAnalyticsStatPostListOpenedCellMenu withProperties:[self propertiesForAnalytics]];
    
    if (![UIDevice isPad]) {
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:alertController  animated:YES completion:nil];
    UIPopoverPresentationController *presentationController = alertController.popoverPresentationController;
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.sourceView = button;
    presentationController.sourceRect = button.bounds;
    }
    
    - (Page *)pageForObjectID:(NSManagedObjectID *)objectID
{
    NSError *error;
    Page *page = (Page *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
    if (error) {
        DDLogError(@"%@, %@, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
    }
    return page;
    }
    
    - (void)cell:(UITableViewCell *)cell receivedRestoreActionForProvider:(id<PostContentProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self restorePost:apost];
}

@end

*/