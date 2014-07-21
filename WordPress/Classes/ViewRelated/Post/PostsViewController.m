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

#define TAG_OFFSET 1010

@interface PostsViewController () {
    BOOL _addingNewPost;
}

@property (nonatomic, strong) PostTableViewCell *cellForLayout;
@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;

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

    [self configureCellForLayout];

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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (void)configureCell:(PostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Post *post = (Post *) [self.resultsController objectAtIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;

    [cell configureCell:post];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    return ceil(size.height + 1);
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

#pragma mark - Instance Methods

- (void)configureCellForLayout
{
    NSString *CellIdentifier = @"CellForLayoutIdentifier";
    [self.tableView registerClass:[PostTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self updateCellForLayoutWidthConstraint:CGRectGetWidth(self.tableView.bounds)];
}

- (void)updateCellForLayoutWidthConstraint:(CGFloat)width
{
    UIView *contentView = self.cellForLayout.contentView;
    if (self.cellForLayoutWidthConstraint) {
        [contentView removeConstraint:self.cellForLayoutWidthConstraint];
    }
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
    NSDictionary *metrics = @{@"width":@(width)};
    self.cellForLayoutWidthConstraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(width)]"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views] firstObject];
    [contentView addConstraint:self.cellForLayoutWidthConstraint];
}

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

@end
