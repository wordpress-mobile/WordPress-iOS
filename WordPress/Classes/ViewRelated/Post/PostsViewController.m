#import "WPTableViewControllerSubclass.h"
#import "PostsViewController.h"
#import "WPLegacyEditPostViewController.h"
#import "WPPostViewController.h"
#import "NewPostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"
#import "Post.h"
#import "Constants.h"
#import "BlogService.h"
#import "PostService.h"
#import "ContextManager.h"

#define TAG_OFFSET 1010

@interface PostsViewController ()
@property (nonatomic, assign, readwrite) BOOL addingNewPost;
@end

@implementation PostsViewController

@synthesize anyMorePosts, drafts;

#pragma mark -
#pragma mark View lifecycle

- (NSString *)noResultsTitleText
{
    return NSLocalizedString(@"You haven't created any posts yet", @"Displayed when the user pulls up the posts view and they have no posts");
}

- (NSString *)noResultsMessageText {
    return NSLocalizedString(@"Would you like to create your first post?",  @"Displayed when the user pulls up the posts view and they have no posts");
}

- (UIView *)noResultsAccessoryView {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"penandink"]];
}

- (NSString *)noResultsButtonText
{
    return NSLocalizedString(@"Create post", @"");
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    [self showAddPostView];
}

- (NSString *)newPostAccessibilityLabel {
    return NSLocalizedString(@"New Post", @"The accessibility value of the new post button.");
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Posts", @"");
    self.tableView.accessibilityIdentifier = @"PostsTable";
    UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showAddPostView) forControlEvents:UIControlEventTouchUpInside];
    button.accessibilityLabel = [self newPostAccessibilityLabel];
    button.accessibilityIdentifier = @"New Post";
    UIBarButtonItem *composeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:composeButtonItem forNavigationItem:self.navigationItem];
    
    self.infiniteScrollEnabled = YES;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    // IMPORTANT: this code makes sure that the back button in WPPostViewController doesn't show
    // this VC's title.
    //
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:[NSString string] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    [self updatePostFormats];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (IS_IPHONE) {
		// iPhone table views should not appear selected
		if ([self.tableView indexPathForSelectedRow]) {
			[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
		}
	}
    
    // Scroll to the top of the UItableView to show the newly added post.
    if (self.addingNewPost) {
        [self.tableView setContentOffset:CGPointZero animated:NO];
        self.addingNewPost = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setEditing:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Syncs methods

- (BOOL)userCanRefresh
{
    AbstractPost *apost = [self.resultsController.fetchedObjects firstObject];
    if (apost.remoteStatus == AbstractPostRemoteStatusPushing) {
        return NO;
    }
    return [super userCanRefresh];
}

- (BOOL)isSyncing {
	return self.blog.isSyncingPosts;
}

- (NSDate *)lastSyncDate {
	return self.blog.lastPostsSync;
}

- (BOOL)hasMoreContent {
	return [self.blog.hasOlderPosts boolValue];
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    [postService loadMorePostsOfType:PostServiceTypePost forBlog:self.blog success:success failure:failure];
}

#pragma mark -
#pragma mark TableView delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Trash", @"The text that appears when a user swipes to 'delete' a post from the Posts list");
}

- (void)configureCell:(NewPostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {    
    Post *apost = (Post*) [self.resultsController objectAtIndexPath:indexPath];
    cell.contentProvider = apost;
	if (apost.remoteStatus == AbstractPostRemoteStatusPushing) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} else {
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessibilityIdentifier = @"PostCell";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
	if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
		// Don't allow editing while pushing changes
		return;
	}
    
    [self viewPost:post];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
    CGFloat width = MIN(WPTableViewFixedWidth, CGRectGetWidth(tableView.frame));
    return [NewPostTableViewCell rowHeightForContentProvider:post andWidth:width];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self deletePostAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Custom methods

- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [self.resultsController objectAtIndexPath:indexPath];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    [postService deletePost:post success:nil failure:^(NSError *error) {
        if([error code] == 403) {
            [self promptForPassword];
        } else {
            [WPError showXMLRPCErrorAlert:error];
        }
        [self syncItems];
    }];
}

- (void)showAddPostView
{
    [self newPost];
}

- (void)newPost
{
    self.addingNewPost = YES;
    
    UINavigationController *navController;
    
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *postViewController = [[WPPostViewController alloc] initWithDraftForBlog:self.blog];
        navController = [[UINavigationController alloc] initWithRootViewController:postViewController];
        navController.restorationIdentifier = WPEditorNavigationRestorationID;
        navController.restorationClass = [WPPostViewController class];
    } else {
        WPLegacyEditPostViewController *editPostViewController = [[WPLegacyEditPostViewController alloc] initWithDraftForLastUsedBlog];
        navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPostViewController class];
    }
    
    [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:navController animated:YES completion:nil];
    
    [WPAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"posts_view" }];
}

- (void)viewPost:(AbstractPost *)apost
{
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *postViewController = [[WPPostViewController alloc] initWithPost:apost
                                                                                         mode:kWPPostViewControllerModePreview];
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

- (void)setBlog:(Blog *)blog {
    [super setBlog:blog];
}

- (void)updatePostFormats
{    
    if (!self.isSyncing && (!self.blog.postFormats || self.blog.postFormats.count <= 1)) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        [blogService syncPostFormatsForBlog:self.blog success:nil failure:nil];
    }
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Post";
}

- (BOOL)refreshRequired {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"refreshPostsRequired"]) { 
		[defaults setBool:NO forKey:@"refreshPostsRequired"];
		return YES;
	}
	
	return NO;
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(blog == %@) && (original == nil)", self.blog];
    NSSortDescriptor *sortDescriptorLocal = [NSSortDescriptor sortDescriptorWithKey:@"remoteStatusNumber" ascending:YES];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorLocal, sortDescriptorDate];
    fetchRequest.fetchBatchSize = 10;
    return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
    return @"remoteStatusNumber";
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    [postService syncPostsOfType:PostServiceTypePost forBlog:self.blog success:success failure:failure];
}

- (Class)cellClass {
    return [NewPostTableViewCell class];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];

    if (type == NSFetchedResultsChangeDelete) {
        if (self.addingNewPost && NSOrderedSame == [indexPath compare:[NSIndexPath indexPathForRow:0 inSection:0]]) {
            self.addingNewPost = NO;
        }
    }
}

- (BOOL)userCanCreateEntity {
	return YES;
}


@end
