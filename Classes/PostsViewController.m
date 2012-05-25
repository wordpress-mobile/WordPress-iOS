#import "PostsViewController.h"
#import "EditPostViewController.h"
#import "PostViewController.h"
#import "PostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"

#define TAG_OFFSET 1010

@interface PostsViewController (Private)

- (void)refreshHandler;
- (void)syncPostsWithBlogInfo:(BOOL)blogInfo;
- (void)syncPosts;
//- (void) addSpinnerToCell:(NSIndexPath *)indexPath;
//- (void) removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (BOOL)handleAutoSavedContext:(NSInteger)tag;
- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath;
- (void)trySelectSomething;
- (void)editPost:(AbstractPost *)apost;
- (void)showSelectedPost;
- (BOOL)isSyncing;
- (void)checkLastSyncDate;
- (NSDate *)lastSyncDate;
- (BOOL) hasOlderItems;
- (void)loadMore;
- (void)loadMoreItemsWithBlock:(void (^)())block;
- (NSString *)entityName;
- (void)syncFinished;
- (void)configureCell:(PostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation PostsViewController

@synthesize composeButtonItem, postDetailViewController, postReaderViewController;
@synthesize anyMorePosts, selectedIndexPath, drafts;
@synthesize resultsController, blog = _blog;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;

	// ShouldRefreshPosts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableAfterDraftSaved:) name:@"DraftsUpdated" object:nil];

    composeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddPostView)];
    self.navigationItem.rightBarButtonItem = composeButtonItem;
    self.title = NSLocalizedString(@"Posts", @"");

    if (_refreshHeaderView == nil) {
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.tableView addSubview:_refreshHeaderView];
	}

	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];

    if (DeviceIsPad() && self.selectedIndexPath && self.postReaderViewController) {
        @try {
            self.postReaderViewController.post = [resultsController objectAtIndexPath:self.selectedIndexPath];
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
    self.tableView.tableFooterView = footerView;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Force a crash for CrashReporter
	//NSLog(@"crash time! %@", 1);
		
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.postID = nil;

	if ( appDelegate.connectionAvailable && ![self isSyncing] && ([self refreshRequired] || [self lastSyncDate] == nil)) {
		CGPoint offset = self.tableView.contentOffset;
		offset.y = - 65.0f;
		self.tableView.contentOffset = offset;
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
	}

	if (DeviceIsPad() == NO) {
		// iPhone table views should not appear selected
		if ([self.tableView indexPathForSelectedRow]) {
			[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
		}
	} else if (DeviceIsPad() == YES) {
        if (!self.selectedIndexPath && ([self.resultsController.fetchedObjects count] > 0)) {
            [self trySelectSomething];
        }
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
	}
}

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_refreshHeaderView release]; _refreshHeaderView = nil;
	[super viewDidUnload];
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

-(NSDate *) lastSyncDate {
	return self.blog.lastPostsSync;
}

- (BOOL) hasOlderItems {
	return [self.blog.hasOlderPosts boolValue];
}

- (void)loadMoreItemsWithBlock:(void (^)())block {
	[self.blog syncPostsWithSuccess:block failure:^(NSError *error) {
        if (block) block();
    } loadMore:YES];
}

#pragma mark -
#pragma mark TableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;

	if (DeviceIsPad() == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) && (indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) && [self tableView:tableView numberOfRowsInSection:indexPath.section] > 10) {
        // Only 3 rows till the end of table
        if (![self isSyncing] && [self hasOlderItems]) {
            [activityFooter startAnimating];
            WPLog(@"Approaching end of table, let's load more posts");
            [self loadMore];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSString *sectionName = [sectionInfo name];
    
    return [Post titleForRemoteStatus:[sectionName numericValue]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PostCell";
    PostTableViewCell *cell = (PostTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[PostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
	if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
		// Don't allow editing while pushing changes
		return;
	}
    if (DeviceIsPad()) {
        self.selectedIndexPath = indexPath;
    } else {
        [self editPost:post];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
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

- (void)syncFinished {
    [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

- (void)refreshHandler {
    if ([self isSyncing])
        return;
    [self syncPostsWithBlogInfo:YES];
}

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

- (void)loadMore {
    if ((![self isSyncing]) && [self hasOlderItems]) {
        WPLog(@"We have older posts to load");
        [self loadMoreItemsWithBlock:^{
            [activityFooter stopAnimating];
        }];
    }
}

- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath{
    Post *post = [resultsController objectAtIndexPath:indexPath];
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
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
		
    Post *post = [Post newDraftForBlog:self.blog];
	if (DeviceIsPad()) {
        self.postReaderViewController = [[[PostViewController alloc] initWithPost:post] autorelease];
		[delegate showContentDetailViewController:self.postReaderViewController];
		[self.postReaderViewController showModalEditor];
	} else {
        self.postDetailViewController = [[[EditPostViewController alloc] initWithNibName:@"EditPostViewController" bundle:nil] autorelease];
        self.postDetailViewController.apost = [post createRevision];
        self.postDetailViewController.editMode = kNewPost;
        [self.postDetailViewController refreshUIForCompose];
		[delegate showContentDetailViewController:self.postDetailViewController];
	}
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
#ifndef PANELS_EXPERIMENTAL
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
#endif
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
#ifdef PANELS_EXPERIMENTAL
    [self.panelNavigationController popToRootViewControllerAnimated:NO];
    [self.panelNavigationController pushViewController:self.postReaderViewController animated:YES];
#else
    [delegate showContentDetailViewController:self.postReaderViewController];
#endif
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

- (void)trySelectSomething {
    if (!DeviceIsPad())
        return;
	
    if (self.tabBarController.selectedViewController != self)
        return;
	
    if (!self.selectedIndexPath) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        @try {
            if ([resultsController fetchedObjects] &&
                ([[resultsController fetchedObjects] count] > 0) &&
                [resultsController objectAtIndexPath:indexPath]) {
                self.selectedIndexPath = indexPath;
            }
        }
        @catch (NSException * e) {
            NSLog(@"Caught exception when looking for a post to select. Maybe there are no posts yet?");
        }
    }
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Post";
}

- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
    }
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:appDelegate.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(blog == %@) && (original == nil)", self.blog]];
    NSSortDescriptor *sortDescriptorLocal = [[NSSortDescriptor alloc] initWithKey:@"remoteStatusNumber" ascending:YES];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorLocal, sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aResultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:appDelegate.managedObjectContext
                                                      sectionNameKeyPath:@"remoteStatusNumber"
                                                      cacheName:[NSString stringWithFormat:@"%@-%@", [self entityName], [self.blog objectID]]];
    self.resultsController = aResultsController;
    resultsController.delegate = self;
    
    [aResultsController release];
    [fetchRequest release];
    [sortDescriptorLocal release]; sortDescriptorLocal = nil;
    [sortDescriptorDate release]; sortDescriptorDate = nil;
    [sortDescriptors release]; sortDescriptors = nil;

    NSError *error = nil;
    if (![resultsController performFetch:&error]) {
        NSLog(@"Couldn't fetch posts");
        resultsController = nil;
    }
    NSLog(@"fetched posts: %@\ntotal: %i", [resultsController fetchedObjects], [[resultsController fetchedObjects] count]);
    
    return resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    if (NSFetchedResultsChangeUpdate == type && newIndexPath != nil) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            if (DeviceIsPad()) {
                self.selectedIndexPath = newIndexPath;
            }
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if(self.selectedIndexPath && (self.selectedIndexPath == indexPath)) {
                //push an the W logo on the right. 
                WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
                [delegate showContentDetailViewController:nil];
                if (DeviceIsPad()) {
                    self.selectedIndexPath = nil;
                }
            }
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:((PostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath]) atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (BOOL)refreshRequired {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"refreshPostsRequired"]) { 
		[defaults setBool:false forKey:@"refreshPostsRequired"];
		return YES;
	}
	
	return NO;
}

- (void)setBlog:(Blog *)blog {
    if (_blog == blog) 
        return;
    [_blog release];
    _blog = [blog retain];
    self.resultsController = nil;
    NSError *error = nil;
    [self.resultsController performFetch:&error];
    [self.tableView reloadData];
    if ([self.resultsController.fetchedObjects count] == 0) {
        if (![self isSyncing]) {
            CGPoint offset = self.tableView.contentOffset;
            offset.y = - 65.0f;
            self.tableView.contentOffset = offset;
            [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
        }
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[self refreshHandler];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return [self isSyncing]; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [self lastSyncDate]; // should return date data source was last changed
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.blog = nil;
    self.resultsController = nil;

    [_refreshHeaderView release]; _refreshHeaderView = nil;
    [activityFooter release];
    [postDetailViewController release];
    [composeButtonItem release];
	[selectedIndexPath release], selectedIndexPath = nil;
	[drafts release];
	
    [super dealloc];
}

@end
