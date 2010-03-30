//
//  CommentsViewController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import "CommentsViewController.h"

#import "BlogDataManager.h"
#import "CommentTableViewCell.h"
#import "CommentViewController.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"
#import "Reachability.h"

#define COMMENTS_SECTION        0
#define NUM_SECTIONS            1

#define ALL_COMMENTS		0
#define PENDING_COMMENTS	1

@interface CommentsViewController (Private)

- (void)scrollToFirstCell;
- (void)setEditing:(BOOL)value;
- (void)updateSelectedComments;
- (void)refreshHandler;
- (void)moderateCommentsWithSelector:(SEL)selector;
- (void)deleteComments;
- (void)approveComments;
- (void)markCommentsAsSpam;
- (void)unapproveComments;
- (void)syncComments;
- (void)addRefreshButton;
- (void)updateBadge;
- (void)reloadTableView;
- (void)limitToOnHold;
- (void)doNotLimit;
- (NSMutableArray *)commentsOnHold;
@end

@implementation CommentsViewController

@synthesize editButtonItem, selectedComments, commentsArray, indexForCurrentPost, segmentedControl;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[segmentedControl release];
    [commentsArray release];
    [commentsDict release];
    [selectedComments release];
    [editButtonItem release];
    [refreshButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    commentsDict = [[NSMutableDictionary alloc] init];
    selectedComments = [[NSMutableArray alloc] init];
    
    [commentsTableView setDataSource:self];
    commentsTableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    
    [self addRefreshButton];
    
    editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered
                                                     target:self action:@selector(editComments)];
	
	// segmented control as the custom title view
	NSArray *segmentTextContent = [NSArray arrayWithObjects:
								   NSLocalizedString(@"All", @""),
								   NSLocalizedString(@"Pending", @""),
								   nil];
	segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	segmentedControl.selectedSegmentIndex = ALL_COMMENTS;
	segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.frame = CGRectMake(0, 0, 170, 30);
	[segmentedControl addTarget:self action:@selector(reloadTableView) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self setEditing:NO];
    
    BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
    [sharedDataManager loadCommentTitlesForCurrentBlog];
    
    [editToolbar setHidden:YES];
    self.navigationItem.rightBarButtonItem = editButtonItem;
    
    if ([commentsTableView indexPathForSelectedRow]) {
        [commentsTableView scrollToRowAtIndexPath:[commentsTableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:animated];
    }
    
	[self refreshCommentsList];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([[Reachability sharedReachability] internetConnectionStatus])
	{
		if ([defaults boolForKey:@"refreshCommentsRequired"]) {
			[self refreshHandler];
			[defaults setBool:false forKey:@"refreshCommentsRequired"];
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated {
    editButtonItem.title = @"Edit";
    [super viewWillDisappear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [commentsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
//    if ([delegate isAlertRunning] == YES) {
//        return NO;
//    } else {
//	NSLog(@"inside commentsviewcontroller's should autorotate");
//        return YES;
//    }
	//return NO;
	if(interfaceOrientation == UIInterfaceOrientationPortrait)
		return YES;
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -

- (void) cancelView {
	NSLog(@"inside Comments View Controller cancelView");
	

	[self.navigationController popViewControllerAnimated:YES];

}


- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, commentsTableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);

    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];

    commentsTableView.tableHeaderView = refreshButton;
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
    
    [commentsTableView setEditing:value animated:YES];
}

- (void)editComments {
	if ([UIApplication sharedApplication].networkActivityIndicatorVisible) {
		UIAlertView *currentlyUpdatingAlert = [[UIAlertView alloc] initWithTitle:@"Currently Syncing" message:@"The edit feature is disabled while syncing. Please try again in a few seconds." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[currentlyUpdatingAlert show];
		[currentlyUpdatingAlert release];
	}
	else {
		[self setEditing:!editing];
	}
}

#pragma mark -
#pragma mark Action Methods

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;
    
    if ([self tableView:commentsTableView numberOfRowsInSection:COMMENTS_SECTION] > 0) {
        NSUInteger indexes[] = {0, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
    
    if (indexPath) {
        [commentsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)refreshHandler {
    [refreshButton startAnimating];
	[self setEditing:false];
    [self performSelectorInBackground:@selector(syncComments) withObject:nil];
}

- (void)syncComments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
    [sharedBlogDataManager syncCommentsForCurrentBlog];
    [sharedBlogDataManager loadCommentTitlesForCurrentBlog];

    [self refreshCommentsList];

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning]) {
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        [progressAlert release];
    } else {
        [refreshButton stopAnimating];
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [pool release];
}

- (void)refreshCommentsList {
    if (!selectedComments) {
        selectedComments = [[NSMutableArray alloc] init];
    } else {
        [selectedComments removeAllObjects];
    }

    [self reloadTableView];

    for (NSDictionary *dict in commentsArray) {
        NSString *str = [dict valueForKey:@"comment_id"];
        [commentsDict setValue:dict forKey:str];
    }
    
    [editButtonItem setEnabled:([commentsArray count] > 0)];
    [self updateBadge];
    [commentsTableView reloadData];
}

- (IBAction)deleteSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(deleteComments) withObject:nil];
}

- (IBAction)approveSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(approveComments) withObject:nil];
}

- (IBAction)unapproveSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(unapproveComments) withObject:nil];
}

- (IBAction)spamSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(markCommentsAsSpam) withObject:nil];
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];

    [sharedDataManager performSelector:selector withObject:[self selectedComments] withObject:[sharedDataManager currentBlog]];

    [self refreshCommentsList];
    [self setEditing:FALSE];

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

- (void)showCommentAtIndex:(int)index {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:nil];
	commentViewController.commentsViewController = self;
	//[commentViewController showComment:commentsArray atIndex:index];
	
    [delegate.navigationController pushViewController:commentViewController animated:YES];

    [commentViewController showComment:commentsArray atIndex:index];
    [commentViewController release];
}

#pragma mark -
#pragma mark Segmented View Controls

- (void)reloadTableView {
	if ([segmentedControl selectedSegmentIndex] == ALL_COMMENTS) {
		[self doNotLimit];
	}
	else {
		[self limitToOnHold];
	}

	[self updateBadge];
    [commentsTableView reloadData];
}

#pragma mark -
#pragma mark Comments Scoping

- (void)limitToOnHold {
    [self setCommentsArray: [self commentsOnHold]];
}

- (void)doNotLimit {
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];

	if (indexForCurrentPost >= -1) {
        self.commentsArray = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog] scopedToPostWithIndex:indexForCurrentPost];
    } else {
        self.commentsArray = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];
    }
}

- (NSMutableArray *)commentsOnHold {
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	NSMutableArray *allComments = nil;
	
	if (indexForCurrentPost >= -1) {
        allComments = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog] scopedToPostWithIndex:indexForCurrentPost];
    } else {
        allComments = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];
    }

    NSMutableArray *commentsOnHold = [[NSMutableArray alloc] init];
	
    for (NSDictionary *comment in allComments) {
        if ([[comment valueForKey:@"status"] isEqualToString:@"hold"]) {
            [commentsOnHold addObject:comment];
        }
    }
	NSMutableArray *copyOfCommentsOnHold = [NSMutableArray arrayWithArray:commentsOnHold];
	[commentsOnHold release];
	return copyOfCommentsOnHold;
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSDictionary *dict = [selectedComments objectAtIndex:indexPath.row];
	id comment = [commentsArray objectAtIndex:indexPath.row];
	if ([[comment valueForKey:@"status"] isEqualToString:@"hold"]) {
		cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
	} else {
		cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
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
    static NSString *CellIdentifier = @"CommentCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    id comment = [commentsArray objectAtIndex:indexPath.row];

    if (cell == nil) {
        cell = [[[CommentTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.comment = comment;
    cell.checked = [selectedComments containsObject:comment];
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
        [self showCommentAtIndex:indexPath.row];
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

#pragma mark -
#pragma mark Update Badge

- (void)updateBadge {
    NSString *badge = nil;
	
	if (indexForCurrentPost < -1) {
		
		NSMutableArray *commentsOnHold = [self commentsOnHold];
		
		if ([commentsOnHold count] > 0) {
			badge = [[NSNumber numberWithInt:[commentsOnHold count]] stringValue];
		}
	}
    self.tabBarItem.badgeValue = badge;
}

@end
