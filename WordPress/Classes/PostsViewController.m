
#import "WPTableViewControllerSubclass.h"
#import "PostsViewController.h"
#import "EditPostViewController.h"
#import "PostTableViewCell.h"
#import "NewPostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"
#import "Post.h"
#import "Constants.h"

#define TAG_OFFSET 1010

@interface PostsViewController () {
    BOOL _addingNewPost;
}

@end

@implementation PostsViewController

@synthesize anyMorePosts, drafts;
//@synthesize resultsController;

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

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Posts", @"");

    UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showAddPostView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *composeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:composeButtonItem forNavigationItem:self.navigationItem];
    
    self.infiniteScrollEnabled = YES;
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [WPMobileStats flagProperty:[self statsPropertyForViewOpening] forEvent:StatsEventAppClosed];
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
    if (_addingNewPost) {
        [self.tableView setContentOffset:CGPointZero animated:NO];
        _addingNewPost = NO;
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setEditing:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)statsPropertyForViewOpening
{
    return StatsPropertyPostsOpened;
}


#pragma mark -
#pragma mark Syncs methods

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
    [self.blog syncPostsWithSuccess:success failure:failure loadMore:YES];
}

#pragma mark -
#pragma mark TableView delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (void)configureCell:(NewPostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {    
    Post *apost = (Post*) [self.resultsController objectAtIndexPath:indexPath];
    cell.post = apost;
	if (cell.post.remoteStatus == AbstractPostRemoteStatusPushing) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} else {
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
	if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
		// Don't allow editing while pushing changes
		return;
	}

    [self editPost:post];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
    CGFloat width = MIN(WPTableViewFixedWidth, CGRectGetWidth(tableView.frame));
    return [NewPostTableViewCell rowHeightForPost:post andWidth:width];
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

- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath{
    Post *post = [self.resultsController objectAtIndexPath:indexPath];
    [post deletePostWithSuccess:nil failure:^(NSError *error) {
		if([error code] == 403) {
			[self promptForPassword];
		} else {
            [WPError showXMLRPCErrorAlert:error];
		}
        [self syncItems];
    }];
}

- (void)showAddPostView {
    [WPMobileStats trackEventForWPCom:StatsEventPostsClickedNewPost];

    _addingNewPost = YES;
    Post *post = [Post newDraftForBlog:self.blog];
    [self editPost:post];
}

- (void)editPost:(AbstractPost *)apost {
    EditPostViewController *editPostViewController = [[EditPostViewController alloc] initWithPost:apost];
    editPostViewController.editorOpenedBy = StatsPropertyPostDetailEditorOpenedOpenedByPostsView;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.view.window.rootViewController presentViewController:navController animated:YES completion:nil];
}

- (void)setBlog:(Blog *)blog {
    [super setBlog:blog];
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
    if (userInteraction) {
        // If triggered by a pull to refresh, sync posts and metadata
        [self.blog syncPostsAndMetadataWithSuccess:success failure:failure];
    } else {
        // If blog has no posts, then sync posts including metadata
        if (self.blog.posts.count == 0) {
            [self.blog syncPostsAndMetadataWithSuccess:success failure:failure];
        } else {
            [self.blog syncPostsWithSuccess:success failure:failure loadMore:NO];
        }
    }
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
        if (_addingNewPost && NSOrderedSame == [indexPath compare:[NSIndexPath indexPathForRow:0 inSection:0]]) {
            _addingNewPost = NO;
        }
    }
}

- (BOOL)userCanCreateEntity {
	return YES;
}


@end
