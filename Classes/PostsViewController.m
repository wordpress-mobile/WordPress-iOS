#import "PostsViewController.h"

#import "BlogDataManager.h"
#import "PostViewController.h"
#import "EditPostViewController.h"
#import "PostTableViewCell.h"
#import "UIViewController+WPAnimation.h"
#import "WordPressAppDelegate.h"
#import "WPNavigationLeftButtonView.h"
#import "Reachability.h"
#import "WPProgressHUD.h"

#define LOCAL_DRAFTS_SECTION    0
#define POSTS_SECTION           1
#define NUM_SECTIONS            2

#define TAG_OFFSET 1010

@interface PostsViewController (Private)

- (void)scrollToFirstCell;
- (void)loadPosts;
- (void)showAddPostView;
- (void)refreshHandler;
- (void)syncPosts;
- (BOOL)handleAutoSavedContext:(NSInteger)tag;
- (void)addRefreshButton;
- (void)deletePostAtIndexPath;

@end

@implementation PostsViewController

@synthesize newButtonItem, postDetailViewController, postDetailEditController;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AsynchronousPostIsPosted" object:nil];
    
    [postDetailEditController release];
    [PostViewController release];
    
    [newButtonItem release];
    [refreshButton release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;

    [self addRefreshButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];

    newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddPostView)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self loadPosts];
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([[Reachability sharedReachability] internetConnectionStatus])
	{
		if ([defaults boolForKey:@"refreshPostsRequired"]) {
			[self refreshHandler];
			[defaults setBool:false forKey:@"refreshPostsRequired"];
		}
	}
	
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    }
	
	NSLog(@"inside PostsViewController.m viewWillAppear");
	[self handleAutoSavedContext:0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

    // Return YES for supported orientations
    return YES;
}

#pragma mark -

- (void)showAddPostView {
    [[BlogDataManager sharedDataManager] makeNewPostCurrent];

    self.postDetailViewController.mode = newPost;

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.navigationController pushViewController:self.postDetailViewController animated:YES];
}

- (PostViewController *)postDetailViewController {
    if (postDetailViewController == nil) {
        postDetailViewController = [[PostViewController alloc] initWithNibName:@"PostViewController" bundle:nil];
        postDetailViewController.postsListController = self;
    }

    return postDetailViewController;
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == LOCAL_DRAFTS_SECTION) {
        if ([[BlogDataManager sharedDataManager] numberOfDrafts] > 0) {
            return @"Local Drafts";
        } else {
            return NULL;
        }
    } else {
        return @"Posts";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == LOCAL_DRAFTS_SECTION) {
        return [[BlogDataManager sharedDataManager] numberOfDrafts];
    } else {
        return [[BlogDataManager sharedDataManager] countOfPostTitles] + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PostCell";
    PostTableViewCell *cell = (PostTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    id post = nil;
	
    if (cell == nil) {
        cell = [[[PostTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	

    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        post = [dm draftTitleAtIndex:indexPath.row];
    } else { 
		int count = [[BlogDataManager sharedDataManager] countOfPostTitles];
		//handle the case when it's the last row and we need to return the modified "get more posts" cell
		//note that it's not [[BlogDataManager sharedDataManager] countOfPostTitles] +1 because of the difference in the counting of the datasets
		if (indexPath.row == count) {
			
			NSLog(@"inside the else");
			NSLog(@"index path: %d", indexPath.row);
		//set the labels.  The spinner will be activiated if the row is selected in didSelectRow...
		//get the total number of posts on the blog, make a string and pump it into the cell
		int totalPosts = [[BlogDataManager sharedDataManager] countOfPostTitles];
			NSLog(@"totalPosts %d", totalPosts);
		NSString * totalString = [NSString stringWithFormat:@"%d posts total", totalPosts];
			[cell changeCellLabelsForUpdate:totalString:@"Load more posts":NO];
		return cell;
	}
		//if it wasn't the last cell, proceed as normal.
        post = [dm postTitleAtIndex:indexPath.row];
    }

    cell.post = post;
	//[cell setSaving:YES];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    dataManager.isLocaDraftsCurrent = (indexPath.section == LOCAL_DRAFTS_SECTION);

    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        id currentDraft = [dataManager draftTitleAtIndex:indexPath.row];

        // Bail out if we're in the middle of saving the draft.
        if ([[currentDraft valueForKey:kAsyncPostFlag] intValue] == 1) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }

        [dataManager makeDraftAtIndexCurrent:indexPath.row];
		
    } else {
		//handle the case when it's the last row and is the "get more posts" cell
		if (indexPath.row == [[BlogDataManager sharedDataManager] countOfPostTitles]) {
			//get the cell
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			
			//do "nothing"
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			
			//change the text in the cell to say "Loading" and change it's color
			int totalPosts = [[BlogDataManager sharedDataManager] countOfPostTitles];
			NSString * totalString = [NSString stringWithFormat:@"%d posts total", totalPosts];
			[((PostTableViewCell *)cell) changeCellLabelsForUpdate:totalString:@"Loading more posts...":YES];
			
			//set the spinner (cast to PostTableView "type" in order to avoid warnings)
			[((PostTableViewCell *)cell) runSpinner:YES];
			
			//run the "get more" function and get 10 more
			
			//turn off the spinner
			
			//update the tableview
			return;
		}
		
        id currentPost = [dataManager postTitleAtIndex:indexPath.row];

        // Bail out if we're in the middle of saving the post.
        if ([[currentPost valueForKey:kAsyncPostFlag] intValue] == 1) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }

        [dataManager makePostAtIndexCurrent:indexPath.row];

        self.postDetailViewController.hasChanges = NO;
    }

    self.postDetailViewController.mode = editPost;
    [delegate.navigationController pushViewController:self.postDetailViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return POST_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //return indexPath.section == LOCAL_DRAFTS_SECTION;
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

	progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting Post..."];
	[progressAlert show];
	
	[self performSelectorInBackground:@selector(deletePostAtIndexPath:) withObject:indexPath];
	
}

#pragma mark -
#pragma mark Private Methods

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;

    if ([self tableView:self.tableView numberOfRowsInSection:LOCAL_DRAFTS_SECTION] > 0) {
        NSUInteger indexes[] = {LOCAL_DRAFTS_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    } else if ([self tableView:self.tableView numberOfRowsInSection:POSTS_SECTION] > 0) {
        NSUInteger indexes[] = {POSTS_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }

    if (indexPath) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)loadPosts {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    dm.isLocaDraftsCurrent = NO;

    [dm loadPostTitlesForCurrentBlog];
    [dm loadDraftTitlesForCurrentBlog];

    [self.tableView reloadData];
}

- (void)goToHome:(id)sender {
    [[BlogDataManager sharedDataManager] resetCurrentBlog];
    [self popTransition:self.navigationController.view];
}

- (BOOL)handleAutoSavedContext:(NSInteger)tag {
	NSLog(@"inside handleAutoSavedContext");
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
    [self performSelectorInBackground:@selector(syncPosts) withObject:nil];
}

- (void)syncPosts {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    [dm syncPostsForCurrentBlog];
    [self loadPosts];
	[dm downloadAllCategoriesForBlog:[dm currentBlog]];

    [refreshButton stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [pool release];
}

- (void)updatePostsTableViewAfterPostSaved:(NSNotification *)notification {
    NSDictionary *postIdsDict = [notification userInfo];
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    [dm updatePostsTitlesFileAfterPostSaved:(NSMutableDictionary *)postIdsDict];
    [dm loadPostTitlesForCurrentBlog];

    [self.tableView reloadData];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[BlogDataManager sharedDataManager] removeAutoSavedCurrentPostFile];
    self.navigationItem.rightBarButtonItem = nil;
    self.postDetailViewController.mode = autorecoverPost;
	
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
	[delegate.navigationController pushViewController:self.postDetailViewController animated:YES];
}

- (void) deletePostAtIndexPath:(id)object{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	//NewObj* pNew = (NewObj*)oldObj;
	NSIndexPath *indexPath = (NSIndexPath*)object;
	
    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        [dataManager deleteDraftAtIndex:indexPath.row forBlog:[dataManager currentBlog]];
		[self syncPosts];
    } else {
		if (indexPath.section == POSTS_SECTION){
			//check for reachability
			if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Error."
																message:@"no internet connection."
															   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				alert.tag = TAG_OFFSET;
				[alert show];
				
				WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
				[delegate setAlertRunning:YES];
				[alert release];
				return;
			}else{				
				//if reachability is good, make post at index current, delete post, and refresh view (sync posts)
				[dataManager makePostAtIndexCurrent:indexPath.row];
				//delete post
				//if ([dataManager deletePage]){
				[dataManager deletePost];
				//resync posts
				[self syncPosts];
				
			}
		}
	}
	
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
	
}

@end
