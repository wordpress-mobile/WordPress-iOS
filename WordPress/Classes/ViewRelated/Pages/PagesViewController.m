#import "PagesViewController.h"
#import "EditPageViewController.h"
#import "WPTableViewControllerSubclass.h"
#import "BlogService.h"
#import "PostService.h"
#import "ContextManager.h"

#define TAG_OFFSET 1010

@interface PagesViewController (PrivateMethods)
- (void)syncFinished;
- (BOOL)isSyncing;
@end

@implementation PagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Pages", @"");
}

- (NSString *)noResultsTitleText
{
    return NSLocalizedString(@"You haven't created any pages yet", @"Displayed when the user pulls up the pages view and they have no pages");
}

- (NSString *)noResultsMessageText {
    return NSLocalizedString(@"Would you like to create your first page?",  @"Displayed when the user pulls up the pages view and they have no pages");
}

- (UIView *)noResultsAccessoryView {
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

- (NSString *)newPostAccessibilityLabel {
    return NSLocalizedString(@"New Page", @"The accessibility value of the new page button.");
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
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

// For iPhone
- (void)editPost:(AbstractPost *)apost {
    EditPageViewController *editPostViewController = [[EditPageViewController alloc] initWithPost:apost];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    [navController setToolbarHidden:NO]; // Fixes wrong toolbar icon animation.
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)showAddPostView {
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    Page *post = [postService createDraftPageForBlog:self.blog];
    [self editPost:post];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

#pragma mark -
#pragma mark Syncs methods

- (BOOL)isSyncing {
	return self.blog.isSyncingPages;
}

-(NSDate *) lastSyncDate {
	return self.blog.lastPagesSync;
}

- (BOOL) hasOlderItems {
	return [self.blog.hasOlderPages boolValue];
}

- (BOOL)refreshRequired {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"refreshPagesRequired"]) { 
		[defaults setBool:NO forKey:@"refreshPagesRequired"];
		return YES;
	}
	
	return NO;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncPagesForBlog:self.blog
                          success:success
                          failure:failure
                         loadMore:YES];
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Page";
}

@end
