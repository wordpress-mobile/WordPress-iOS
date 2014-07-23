#import "WPTableViewControllerSubclass.h"
#import "PostsViewController.h"
#import "EditPostViewController.h"
#import "PostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"
#import "Post.h"
#import "Constants.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPTableImageSource.h"

#define TAG_OFFSET 1010

@interface PostsViewController () <PostContentViewDelegate, UIAlertViewDelegate> {
    BOOL _addingNewPost;
}

@property (strong, nonatomic) NSIndexPath *indexPathToBeDeleted;

@end

@implementation PostsViewController

@synthesize drafts;

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

    UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showAddPostView) forControlEvents:UIControlEventTouchUpInside];
    button.accessibilityLabel = [self newPostAccessibilityLabel];
    button.accessibilityIdentifier = @"addpost";
    UIBarButtonItem *composeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:composeButtonItem forNavigationItem:self.navigationItem];
    
    self.infiniteScrollEnabled = YES;
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncPostsForBlog:self.blog success:success failure:failure loadMore:YES];
}

#pragma mark -
#pragma mark TableView delegate

- (void)configureCell:(PostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Post *post = (Post *) [self.resultsController objectAtIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;

    [cell configureCell:post];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];
    [self setImageForPost:post forCell:cell indexPath:indexPath];

    cell.postView.delegate = self;
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
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
    [WPAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"posts_view" }];

    _addingNewPost = YES;
    Post *post = [Post newDraftForBlog:self.blog];
    [self editPost:post];
}

- (void)editPost:(AbstractPost *)apost {
    EditPostViewController *editPostViewController = [[EditPostViewController alloc] initWithPost:apost];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];
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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    //Re-sync media, in case new media was added server-side
    [blogService syncMediaLibraryForBlog:self.blog success:nil failure:nil];

    if (userInteraction) {
        // If triggered by a pull to refresh, sync posts and metadata
        [blogService syncPostsAndMetadataForBlog:self.blog success:success failure:failure];
    } else {
        // If blog has no posts, then sync posts including metadata
        if (self.blog.posts.count == 0) {
            [blogService syncPostsAndMetadataForBlog:self.blog success:success failure:failure];
        } else {
            [blogService syncPostsForBlog:self.blog success:success failure:failure loadMore:NO];
        }
    }
}

- (Class)cellClass {
    return [PostTableViewCell class];
}

#pragma mark - NSFetchedResultsController overrides

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [super controllerDidChangeContent:controller];
    // Index paths may have changed. We don't want callbacks for stale paths.
    [self.featuredImageSource invalidateIndexPaths];
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

    if (type == NSFetchedResultsChangeInsert || type == NSFetchedResultsChangeDelete) {
        [self.cachedRowHeights removeAllObjects];
    }
}

- (BOOL)userCanCreateEntity {
	return YES;
}

#pragma mark - Instance Methods

- (void)setAvatarForPost:(Post *)post forCell:(PostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if ([cell isEqual:self.cellForLayout]) {
        return;
    }

    CGSize imageSize = CGSizeMake(WPContentViewAuthorAvatarSize, WPContentViewAuthorAvatarSize);
    UIImage *image = [post cachedAvatarWithSize:imageSize];
    if (image) {
        [cell.postView setAvatarImage:image];
    } else {
        [cell.postView setAvatarImage:[UIImage imageNamed:@"gravatar"]];
        [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            if (!image) {
                return;
            }
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell.postView setAvatarImage:image];
            }
        }];
    }
}

#pragma mark - PostContentView delegate methods

- (void)postView:(PostContentView *)postView didReceiveEditAction:(id)sender {
    PostTableViewCell *cell = (PostTableViewCell *)[PostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
    if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
        // Don't allow editing while pushing changes
        return;
    }

    [self editPost:post];
}

- (void)postView:(PostContentView *)postView didReceiveDeleteAction:(id)sender {
    PostTableViewCell *cell = (PostTableViewCell *)[PostTableViewCell cellForSubview:sender];
    self.indexPathToBeDeleted = [self.tableView indexPathForCell:cell];

    NSString *message = NSLocalizedString(@"Are you sure you wish to move this post to trash?", nil);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Post", nil)
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Delete Post", nil), nil];
    [alertView show];
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        self.indexPathToBeDeleted = nil;
    }
    else if (buttonIndex == 1) {
        if (self.indexPathToBeDeleted) {
            [self deletePostAtIndexPath:self.indexPathToBeDeleted];
            self.indexPathToBeDeleted = nil;
        }
    }
}

@end
