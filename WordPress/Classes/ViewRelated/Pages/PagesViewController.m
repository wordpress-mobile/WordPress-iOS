#import "PagesViewController.h"
#import "EditPageViewController.h"
#import "WPLegacyEditPageViewController.h"
#import "WPTableViewControllerSubclass.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "PageSettingsViewController.h"

#define TAG_OFFSET 1010

@interface PagesViewController (PrivateMethods)
- (void)syncFinished;
- (BOOL)isSyncing;
@end

@implementation PagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Pages", @"");
}

- (NSString *)noResultsTitleText
{
    return NSLocalizedString(@"You haven't created any pages yet", @"Displayed when the user pulls up the pages view and they have no pages");
}

- (NSString *)noResultsMessageText
{
    return NSLocalizedString(@"Would you like to create your first page?",  @"Displayed when the user pulls up the pages view and they have no pages");
}

- (UIView *)noResultsAccessoryView
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"penandink"]];
}

- (NSString *)noResultsButtonText
{
    return NSLocalizedString(@"Create page", @"");
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    [self showAddPostView];
}

- (NSString *)newPostAccessibilityLabel
{
    return NSLocalizedString(@"New Page", @"The accessibility value of the new page button.");
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction
                            success:(void (^)())success
                            failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    __block BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    [blogService syncPagesForBlog:self.blog
                          success:^{
                              blogService = nil;
                          }
                          failure:^(NSError *error) {
                              blogService = nil;
                          }
                         loadMore:NO];
}

- (void)editPost:(AbstractPost *)apost
{
    UINavigationController *navController;
    if ([WPPostViewController isNewEditorEnabled]) {
        EditPageViewController *editPageiewController = [[EditPageViewController alloc] initWithPost:apost
                                                                                                 mode:kWPPostViewControllerModeEdit];
        navController = [[UINavigationController alloc] initWithRootViewController:editPageiewController];
        navController.restorationIdentifier = WPEditorNavigationRestorationID;
        navController.restorationClass = [WPPostViewController class];
    } else {
        WPLegacyEditPageViewController *editPageViewController = [[WPLegacyEditPageViewController alloc] initWithPost:apost];
        navController = [[UINavigationController alloc] initWithRootViewController:editPageViewController];
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPostViewController class];
    }
    
	[navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
	navController.modalPresentationStyle = UIModalPresentationCurrentContext;
	[self.view.window.rootViewController presentViewController:navController animated:YES completion:nil];
}

- (void)viewPost:(AbstractPost *)apost
{
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *pageViewController = [[EditPageViewController alloc] initWithPost:apost
                                                                                         mode:kWPPostViewControllerModePreview];
        pageViewController.restorationIdentifier = WPEditorNavigationRestorationID;
        self.navigationController.restorationClass = [EditPageViewController class];
        [self.navigationController pushViewController:pageViewController animated:YES];
    } else {
        // In legacy mode, view means edit
        WPLegacyEditPageViewController *editPageViewController = [[WPLegacyEditPageViewController alloc] initWithPost:apost];
        editPageViewController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPageViewController];
        [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
        navController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self.view.window.rootViewController presentViewController:navController animated:YES completion:nil];
    }
}

- (void)showAddPostView {
    Page *post = [Page newDraftForBlog:self.blog];
    [self editPost:post];
}

- (Class)classForSettingsViewController {
    return [PageSettingsViewController class];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

#pragma mark -
#pragma mark Syncs methods

- (BOOL)isSyncing
{
    return self.blog.isSyncingPages;
}

- (NSDate *) lastSyncDate
{
    return self.blog.lastPagesSync;
}

- (BOOL) hasOlderItems
{
    return [self.blog.hasOlderPages boolValue];
}

- (BOOL)refreshRequired
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"refreshPagesRequired"]) {
        [defaults setBool:NO forKey:@"refreshPagesRequired"];
        return YES;
    }

    return NO;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncPagesForBlog:self.blog
                          success:success
                          failure:failure
                         loadMore:YES];
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName
{
    return @"Page";
}

@end
