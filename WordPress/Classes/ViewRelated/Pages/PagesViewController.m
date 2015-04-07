#import "PagesViewController.h"
#import "EditPageViewController.h"
#import "WPLegacyEditPageViewController.h"
#import "WPTableViewControllerSubclass.h"
#import "BlogService.h"
#import "PostService.h"
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
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    [postService syncPostsOfType:PostServiceTypePage forBlog:self.blog success:success failure:failure];
}


- (void)showAddPostView
{
    [self newPost];
}

- (void)newPost
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

- (void)viewPost:(AbstractPost *)apost
{
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
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    [postService loadMorePostsOfType:PostServiceTypePage forBlog:self.blog success:success failure:failure];
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName
{
    return NSStringFromClass([Page class]);
}

@end
