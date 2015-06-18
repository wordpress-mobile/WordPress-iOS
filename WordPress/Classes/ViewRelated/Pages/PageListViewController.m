#import "PageListViewController.h"

#import "AbstractPostListViewControllerSubclass.h"
#import "EditPageViewController.h"
#import "Page.h"
#import "PageListSectionHeaderView.h"
#import "PageListTableViewCell.h"
#import "WPLegacyEditPageViewController.h"

static const CGFloat PageSectionHeaderHeight = 24.0;
static const CGFloat PageCellEstimatedRowHeight = 44.0;
static NSString * const PagesViewControllerRestorationKey = @"PagesViewControllerRestorationKey";
static NSString * const PageCellIdentifier = @"PageCellIdentifier";
static NSString * const PageCellNibName = @"PageListTableViewCell";
static NSString * const RestorePageCellIdentifier = @"RestorePageCellIdentifier";
static NSString * const RestorePageCellNibName = @"RestorePageTableViewCell";
static NSString * const CurrentPageListStatusFilterKey = @"CurrentPageListStatusFilterKey";

@interface PageListViewController() <PageListTableViewCellDelegate, UIActionSheetDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) PageListTableViewCell *cellForLayout;
@property (nonatomic, strong) NSManagedObjectID *currentActionedPageObjectID;

@end

@implementation PageListViewController

#pragma mark - Lifecycle Methods

+ (instancetype)controllerWithBlog:(Blog *)blog
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Pages" bundle:[NSBundle mainBundle]];
    PageListViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"PageListViewController"];
    controller.blog = blog;
    controller.restorationClass = [self class];
    return controller;
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *blogID = [coder decodeObjectForKey:PagesViewControllerRestorationKey];
    if (!blogID) {
        return nil;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:blogID]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    Blog *restoredBlog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredBlog) {
        return nil;
    }

    return [self controllerWithBlog:restoredBlog];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:PagesViewControllerRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.postListViewController = segue.destinationViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Pages", @"Tile of the screen showing the list of pages for a blog.");
}


#pragma mark - Configuration

- (void)configureCellsForLayout
{
    self.cellForLayout = (PageListTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PageCellNibName owner:nil options:nil] firstObject];
}

- (void)configureTableView
{
    self.tableView.accessibilityIdentifier = @"PagesTable";
    self.tableView.isAccessibilityElement = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    // Register the cells
    UINib *pageCellNib = [UINib nibWithNibName:PageCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:pageCellNib forCellReuseIdentifier:PageCellIdentifier];

    UINib *restorePageCellNib = [UINib nibWithNibName:RestorePageCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:restorePageCellNib forCellReuseIdentifier:RestorePageCellIdentifier];
}

- (NSString *)noResultsTitleText
{
    if (self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching pages...", @"A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new pages.");
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
                   @(PostListStatusFilterScheduled):[NSString stringWithFormat:NSLocalizedString(@"No scheduled pages match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                   @(PostListStatusFilterTrashed):[NSString stringWithFormat:NSLocalizedString(@"No trashed pages match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                   @(PostListStatusFilterPublished):[NSString stringWithFormat:NSLocalizedString(@"No pages match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                   };
    } else {
        titles = @{
                   @(PostListStatusFilterDraft):NSLocalizedString(@"You don't have any drafts.", @"Displayed when the user views drafts in the pages list and there are no pages"),
                   @(PostListStatusFilterScheduled):NSLocalizedString(@"You don't have any scheduled pages.", @"Displayed when the user views scheduled pages in the pages list and there are no pages"),
                   @(PostListStatusFilterTrashed):NSLocalizedString(@"You don't have any pages in your trash folder.", @"Displayed when the user views trashed in the pages list and there are no pages"),
                   @(PostListStatusFilterPublished):NSLocalizedString(@"You haven't published any pages yet.", @"Displayed when the user views published pages in the pages list and there are no pages"),
                   };
    }
    return titles;
}

- (NSString *)noResultsMessageText
{
    if (self.syncHelper.isSyncing || [self isSearching]) {
        return [NSString string];
    }
    NSString *message;
    PostListFilter *filter = [self currentPostListFilter];
    switch (filter.filterType) {
        case PostListStatusFilterDraft:
            message = NSLocalizedString(@"Would you like to create one?", @"Displayed when the user views drafts in the pages list and there are no pages");
            break;
        case PostListStatusFilterScheduled:
            message = NSLocalizedString(@"Would you like to schedule a draft to publish?", @"Displayed when the user views scheduled pages in the oages list and there are no pages");
            break;
        case PostListStatusFilterTrashed:
            message = NSLocalizedString(@"Everything you write is solid gold.", @"Displayed when the user views trashed pages in the pages list and there are no pages");
            break;
        default:
            message = NSLocalizedString(@"Would you like to publish your first page?", @"Displayed when the user views published pages in the pages list and there are no pages");
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
        case PostListStatusFilterTrashed:
            title = [NSString string];
            break;
        default:
            title = NSLocalizedString(@"Start a Page", @"Button title, encourages users to create their first page on their blog.");
            break;
    }
    return title;
}

- (void)configureAuthorFilter
{
    // Noop
}


#pragma mark - Sync Methods

- (NSString *)postTypeToSync
{
    return PostServiceTypePage;
}


#pragma mark - TableView Handler Delegate Methods

- (NSString *)entityName
{
    return NSStringFromClass([Page class]);
}

- (NSPredicate *)predicateForFetchRequest
{
    NSMutableArray *predicates = [NSMutableArray array];

    NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"blog = %@ && original = nil", self.blog];
    [predicates addObject:basePredicate];

    NSString *searchText = [self currentSearchTerm];
    NSPredicate *filterPredicate = [self currentPostListFilter].predicateForFetchRequest;

    // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
    // or posts that were recently deleted.
    if ([searchText length] == 0 && [self.recentlyTrashedPostIDs count] > 0) {
        NSPredicate *trashedPredicate = [NSPredicate predicateWithFormat:@"postID IN %@", self.recentlyTrashedPostIDs];
        filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[filterPredicate, trashedPredicate]];
    }
    [predicates addObject:filterPredicate];

    if ([searchText length] > 0) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"postTitle CONTAINS[cd] %@", searchText];
        [predicates addObject:searchPredicate];
    }

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    return predicate;
}


#pragma mark - Table View Handling

- (NSString *)sectionNameKeyPath
{
    return NSStringFromSelector(@selector(sectionIdentifier));
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PageCellEstimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Page *page = (Page *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([[self cellIdentifierForPage:page] isEqualToString:RestorePageCellIdentifier]) {
        return PageCellEstimatedRowHeight;
    }
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return PageSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.tableViewHandler.resultsController.sections objectAtIndex:section];
    NSString *nibName = NSStringFromClass([PageListSectionHeaderView class]);
    PageListSectionHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] firstObject];
    [headerView setTite:sectionInfo.name];

    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AbstractPost *apost = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if (apost.remoteStatus == AbstractPostRemoteStatusPushing) {
        // Don't allow editing while pushing changes
        return;
    }

    if ([apost.status isEqualToString:PostStatusTrash]) {
        // No editing posts that are trashed.
        return;
    }

    [self editPage:apost];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Page *page = (Page *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    NSString *identifier = [self cellIdentifierForPage:page];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    PageListTableViewCell *pageCell = (PageListTableViewCell *)cell;
    pageCell.delegate = self;
    Page *page = (Page *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    [pageCell configureCell:page];
}

- (NSString *)cellIdentifierForPage:(Page *)page
{
    NSString *identifier;
    if ([self.recentlyTrashedPostIDs containsObject:page.postID] && [self currentPostListFilter].filterType != PostListStatusFilterTrashed) {
        identifier = RestorePageCellIdentifier;
    } else {
        identifier = PageCellIdentifier;
    }
    return identifier;
}


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

    [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
    navController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:navController animated:YES completion:nil];

    [WPAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"posts_view" }];
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
        [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")
                                              otherButtonTitles:nil, nil];
    [alertView show];
}


#pragma mark - Filter related

- (NSString *)keyForCurrentListStatusFilter
{
    return CurrentPageListStatusFilterKey;
}


#pragma mark - Cell Delegate Methods

- (void)cell:(UITableViewCell *)cell receivedMenuActionFromButton:(UIButton *)button forProvider:(id<WPContentViewProvider>)contentProvider
{
    Page *page = (Page *)contentProvider;
    self.currentActionedPageObjectID = page.objectID;

    NSString *viewButtonTitle = NSLocalizedString(@"View", @"Label for a button that opens the page when tapped.");
    NSString *draftButtonTitle = NSLocalizedString(@"Move to Draft", @"Label for a button that moves a page to the draft folder");
    NSString *publishButtonTitle = NSLocalizedString(@"Publish Immediately", @"Label for a button that moves a page to the published folder, publishing with the current date/time.");
    NSString *trashButtonTitle = NSLocalizedString(@"Move to Trash", @"Label for a button that moves a page to the trash folder");
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Label for a cancel button");
    NSString *deleteButtonTitle = NSLocalizedString(@"Delete Permanently", @"Label for a button permanently deletes a page.");

    UIActionSheet *actionSheet;
    PostListStatusFilter filter = [self currentPostListFilter].filterType;
    if (filter == PostListStatusFilterTrashed) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:cancelButtonTitle
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:publishButtonTitle, draftButtonTitle, deleteButtonTitle, nil];
    } else if (filter == PostListStatusFilterPublished) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelButtonTitle
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:viewButtonTitle, draftButtonTitle, trashButtonTitle, nil];
    } else {
        // draft or scheduled
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelButtonTitle
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:viewButtonTitle, publishButtonTitle, trashButtonTitle, nil];
    }
    CGRect frame = CGRectZero;
    frame.size = button.bounds.size;
    [actionSheet showFromRect:frame inView:button animated:YES];
    [WPAnalytics track:WPAnalyticsStatPostListOpenedCellMenu withProperties:[self propertiesForAnalytics]];
}

- (void)cell:(UITableViewCell *)cell receivedRestoreActionForProvider:(id<WPContentViewProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self restorePost:apost];
}


#pragma mark - UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    NSError *error;
    Page *page = (Page *)[self.managedObjectContext existingObjectWithID:self.currentActionedPageObjectID error:&error];
    if (error) {
        DDLogError(@"%@, %@, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
    }

    PostListStatusFilter filter = [self currentPostListFilter].filterType;

    if (buttonIndex == 0) {

        if (filter == PostListStatusFilterTrashed) {
            // publish action
            [self publishPost:page];
        } else {
            // view action
            [self viewPost:page];
        }

    } else if (buttonIndex == 1) {

        if (filter == PostListStatusFilterPublished || filter == PostListStatusFilterTrashed) {
            // draft action
            [self draftPage:page];
        } else {
            // publish action
            [self publishPost:page];
        }

    } else if (buttonIndex == 2) {
        [self deletePost:page];
    }

}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.currentActionedPageObjectID = nil;
}

@end
