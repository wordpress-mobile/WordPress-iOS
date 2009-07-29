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

#define COMMENTS_SECTION        0

@interface DashboardViewController (Private)

- (void)initCommentsMap;
- (void)scrollToFirstCell;
- (void)refreshHandler;
- (void)syncComments;
- (BOOL)isConnectedToHost;
- (void)refreshCommentsList;
- (void)addRefreshButton;
- (void)calculateSections;
- (void)showCommentAtIndex:(int)index;

@end

@implementation DashboardViewController

@synthesize comments, sectionHeaders;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [comments release];
    [commentsMap release];
    [refreshButton release];
    [sectionHeaders release];
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
}

- (void)viewWillAppear:(BOOL)animated {  
    BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
    [sharedDataManager loadCommentTitlesForCurrentBlog];
    
    [self refreshCommentsList];
    [self scrollToFirstCell];
    [self refreshHandler];
        
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    }
    
    [super viewWillAppear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    if ([delegate isAlertRunning] == YES) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ([sectionHeaders count] == 0) ? 1 : [sectionHeaders count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([sectionHeaders count] > 0) {
        ResourcesTableViewSection *tableViewSection = [sectionHeaders objectAtIndex:section];
        return tableViewSection.title;
    } else {
        return  @"No Comments";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([sectionHeaders count] > 0) {
        ResourcesTableViewSection *tableViewSection = [sectionHeaders objectAtIndex:section];
        return tableViewSection.numberOfRows;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CommentCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    ResourcesTableViewSection *tableViewSection = [sectionHeaders objectAtIndex:indexPath.section];
    id comment = [tableViewSection.resources objectAtIndex:indexPath.row];
    
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
    ResourcesTableViewSection *tableViewSection = [sectionHeaders objectAtIndex:indexPath.section];
    id comment = [tableViewSection.resources objectAtIndex:indexPath.row];
    int index = [[comment objectForKey:@"index"] intValue];
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

- (void)initCommentsMap {
    if (commentsMap) {
        [commentsMap release];
        commentsMap = nil;
    }
    
    commentsMap = [[NSMutableDictionary alloc] init];
}

- (void)refreshCommentsList {
    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
    [self setComments:[sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]]];
    
    [self initCommentsMap];
    
    for (NSDictionary *comment in comments) {
        NSString *commentId = [comment valueForKey:@"comment_id"];
        [commentsMap setValue:comment forKey:commentId];
    }
    
    [self calculateSections];
    [self.tableView reloadData];
}

- (void)showCommentAtIndex:(int)index {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:nil];
    
    [delegate.navigationController pushViewController:commentViewController animated:YES];
    
    [commentViewController showComment:comments atIndex:index];
    [commentViewController release];
}

- (void)calculateSections {
    ResourcesTableViewSection *tableViewSection = nil;

    NSMutableDictionary *dates = [[NSMutableDictionary alloc] init];
    NSMutableArray *tableViewSections = [[NSMutableArray alloc] init];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];
    
    int index = 0;

    for (id comment in comments) {
        NSString *dateString = [dateFormat stringFromDate:[comment objectForKey:@"date_created_gmt"]];
        [comment setValue:[NSNumber numberWithInt:index] forKey:@"index"];

        if ([dates objectForKey:dateString] == nil) {
            [dates setObject:[NSNumber numberWithInt:[dates count]] forKey:dateString];
            
            tableViewSection = [[ResourcesTableViewSection alloc] initWithTitle:dateString];
            [tableViewSections addObject:tableViewSection];
            [tableViewSection release];
        } else {
            int dateArrayIndex = [[dates objectForKey:dateString] intValue];
            tableViewSection = [tableViewSections objectAtIndex:dateArrayIndex];
        }

        tableViewSection.numberOfRows = tableViewSection.numberOfRows + 1;
        [tableViewSection.resources addObject:comment];

        index++;
    }

    self.sectionHeaders = tableViewSections;
    
    [dateFormat release];
    [tableViewSections release];
    [dates release];
}

@end