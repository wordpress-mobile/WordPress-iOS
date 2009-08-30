//
//  DashboardViewController.m
//  WordPress
//
//  Created by Gareth Townsend on 23/07/09.
//

#import "DashboardViewController.h"

#import "BlogDataManager.h"
#import "CommentTableViewCell.h"
#import "CommentViewController.h"
#import "ResourcesTableViewSection.h"
#import "WordPressAppDelegate.h"

#define COMMENTS_SECTION    0

#define ALL_COMMENTS		0
#define PENDING_COMMENTS	1

@interface DashboardViewController (Private)

- (void)scrollToFirstCell;
- (void)refreshHandler;
- (void)syncComments;
- (BOOL)isConnectedToHost;
- (void)addRefreshButton;
- (void)initCommentsMap;
- (void)calculateSections;
- (void)showCommentAtIndex:(int)index;
- (void)limitToOnHold;
- (void)doNotLimit;
- (NSMutableArray *)commentsOnHold;
- (void)updateBadge;
- (void)reloadTableView;
@end

@implementation DashboardViewController

@synthesize comments, commentsMap, commentsSections, segmentedControl;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [comments release];
    [commentsMap release];
    [refreshButton release];
    [commentsSections release];
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
    
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    
    [self addRefreshButton];
	
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
	[self updateBadge];
}

- (void)viewWillAppear:(BOOL)animated {  
    BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
    [sharedDataManager loadCommentTitlesForCurrentBlog];
    
    [self reloadTableView];
    [self scrollToFirstCell];
    [self refreshHandler];
        
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    }
    
    [super viewWillAppear:animated];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ([commentsSections count] == 0) ? 1 : [commentsSections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([commentsSections count] > 0) {
        ResourcesTableViewSection *commentsSection = [commentsSections objectAtIndex:section];
        return commentsSection.title;
    } else {
        return  @"No Comments";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([commentsSections count] > 0) {
        ResourcesTableViewSection *commentsSection = [commentsSections objectAtIndex:section];
        return commentsSection.numberOfRows;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CommentCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    ResourcesTableViewSection *commentsSection = [commentsSections objectAtIndex:indexPath.section];
    id comment = [commentsSection.resources objectAtIndex:indexPath.row];
    
    if (cell == nil) {
        cell = [[[CommentTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.comment = comment;
    cell.checked = NO;
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
    ResourcesTableViewSection *commentsSection = [commentsSections objectAtIndex:indexPath.section];
    id comment = [commentsSection.resources objectAtIndex:indexPath.row];
    int index = [comments indexOfObject:comment];
    [self showCommentAtIndex:index];
}

#pragma mark -
#pragma mark Private Methods

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, self.tableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);
    
    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableHeaderView = refreshButton;
}

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;
    
    if ([self tableView:self.tableView numberOfRowsInSection:COMMENTS_SECTION] > 0) {
        NSUInteger indexes[] = {0, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
    
    if (indexPath) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)refreshHandler {
    [refreshButton startAnimating];
    [self performSelectorInBackground:@selector(syncComments) withObject:nil];
}

- (void)syncComments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
    [sharedBlogDataManager syncCommentsForCurrentBlog];
    [sharedBlogDataManager loadCommentTitlesForCurrentBlog];
    
    [self reloadTableView];
    
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

- (void)showCommentAtIndex:(int)index {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:nil];
    
    [delegate.navigationController pushViewController:commentViewController animated:YES];
    
    [commentViewController showComment:comments atIndex:index];
    [commentViewController release];
}

- (void)initCommentsMap {
    NSMutableDictionary *newCommentsMap = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary *comment in comments) {
        NSString *commentId = [comment valueForKey:@"comment_id"];
        [newCommentsMap setValue:comment forKey:commentId];
    }
    
    self.commentsMap = newCommentsMap;
    [newCommentsMap release];
}

- (void)calculateSections {
    ResourcesTableViewSection *commentsSection = nil;

    NSMutableArray *newCommentsSections = [[NSMutableArray alloc] init];
    NSMutableDictionary *dateToCommentSectionMap = [[NSMutableDictionary alloc] init];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];

    for (id comment in comments) {
        NSString *dateString = [dateFormat stringFromDate:[comment objectForKey:@"date_created_gmt"]];

        if ([dateToCommentSectionMap objectForKey:dateString] == nil) {
            commentsSection = [[ResourcesTableViewSection alloc] initWithTitle:dateString];
            [newCommentsSections addObject:commentsSection];
            [dateToCommentSectionMap setObject:commentsSection forKey:dateString];
            [commentsSection release];
        } else {
            commentsSection = [dateToCommentSectionMap objectForKey:dateString];
        }

        commentsSection.numberOfRows = commentsSection.numberOfRows + 1;
        [commentsSection.resources addObject:comment];
    }

    self.commentsSections = newCommentsSections;
    
    [dateFormat release];
    [dateToCommentSectionMap release];
    [newCommentsSections release];
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
	[self initCommentsMap];
    [self calculateSections];
	[self updateBadge];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Comments Scoping

- (void)limitToOnHold {
    [self setComments: [self commentsOnHold]];
}

- (void)doNotLimit {
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	[self setComments: [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]]];
}

- (NSMutableArray *)commentsOnHold {
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	NSMutableArray *allComments = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];
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
#pragma mark Tab Badge

- (void)updateBadge {
    NSString *badge = nil;
	NSMutableArray *commentsOnHold = [self commentsOnHold];
	
    if ([commentsOnHold count] > 0) {
        badge = [[NSNumber numberWithInt:[commentsOnHold count]] stringValue];
    }
	
    self.tabBarItem.badgeValue = badge;
}

@end