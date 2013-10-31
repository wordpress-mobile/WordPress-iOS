
#import "WPTableViewControllerSubclass.h"
#import "PostsViewController.h"
#import "EditPostViewController.h"
#import "PostTableViewCell.h"
#import "NewPostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"
#import "PanelNavigationConstants.h"

#define TAG_OFFSET 1010

@implementation PostsViewController

@synthesize postReaderViewController;
@synthesize anyMorePosts, selectedIndexPath, drafts;
//@synthesize resultsController;

#pragma mark -
#pragma mark View lifecycle

- (id)init {
    self = [super init];
    if(self) {
        self.title = NSLocalizedString(@"Posts", @"");
    }
    return self;
}

- (NSString *)noResultsText
{
    return NSLocalizedString(@"No posts yet", @"Displayed when the user pulls up the posts view and they have no posts");
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];
    
	// ShouldRefreshPosts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableAfterDraftSaved:) name:@"DraftsUpdated" object:nil];
    
    UIBarButtonItem *composeButtonItem  = nil;
    
    if ([self.editButtonItem respondsToSelector:@selector(setTintColor:)]) {
        composeButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navbar_add"]
                                                             style:[WPStyleGuide barButtonStyleForBordered]
                                                             target:self 
                                                             action:@selector(showAddPostView)];
    } else {
        composeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                           target:self 
                                                                           action:@selector(showAddPostView)];
    }
    if ([composeButtonItem respondsToSelector:@selector(setTintColor:)]) {
        composeButtonItem.tintColor = [UIColor UIColorFromHex:0x333333];
    }
    if (IS_IOS7) {
        UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showAddPostView) forControlEvents:UIControlEventTouchUpInside];
        composeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:composeButtonItem forNavigationItem:self.navigationItem];
    
    if (IS_IPAD && self.selectedIndexPath && self.postReaderViewController) {
        @try {
            self.postReaderViewController.post = [self.resultsController objectAtIndexPath:self.selectedIndexPath];
            [self.postReaderViewController refreshUI];
        }
        @catch (NSException * e) {
            // In some cases, selectedIndexPath could be pointing to a missing row
            // This is the case after a failed core data upgrade
            self.selectedIndexPath = nil;
        }
    }
    
    self.infiniteScrollEnabled = YES;
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarOpened) name:SidebarOpenedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [WPMobileStats flagProperty:[self statsPropertyForViewOpening] forEvent:StatsEventAppClosed];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
    self.panelNavigationController.delegate = self;

	if (!IS_IPAD) {
		// iPhone table views should not appear selected
		if ([self.tableView indexPathForSelectedRow]) {
			[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
		}
	} else if (IS_IPAD) {
		// sometimes, iPad table views should
		if (self.selectedIndexPath) {
            [self showSelectedPost];
			[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			[self.tableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
		} else {
			//There are no content yet, push an the WP logo on the right.  
			WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate]; 
			[delegate showContentDetailViewController:nil];
		}
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:NO];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.panelNavigationController.delegate = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIColor *)backgroundColorForRefreshHeaderView
{
    return [WPStyleGuide itsEverywhereGrey];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;
    
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (NSString *)statsPropertyForViewOpening
{
    return StatsPropertyPostsOpened;
}

- (void)sidebarOpened {
    self.tableView.editing = NO;
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

#pragma mark - DetailViewDelegate

- (void)resetView {
    //Reset a few things if extra panels were popped off on the iPad
    if (self.selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath: self.selectedIndexPath animated: NO];
        self.selectedIndexPath = nil;
    }
}

#pragma mark -
#pragma mark TableView delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
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
    return [NewPostTableViewCell rowHeightForPost:post andWidth:CGRectGetWidth(self.tableView.bounds)];
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
        NSDictionary *errInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.blog, @"currentBlog", nil];
		if([error code] == 403) {
			[self promptForPassword];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:kXML_RPC_ERROR_OCCURS object:error userInfo:errInfo];
		}
        [self syncItemsWithUserInteraction:NO];
        if(IS_IPAD && self.postReaderViewController) {
            if(self.postReaderViewController.apost == post) {
                //push an the W logo on the right. 
                WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
                [delegate showContentDetailViewController:nil];
                self.selectedIndexPath = nil;
            }
        }
    }];
}

- (void)reselect {
	if (self.selectedIndexPath) {
		[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self tableView:self.tableView didSelectRowAtIndexPath:self.selectedIndexPath];
	}
}

- (void)showAddPostView {
    [WPMobileStats trackEventForWPCom:StatsEventPostsClickedNewPost];

    if (IS_IPAD)
        [self resetView];
    
    Post *post = [Post newDraftForBlog:self.blog];
    [self editPost:post];
}

- (void)editPost:(AbstractPost *)apost {
    EditPostViewController *editPostViewController = [[EditPostViewController alloc] initWithPost:[apost createRevision]];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.panelNavigationController.detailViewController presentViewController:navController animated:YES completion:nil];
}

// For iPad
// Subclassed in PagesViewController
- (void)showSelectedPost {
    Post *post = nil;
    NSIndexPath *indexPath = self.selectedIndexPath;

    @try {
        post = [self.resultsController objectAtIndexPath:indexPath];
        DDLogInfo(@"Selected post at indexPath: (%i,%i)", indexPath.section, indexPath.row);
    }
    @catch (NSException *e) {
        DDLogError(@"Can't select post at indexPath (%i,%i)", indexPath.section, indexPath.row);
        DDLogError(@"sections: %@", self.resultsController.sections);
        DDLogError(@"results: %@", self.resultsController.fetchedObjects);
        post = nil;
    }
    self.postReaderViewController = [[PostViewController alloc] initWithPost:post];
    [self.panelNavigationController.navigationController pushViewController:self.postReaderViewController animated:YES];
}

- (void)setSelectedIndexPath:(NSIndexPath *)indexPath {
    if ([selectedIndexPath isEqual:indexPath]) {
        if (self.panelNavigationController) {
            [self.panelNavigationController viewControllerWantsToBeFullyVisible:self];
        }
    } else {
        WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

        if (indexPath != nil) {
            @try {
                [self.resultsController objectAtIndexPath:indexPath];
                selectedIndexPath = indexPath;
                [self showSelectedPost];
            }
            @catch (NSException *exception) {
                selectedIndexPath = nil;
                [delegate showContentDetailViewController:nil];
            }
        } else {
            selectedIndexPath = nil;
            if (IS_IPHONE == NO) //Fixes #1292. popToViewController:animated was called twice
                [delegate showContentDetailViewController:nil];
        }
    }
}

- (void)setBlog:(Blog *)blog {
    [super setBlog:blog];
    self.selectedIndexPath = nil;
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

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    // If triggered by a pull to refresh, sync categories, post formats, ...
    if (userInteraction) {
        [self.blog syncBlogPostsWithSuccess:success failure:failure];
    } else {
        [self.blog syncPostsWithSuccess:success failure:failure loadMore:NO];
    }
}

- (UITableViewCell *)newCell {
    static NSString *const cellIdentifier = @"PostCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[NewPostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        if (!IS_IOS7) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
            [cell setBackgroundView:imageView];
        }
    }
    return cell;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];

    if (type == NSFetchedResultsChangeDelete) {
        if ([indexPath compare:selectedIndexPath] == NSOrderedSame) {
            self.selectedIndexPath = nil;
        }
    }
}

- (BOOL)userCanCreateEntity {
	return YES;
}


@end
