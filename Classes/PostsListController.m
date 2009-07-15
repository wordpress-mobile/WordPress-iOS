#import "PostsListController.h"

#import "BlogDataManager.h"
#import "PostViewController.h"
#import "PostDetailEditController.h"
#import "PostTableViewCell.h"
#import "Reachability.h"
#import "UIViewController+WPAnimation.h"
#import "WordPressAppDelegate.h"
#import "WPNavigationLeftButtonView.h"

#define LOCAL_DRAFTS_SECTION    0
#define POSTS_SECTION           1
#define NUM_SECTIONS            2

#define NEW_VERSION_ALERT_TAG   5111

@interface PostsListController (Private)
- (void)loadPosts;
- (void)showAddPostView;
- (void)refreshHandler;
- (void)downloadRecentPosts;
- (BOOL)handleAutoSavedContext:(NSInteger)tag;
- (void)addRefreshButton;
@end

@implementation PostsListController

@synthesize newButtonItem, postDetailViewController, postDetailEditController;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;

    [self addRefreshButton];

    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];

    newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddPostView)];
}

- (void)viewWillAppear:(BOOL)animated {
    connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);

    [self loadPosts];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
#pragma mark Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kNetworkReachabilityChangedNotification" object:nil];
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

- (void)showAddPostView {
    // Set current post to a new post
    // Detail view will bind data into this instance and call save

    [[BlogDataManager sharedDataManager] makeNewPostCurrent];

    self.postDetailViewController.mode = 0;

    // Create a new nav controller to provide navigation bar with Cancel and Done buttons.
    // Ask for modal presentation
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
#pragma mark UITableViewDataSource methods

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
        return [[BlogDataManager sharedDataManager] countOfPostTitles];
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
        post = [dm postTitleAtIndex:indexPath.row];
    }

    cell.post = post;

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
        if (!connectionStatus) {
            UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
                                   message:@"Editing is not supported now."
                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];

            alert1.tag = NEW_VERSION_ALERT_TAG;
            [alert1 show];
            [delegate setAlertRunning:YES];

            [alert1 release];

            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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

    self.postDetailViewController.mode = 1;
    [delegate.navigationController pushViewController:self.postDetailViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return POST_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == LOCAL_DRAFTS_SECTION;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];

    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        [dataManager deleteDraftAtIndex:indexPath.row forBlog:[dataManager currentBlog]];
    } else {
        // TODO: delete the post.
    }

    [self loadPosts];
}

#pragma mark -
#pragma mark Private methods

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

- (void)reachabilityChanged {
    connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
    [self.tableView reloadData];
}

- (BOOL)handleAutoSavedContext:(NSInteger)tag {
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
    [self performSelectorInBackground:@selector(downloadRecentPosts) withObject:nil];
}

- (void)downloadRecentPosts {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    [dm syncPostsForCurrentBlog];
    [self loadPosts];

    [refreshButton stopAnimating];
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
    if (alertView.tag != NEW_VERSION_ALERT_TAG) { // When Connection Available.
        [[BlogDataManager sharedDataManager] removeAutoSavedCurrentPostFile];
        self.navigationItem.rightBarButtonItem = nil;
        self.postDetailViewController.mode = 2;
        [[self navigationController] pushViewController:self.postDetailViewController animated:YES];
    }

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

@end
