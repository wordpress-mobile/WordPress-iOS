#import "PostsViewController.h"
#import "BlogDataManager.h"
#import "PostViewController.h"
#import "EditPostViewController.h"
#import "PostTableViewCell.h"
#import "UIViewController+WPAnimation.h"
#import "WordPressAppDelegate.h"
#import "WPNavigationLeftButtonView.h"
#import "WPReachability.h"
#import "WPProgressHUD.h"
#import "IncrementPost.h"

#define LOCAL_DRAFTS_SECTION    0
#define POSTS_SECTION           1
#define NUM_SECTIONS            2
#define TAG_OFFSET 1010

@interface PostsViewController (Private)

- (void)scrollToFirstCell;
- (void)refreshHandler;
- (void)syncPosts;
//- (void) addSpinnerToCell:(NSIndexPath *)indexPath;
//- (void) removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (BOOL)handleAutoSavedContext:(NSInteger)tag;
- (void)addRefreshButton;
- (void)deletePostAtIndexPath;

@end

@implementation PostsViewController

@synthesize newButtonItem, postDetailViewController, postDetailEditController;
@synthesize anyMorePosts, selectedIndexPath, drafts, draftManager, mediaManager;
@synthesize resultsController;
@synthesize blog;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"Posts"];

	draftManager = [[DraftManager alloc] init];
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    [self addRefreshButton];

	// ShouldRefreshPosts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableAfterDraftSaved:) name:@"DraftsUpdated" object:nil];

    newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddPostView)];

    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        NSLog(@"Error fetching request (Posts) %@", [error localizedDescription]);
    } else {
        NSLog(@"fetched posts: %@", [resultsController fetchedObjects]);
        NSLog(@"sections: %@", [resultsController sections]);
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Force a crash for CrashReporter
	//NSLog(@"crash time! %@", 1);
		
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.postID = nil;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([[WPReachability sharedReachability] internetConnectionStatus])
	{
		if ([defaults boolForKey:@"refreshPostsRequired"]) {
			[self refreshHandler];
			[defaults setBool:false forKey:@"refreshPostsRequired"];
		}
	}

	if (DeviceIsPad() == NO) {
		// iPhone table views should not appear selected
		if ([self.tableView indexPathForSelectedRow]) {
			[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
		}
	} else if (DeviceIsPad() == YES) {
		// sometimes, iPad table views should
		if (self.selectedIndexPath) {
			[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}

	[self handleAutoSavedContext:0];	
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;
    return YES;
}

#pragma mark -
#pragma mark TableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;

	if (DeviceIsPad() == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[resultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[resultsController sections] objectAtIndex:section];
    NSString *sectionName = [sectionInfo name];
    
    // Ugly, but it works. We'll need something better when going for i18n
    return [sectionName stringByAppendingString:@"s"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PostCell";
    PostTableViewCell *cell = (PostTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Post *post = [resultsController objectAtIndexPath:indexPath];

    if (cell == nil) {
        cell = [[[PostTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.post = post;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WordPressAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	self.postDetailViewController = nil;
	if (DeviceIsPad() == YES) {
		self.postDetailViewController = [[PostViewController alloc] initWithNibName:@"PostViewController-iPad" bundle:nil];
	} else {
		self.postDetailViewController = [[PostViewController alloc] initWithNibName:@"PostViewController" bundle:nil];
	}

    if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        //run the spinner in the background and change the text
        [self performSelectorInBackground:@selector(addSpinnerToCell:) withObject:indexPath];

        //init the Increment Post helper class class
        IncrementPost *incrementPost = [[IncrementPost alloc] init];

        //run the "get more" function in the IncrementPost class and get metadata, then parse metadata for next 10 and get 10 more
        anyMorePosts = [incrementPost loadOlderPosts];
        [defaults setBool:anyMorePosts forKey:@"anyMorePosts"];

        //release the helper class
        [incrementPost release];

        //turn of spinner and change text
        [self performSelectorInBackground:@selector(removeSpinnerFromCell:) withObject:indexPath];

        //get a reference to the cell
        UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];

        // solve the problem where the "load more" cell is reused and retains it's old formatting by forcing a redraw
        [cell setNeedsDisplay];

        //return
        return;

    }

    postDetailViewController.post = [resultsController objectAtIndexPath:indexPath];
    [postDetailViewController refreshUIForCurrentPost];
    postDetailViewController.postsListController = self;
    self.selectedIndexPath = indexPath;
    self.postDetailViewController.hasChanges = NO;

    self.postDetailViewController.editMode = kEditPost;
	[self.postDetailViewController refreshUIForCurrentPost];
	[appDelegate showContentDetailViewController:self.postDetailViewController];
	
	if (!DeviceIsPad())
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return POST_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting Post..."];
	[progressAlert show];
	[self performSelectorInBackground:@selector(deletePostAtIndexPath:) withObject:indexPath];
	
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Custom methods

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;
	
    if ([self tableView:self.tableView numberOfRowsInSection:LOCAL_DRAFTS_SECTION] > 0) {
        NSUInteger indexes[] = {LOCAL_DRAFTS_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
	else if ([self tableView:self.tableView numberOfRowsInSection:POSTS_SECTION] > 0) {
        NSUInteger indexes[] = {POSTS_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
	
    if (indexPath) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}


- (void)refreshPostList {
//    [self.tableView reloadData];
    [refreshButton stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)goToHome:(id)sender {
    [[BlogDataManager sharedDataManager] resetCurrentBlog];
    [self popTransition:self.navigationController.view];
}

- (BOOL)handleAutoSavedContext:(NSInteger)tag {
	//NSLog(@"Autosaving...");
    if ([[BlogDataManager sharedDataManager] makeAutoSavedPostCurrentForCurrentBlog]) {
        NSString *title = [[BlogDataManager sharedDataManager].currentPost valueForKey:@"title"];
        title = (title == nil ? @"" : title);
        NSString *titleStr = [NSString stringWithFormat:@"Your last session was interrupted. Unsaved edits to the post \"%@\" were recovered.", title];
        UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Recovered Post"
														 message:titleStr
														delegate:self
											   cancelButtonTitle:nil
											   otherButtonTitles:@"Review Post", nil];
		
        alert1.tag = tag;
		
        [alert1 show];
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];
		
        [alert1 release];
        return YES;
    }
	
    return NO;
}

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, self.tableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);
	
    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];
	
    self.tableView.tableHeaderView = refreshButton;
}

- (void)refreshHandler {
    [refreshButton startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelectorInBackground:@selector(syncPosts) withObject:nil];
}

- (void)syncPosts {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;
    // TODO: handle errors
    [self.blog syncCategoriesWithError:&error];
    // TODO: handle errors
    [self.blog syncPostsWithError:&error];
    [self performSelectorOnMainThread:@selector(refreshPostList) withObject:nil waitUntilDone:NO];
    [pool release];
}

- (void)updatePostsTableViewAfterPostSaved:(NSNotification *)notification {
    NSDictionary *postIdsDict = [notification userInfo];
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
    [dm updatePostsTitlesFileAfterPostSaved:(NSMutableDictionary *)postIdsDict];
    [dm loadPostTitlesForCurrentBlog];
	[self refreshHandler];
	[self.tableView reloadData];
}

- (void)updatePostsTableAfterDraftSaved:(NSNotification *)notification {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    [dm loadPostTitlesForCurrentBlog];
	[self refreshHandler];
	[self.tableView reloadData];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[BlogDataManager sharedDataManager] removeAutoSavedCurrentPostFile];
    self.navigationItem.rightBarButtonItem = nil;
    self.postDetailViewController.editMode = kAutorecoverPost;
	
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
	if (DeviceIsPad() == YES) {
		[delegate showContentDetailViewController:self.postDetailViewController];
	}
	else {
		[delegate showContentDetailViewController:self.postDetailViewController];
	}
}

- (void)deletePostAtIndexPath:(id)object{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	//NewObj* pNew = (NewObj*)oldObj;
	NSIndexPath *indexPath = (NSIndexPath*)object;
    Post *post = [resultsController objectAtIndexPath:indexPath];
	
    if (post.local) {
		[mediaManager removeForPostID:post.postID andBlogURL:[[[BlogDataManager sharedDataManager] currentBlog] objectForKey:@"url"]];
		
        // FIXME: use custom post method
		[appDelegate.managedObjectContext deleteObject:post];
		
        // Commit the change.
        NSError *error;
        if (![appDelegate.managedObjectContext save:&error]) {
			NSLog(@"Severe error when trying to delete local draft. Error: %@", error);
        }		
    } 
	else {
		if (indexPath.section == POSTS_SECTION) {
			//check for reachability
			if ([[WPReachability sharedReachability] internetConnectionStatus] == NotReachable) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Error."
																message:@"no internet connection."
															   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				alert.tag = TAG_OFFSET;
				[alert show];
				
				WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
				[delegate setAlertRunning:YES];
				[alert release];
				return;
			}
			else{
				//if reachability is good, make post at index current, delete post, and refresh view (sync posts)
				[dataManager makePostAtIndexCurrent:indexPath.row];
				[mediaManager removeForPostID:[[[BlogDataManager sharedDataManager] currentPost] objectForKey:@"postid"] 
								   andBlogURL:[[[BlogDataManager sharedDataManager] currentBlog] objectForKey:@"url"]];
				//delete post
				[dataManager deletePost];
				
				//resync posts
				[dataManager loadPostTitlesForCurrentBlog];
				[self syncPosts];
			}
		}
	}
	
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
}

- (void)addSpinnerToCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	[((PostTableViewCell *)cell) runSpinner:YES];
	int totalPosts = [[BlogDataManager sharedDataManager] countOfPostTitles];
	NSString * totalString = [NSString stringWithFormat:@"%d posts loaded", totalPosts];
	[((PostTableViewCell *)cell) changeCellLabelsForUpdate:totalString:@"Loading more posts...":YES];
	[apool release];
}

- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	[((PostTableViewCell *)cell) runSpinner:NO];
	[apool release];
}

- (void)reselect {
	if ([[BlogDataManager sharedDataManager] hasAutosavedPost])
		return;
	
	if (self.selectedIndexPath != NULL) {
		[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self tableView:self.tableView didSelectRowAtIndexPath:self.selectedIndexPath];
	}
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"Shake detected. Refreshing...");
	if(event.subtype == UIEventSubtypeMotionShake)
		[self refreshPostList];
}

- (void)showAddPostView {
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	
	if(postDetailViewController == nil) {
		if(DeviceIsPad() == YES)
			self.postDetailViewController = [[PostViewController alloc] initWithNibName:@"PostViewController-iPad" bundle:nil];
		else
			self.postDetailViewController = [[PostViewController alloc] initWithNibName:@"PostViewController" bundle:nil];
	}
	self.postDetailViewController.editMode = kNewPost;
	self.postDetailViewController.title = @"Write";
    self.postDetailViewController.post = [Post newDraftForBlog:self.blog];
	[self.postDetailViewController refreshUIForCompose];
	
	if (DeviceIsPad() == NO) {
		[delegate.navigationController pushViewController:self.postDetailViewController animated:YES];
	}
	else if (DeviceIsPad() == YES) {
		[delegate showContentDetailViewController:self.postDetailViewController];
	}
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
    }
    
    WordPressAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext]];
    NSSortDescriptor *sortDescriptorLocal = [[NSSortDescriptor alloc] initWithKey:@"localType" ascending:YES];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorLocal, sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aResultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:appDelegate.managedObjectContext
                                                      sectionNameKeyPath:@"localType"
                                                      cacheName:@"Post"];
    self.resultsController = aResultsController;
    resultsController.delegate = self;
    
    [aResultsController release];
    [fetchRequest release];
    [sortDescriptorLocal release]; sortDescriptorLocal = nil;
    [sortDescriptorDate release]; sortDescriptorDate = nil;
    [sortDescriptors release]; sortDescriptors = nil;
    
    return resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    //    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    //    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    self.blog = nil;
    self.resultsController = nil;

	[mediaManager release];
	[draftManager release];
    [postDetailEditController release];
    [postDetailViewController release];
    [newButtonItem release];
    [refreshButton release];
	[selectedIndexPath release], selectedIndexPath = nil;
	[drafts release];
	
    [super dealloc];
}

@end
