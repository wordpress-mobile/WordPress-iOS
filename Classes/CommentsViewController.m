//
//  CommentsViewController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import "CommentsViewController.h"

#import "BlogDataManager.h"
#import "CommentTableViewCell.h"
#import "NSString+XMLExtensions.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "CommentViewController.h"
#import "WPProgressHUD.h"

@interface CommentsViewController (Private)
- (void)setEditing:(BOOL)value;
- (void)updateSelectedComments;
- (void)refreshHandler;
- (void)downloadRecentComments;
- (BOOL)isConnectedToHost;
- (void)moderateCommentsWithSelector:(SEL)selector;
- (void)deleteComments;
- (void)approveComments;
- (void)markCommentsAsSpam;
- (void)unapproveComments;
- (void)refreshCommentsList;
@end

@implementation CommentsViewController

@synthesize editButtonItem, selectedComments, commentsArray;

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, commentsTableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);

    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];

    commentsTableView.tableHeaderView = refreshButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    commentsDict = [[NSMutableDictionary alloc] init];
    selectedComments = [[NSMutableArray alloc] init];

    [commentsTableView setDataSource:self];
    commentsTableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;

    [self addRefreshButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];

    editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered
                      target:self action:@selector(editComments)];

    self.navigationItem.rightBarButtonItem = editButtonItem;

    [editButtonItem setEnabled:([commentsArray count] > 0)];
}

- (void)dealloc {
    [commentsArray release];
    [commentsDict release];
    [selectedComments release];
    [editButtonItem release];
    [commentsTableView release];
    [refreshButton release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [self setEditing:NO];

    BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
    [sharedDataManager loadCommentTitlesForCurrentBlog];

    [self refreshCommentsList];

    connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);

    [editToolbar setHidden:YES];

    [editButtonItem setEnabled:([commentsArray count] > 0)];

    [commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:animated];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    editButtonItem.title = @"Edit";
    [super viewWillDisappear:animated];
}

- (void)reachabilityChanged {
    connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
    [commentsTableView reloadData];
}

- (void)setEditing:(BOOL)value {
    editing = value;

    // Adjust comments table view height to fit toolbar (if it's visible).
    CGFloat toolbarHeight = editing ? editToolbar.bounds.size.height : 0;
    CGRect mainViewBounds = self.view.bounds;
    CGRect rect = CGRectMake(mainViewBounds.origin.x,
                             mainViewBounds.origin.y,
                             mainViewBounds.size.width,
                             mainViewBounds.size.height - toolbarHeight);

    commentsTableView.frame = rect;

    [editToolbar setHidden:!editing];
    [deleteButton setEnabled:!editing];
    [approveButton setEnabled:!editing];
    [unapproveButton setEnabled:!editing];
    [spamButton setEnabled:!editing];

    editButtonItem.title = editing ? @"Cancel" : @"Edit";
    [commentsTableView reloadData];
}

- (void)editComments {
    [self setEditing:!editing];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [commentsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES) {
        return NO;
    } else {
        return YES;
    }
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Action methods

- (void)refreshHandler {
    [refreshButton startAnimating];
    [self performSelectorInBackground:@selector(downloadRecentComments) withObject:nil];
}

- (void)downloadRecentComments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (!connectionStatus) {
        UIAlertView *alertt1 = [[[UIAlertView alloc] initWithTitle:@"No connection to host."
                                 message:@"Sync operation is not supported now."
                                 delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];

        [alertt1 show];
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];
        return;
    }

    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
    [sharedBlogDataManager syncCommentsForCurrentBlog];
    [sharedBlogDataManager loadCommentTitlesForCurrentBlog];

    [self refreshCommentsList];

    [editButtonItem setEnabled:([commentsArray count] > 0)];

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning]) {
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        [progressAlert release];
    } else {
        [refreshButton stopAnimating];
    }

    [pool release];
}

- (void)refreshCommentsList {
    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];

    if (!selectedComments) {
        selectedComments = [[NSMutableArray alloc] init];
    } else {
        [selectedComments removeAllObjects];
    }

    NSMutableArray *commentsList = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];

    [self setCommentsArray:commentsList];

    for (NSDictionary *dict in commentsArray) {
        NSString *str = [dict valueForKey:@"comment_id"];
        [commentsDict setValue:dict forKey:str];
    }

    if (([commentsArray count] > 0) && (![(NSDictionary *)[commentsArray objectAtIndex:0] objectForKey:@"author_url"])) {
        progressAlert = [[WPProgressHUD alloc] initWithLabel:@"updating"];
        [progressAlert show];

        [self performSelectorInBackground:@selector(downloadRecentComments) withObject:nil];
    }

    [commentsTableView reloadData];
}

- (IBAction)deleteSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"deleting"];
    [progressAlert show];

    [self performSelectorInBackground:@selector(deleteComments) withObject:nil];
}

- (IBAction)approveSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];

    [self performSelectorInBackground:@selector(approveComments) withObject:nil];
}

- (IBAction)unapproveSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];

    [self performSelectorInBackground:@selector(unapproveComments) withObject:nil];
}

- (IBAction)spamSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];

    [self performSelectorInBackground:@selector(markCommentsAsSpam) withObject:nil];
}

- (BOOL)isConnectedToHost {
    if (![[Reachability sharedReachability] remoteHostStatus] != NotReachable) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
                                            message:@"Operation is not supported now."
                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectionFailAlert show];
        [connectionFailAlert release];
        return NO;
    }

    return YES;
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self isConnectedToHost]) {
        BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];

        NSArray *selectedItems = [self selectedComments];

        [sharedDataManager performSelector:selector withObject:selectedItems withObject:[sharedDataManager currentBlog]];

        [editButtonItem setEnabled:([commentsArray count] > 0)];
        [self setEditing:FALSE];
    }

    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
}

- (void)deleteComments {
    [self moderateCommentsWithSelector:@selector(deleteComment:forBlog:)];
}

- (void)approveComments {
    [self moderateCommentsWithSelector:@selector(approveComment:forBlog:)];
}

- (void)markCommentsAsSpam {
    [self moderateCommentsWithSelector:@selector(spamComment:forBlog:)];
}

- (void)unapproveComments {
    [self moderateCommentsWithSelector:@selector(unApproveComment:forBlog:)];
}

- (void)updateSelectedComments {
    int i, approvedCount, unapprovedCount, spamCount, count = [selectedComments count];

    approvedCount = unapprovedCount = spamCount = 0;

    for (i = 0; i < count; i++) {
        NSDictionary *dict = [selectedComments objectAtIndex:i];

        if ([[dict valueForKey:@"status"] isEqualToString:@"hold"]) {
            unapprovedCount++;
        } else if ([[dict valueForKey:@"status"] isEqualToString:@"approve"]) {
            approvedCount++;
        } else if ([[dict valueForKey:@"status"] isEqualToString:@"spam"]) {
            spamCount++;
        }
    }

    [deleteButton setEnabled:(count > 0)];
    [approveButton setEnabled:((count - approvedCount) > 0)];
    [unapproveButton setEnabled:((count - unapprovedCount) > 0)];
    [spamButton setEnabled:((count - spamCount) > 0)];

    [approveButton setTitle:(((count - approvedCount) > 0) ? [NSString stringWithFormat:@"Approve (%d)", count - approvedCount]:@"Approve")];
    [unapproveButton setTitle:(((count - unapprovedCount) > 0) ? [NSString stringWithFormat:@"Unapprove (%d)", count - unapprovedCount]:@"Unapprove")];
    [spamButton setTitle:(((count - spamCount) > 0) ? [NSString stringWithFormat:@"Spam (%d)", count - spamCount]:@"Spam")];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
    } else {
        cell.backgroundColor = TABLE_VIEW_CELL_ALT_BACKGROUND_COLOR;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Comments";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [commentsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PageCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    id comment = [commentsArray objectAtIndex:indexPath.row];

    if (cell == nil) {
        cell = [[[CommentTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    } else {
        [cell resetAsynchronousImageView];
    }

    cell.comment = comment;
    cell.editing = editing;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return COMMENT_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editing) {
        [self tableView:tableView didCheckRowAtIndexPath:indexPath];
    } else {
        CommentViewController *commentsViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:nil];

        // Get the navigation controller from the delegate
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate.navigationController pushViewController:commentsViewController animated:YES];

        [commentsViewController fillCommentDetails:[[BlogDataManager sharedDataManager] commentTitles]
         atRow:indexPath.row];
        [commentsViewController release];
    }
}

- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath {
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *comment = cell.comment;

    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    if ([selectedComments containsObject:comment]) {
        cell.checked = NO;
        [selectedComments removeObject:comment];
    } else {
        cell.checked = YES;
        [selectedComments addObject:comment];
    }

    [self updateSelectedComments];
}

@end
