
#import "WPTableViewControllerSubclass.h"
#import "PostsViewController.h"
#import "EditPostViewController.h"
#import "PostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"

#define TAG_OFFSET 1010

@interface PostsViewController (Private)

- (void)syncPostsWithBlogInfo:(BOOL)blogInfo;
- (void)syncPosts;
- (BOOL)handleAutoSavedContext:(NSInteger)tag;
- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath;
- (void)editPost:(AbstractPost *)apost;
- (void)showSelectedPost;
- (void)checkLastSyncDate;
- (void)syncFinished;

@end

@implementation PostsViewController

@synthesize composeButtonItem, postDetailViewController, postReaderViewController;
@synthesize anyMorePosts, selectedIndexPath, drafts;
//@synthesize resultsController;

#pragma mark -
#pragma mark View lifecycle

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    [activityFooter release];
    [postDetailViewController release];
	[selectedIndexPath release], selectedIndexPath = nil;
	[drafts release];
	
    [super dealloc];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

	// ShouldRefreshPosts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableAfterDraftSaved:) name:@"DraftsUpdated" object:nil];

    self.title = NSLocalizedString(@"Posts", @"");
    composeButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddPostView)] autorelease];
    if (IS_IPAD) {
        CGFloat toolbarHeight = 44.0f;
        CGRect frame = CGRectMake(0.0f, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width, toolbarHeight);
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:frame];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:toolbar];
        [toolbar setItems:[NSArray arrayWithObject:composeButtonItem]];
        
    } else {
        self.navigationItem.rightBarButtonItem = composeButtonItem;
    }

    if (DeviceIsPad() && self.selectedIndexPath && self.postReaderViewController) {
        @try {
            self.postReaderViewController.post = [self.resultsController objectAtIndexPath:self.selectedIndexPath];
            [self.postReaderViewController refreshUI];
        }
        @catch (NSException * e) {
            // In some cases, selectedIndexPath could be pointint to a missing row
            // This is the case after a failed core data upgrade
            self.selectedIndexPath = nil;
        }
    }
    
    if (activityFooter == nil) {
        CGRect rect = CGRectMake(145.0, 10.0, 30.0, 30.0);
        activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
        activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        activityFooter.hidesWhenStopped = YES;
        activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [activityFooter stopAnimating];
    }
    UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)] autorelease];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:activityFooter];
    tableView.tableFooterView = footerView;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Force a crash for CrashReporter
	//NSLog(@"crash time! %@", 1);
		
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.postID = nil;

	if (DeviceIsPad() == NO) {
		// iPhone table views should not appear selected
		if ([tableView indexPathForSelectedRow]) {
			[tableView scrollToRowAtIndexPath:[tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:animated];
		}
	} else if (DeviceIsPad() == YES) {
		// sometimes, iPad table views should
		if (self.selectedIndexPath) {
            [self showSelectedPost];
			[tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			[tableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
		} else {
			//There are no content yet, push an the WP logo on the right.  
			WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate]; 
			[delegate showContentDetailViewController:nil];
		}
	}
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
    return YES;
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

- (void)loadMoreItemsWithBlock:(void (^)())block {
	[self.blog syncPostsWithSuccess:block failure:^(NSError *error) {
        if (block) block();
    } loadMore:YES];
}

#pragma mark -
#pragma mark TableView delegate

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;

	if (DeviceIsPad() == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) && (indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) && [self tableView:tableView numberOfRowsInSection:indexPath.section] > 10) {
        // Only 3 rows till the end of table
        if (![self isSyncing] && [self hasMoreContent]) {
            [activityFooter startAnimating];
            WPLog(@"Approaching end of table, let's load more posts");
            [self loadMoreContent];
        }
    }
}

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

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
	if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
		// Don't allow editing while pushing changes
		return;
	}
    if (DeviceIsPad()) {
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
    return YES;
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

- (void)syncPostsWithBlogInfo:(BOOL)blogInfo {
    void (^success)() = ^{
        [self syncFinished];
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        [WPError showAlertWithError:error title:NSLocalizedString(@"Couldn't sync posts", @"")];
        [self syncFinished];
    };

    if (blogInfo) {
        [self.blog syncBlogPostsWithSuccess:success failure:failure];
    } else {
        [self.blog syncPostsWithSuccess:success failure:failure loadMore:NO];
    }
}

- (void)syncPosts {
    [self syncPostsWithBlogInfo:NO];
}

- (void)loadMoreContent {
    if ((![self isSyncing]) && [self hasMoreContent]) {
        WPLog(@"We have older posts to load");
        [self loadMoreItemsWithBlock:^{
            [activityFooter stopAnimating];
        }];
    }
}

- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath{
    Post *post = [self.resultsController objectAtIndexPath:indexPath];
    [post deletePostWithSuccess:nil failure:^(NSError *error) {
        NSDictionary *errInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.blog, @"currentBlog", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kXML_RPC_ERROR_OCCURS object:error userInfo:errInfo];
        [self syncPosts];
        if(DeviceIsPad() && self.postReaderViewController) {
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
		
    Post *post = [Post newDraftForBlog:self.blog];
    EditPostViewController *editPostViewController = [[[EditPostViewController alloc] initWithPost:[post createRevision]] autorelease];
    editPostViewController.editMode = kNewPost;
    [editPostViewController refreshUIForCompose];
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:editPostViewController] autorelease];
    navController.modalTransitionStyle = UIModalPresentationFormSheet;
    [self.panelNavigationController presentModalViewController:navController animated:YES];
    [post release];
}

// For iPhone
- (void)editPost:(AbstractPost *)apost {
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

    self.postDetailViewController = [[[EditPostViewController alloc] initWithNibName:@"EditPostViewController" bundle:nil] autorelease];
    self.postDetailViewController.apost = [apost createRevision];
    self.postDetailViewController.editMode = kEditPost;
    [self.postDetailViewController refreshUIForCurrentPost];
    [appDelegate showContentDetailViewController:self.postDetailViewController];
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
    [self.panelNavigationController popToRootViewControllerAnimated:NO];
    [self.panelNavigationController pushViewController:self.postReaderViewController animated:YES];
}

- (void)setSelectedIndexPath:(NSIndexPath *)indexPath {
    if (selectedIndexPath != indexPath) {
        WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        [selectedIndexPath release];

        if (indexPath != nil) {
            @try {
                [self.resultsController objectAtIndexPath:indexPath];
                selectedIndexPath = [indexPath retain];
                [self showSelectedPost];
            }
            @catch (NSException *exception) {
                selectedIndexPath = nil;
                [delegate showContentDetailViewController:nil];
            }
        } else {
            selectedIndexPath = nil;
            [delegate showContentDetailViewController:nil];
        }

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
		[defaults setBool:false forKey:@"refreshPostsRequired"];
		return YES;
	}
	
	return NO;
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.blog.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(blog == %@) && (original == nil)", self.blog]];
    NSSortDescriptor *sortDescriptorLocal = [[[NSSortDescriptor alloc] initWithKey:@"remoteStatusNumber" ascending:YES] autorelease];
    NSSortDescriptor *sortDescriptorDate = [[[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptorLocal, sortDescriptorDate, nil] autorelease];
    [fetchRequest setSortDescriptors:sortDescriptors];

    return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
    return @"remoteStatusNumber";
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    [self.blog syncPostsWithSuccess:success failure:failure loadMore:NO];
}

- (UITableViewCell *)newCell {
    NSString *cellIdentifier = @"PostCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    return cell;
}

@end
