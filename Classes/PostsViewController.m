
#import "WPTableViewControllerSubclass.h"
#import "PostsViewController.h"
#import "EditPostViewController.h"
#import "PostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"

#define TAG_OFFSET 1010

@interface PostsViewController (Private)

- (BOOL)handleAutoSavedContext:(NSInteger)tag;
- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath;
- (void)editPost:(AbstractPost *)apost;
- (void)showSelectedPost;
- (void)checkLastSyncDate;
- (void)syncFinished;

@end

@implementation PostsViewController

@synthesize postDetailViewController, postReaderViewController;
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


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

	// ShouldRefreshPosts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableAfterDraftSaved:) name:@"DraftsUpdated" object:nil];
    
    UIBarButtonItem *composeButtonItem  = nil;
    
    if (IS_IPHONE && [self.editButtonItem respondsToSelector:@selector(setTintColor:)]) {
        composeButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navbar_add"]style:UIBarButtonItemStyleBordered 
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
    if (!IS_IPAD) {
        self.navigationItem.rightBarButtonItem = composeButtonItem;
    } else {
        self.toolbarItems = [NSArray arrayWithObject:composeButtonItem];
    }
    
    
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
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Force a crash for CrashReporter
	//NSLog(@"crash time! %@", 1);
    
    self.panelNavigationController.delegate = self;
		
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.postID = nil;

	if (IS_IPAD == NO) {
		// iPhone table views should not appear selected
		if ([self.tableView indexPathForSelectedRow]) {
			[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
		}
	} else if (IS_IPAD == YES) {
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

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;
    
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
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
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSString *sectionName = [sectionInfo name];
    
    return [Post titleForRemoteStatus:[sectionName numericValue]];
}

- (void)configureCell:(PostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    AbstractPost *apost = (AbstractPost*) [self.resultsController objectAtIndexPath:indexPath];
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
    if (IS_IPAD) {
        self.selectedIndexPath = indexPath;
    } else {
        [self editPost:post];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return POST_ROW_HEIGHT;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (IS_IPAD) {
        return NO;
    } else {
        return YES;
    }
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
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Custom methods

- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath{
    Post *post = [self.resultsController objectAtIndexPath:indexPath];
    [post deletePostWithSuccess:nil failure:^(NSError *error) {
        NSDictionary *errInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.blog, @"currentBlog", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kXML_RPC_ERROR_OCCURS object:error userInfo:errInfo];
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
	if (self.selectedIndexPath != NULL) {
		[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self tableView:self.tableView didSelectRowAtIndexPath:self.selectedIndexPath];
	}
}

- (void)showAddPostView {
    if (IS_IPAD)
        [self resetView];
    Post *post = [Post newDraftForBlog:self.blog];
    EditPostViewController *editPostViewController = [[EditPostViewController alloc] initWithPost:[post createRevision]];
    editPostViewController.editMode = kNewPost;
    [editPostViewController refreshUIForCompose];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.panelNavigationController presentModalViewController:navController animated:YES];
}

// For iPhone
- (void)editPost:(AbstractPost *)apost {
    EditPostViewController *editPostViewController = [[EditPostViewController alloc] initWithPost:[apost createRevision]];
    editPostViewController.editMode = kEditPost;
    [editPostViewController refreshUIForCurrentPost];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.panelNavigationController presentModalViewController:navController animated:YES];
}

// For iPad
// Subclassed in PagesViewController
- (void)showSelectedPost {
    Post *post = nil;
    NSIndexPath *indexPath = self.selectedIndexPath;

    @try {
        post = [self.resultsController objectAtIndexPath:indexPath];
        WPLog(@"Selected post at indexPath: (%i,%i)", indexPath.section, indexPath.row);
    }
    @catch (NSException *e) {
        NSLog(@"Can't select post at indexPath (%i,%i)", indexPath.section, indexPath.row);
        NSLog(@"sections: %@", self.resultsController.sections);
        NSLog(@"results: %@", self.resultsController.fetchedObjects);
        post = nil;
    }
    self.postReaderViewController = [[PostViewController alloc] initWithPost:post];
    [self.panelNavigationController pushViewController:self.postReaderViewController fromViewController:self animated:YES];
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
            if ( IS_IPHONE == NO ) //Fixes #1292. popToViewController:animated was called twice
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
		[defaults setBool:false forKey:@"refreshPostsRequired"];
		return YES;
	}
	
	return NO;
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.blog.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(blog == %@) && (original == nil)", self.blog]];
    NSSortDescriptor *sortDescriptorLocal = [[NSSortDescriptor alloc] initWithKey:@"remoteStatusNumber" ascending:YES];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorLocal, sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

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
    // To comply with apple ownership and naming conventions, returned cell should have a retain count > 0, so retain the dequeued cell.
    NSString *cellIdentifier = @"PostCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        [cell setBackgroundView:imageView];
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
