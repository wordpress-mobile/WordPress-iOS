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
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"

#define COMMENTS_SECTION        0

@interface DashboardViewController (Private)

- (void)scrollToFirstCell;
- (void)refreshHandler;
- (void)syncComments;
- (BOOL)isConnectedToHost;
- (void)refreshCommentsList;
- (void)addRefreshButton;
- (void)calculateSections;
@end

@implementation DashboardViewController

@synthesize commentsArray, sectionHeaders;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [commentsArray release];
    [commentsDict release];
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
    
    commentsDict = [[NSMutableDictionary alloc] init];
    
    [commentsTableView setDataSource:self];
    commentsTableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    
    [self addRefreshButton];
}

- (void)viewWillAppear:(BOOL)animated {  
    
    BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
    [sharedDataManager loadCommentTitlesForCurrentBlog];
    
    [self refreshCommentsList];
    [self scrollToFirstCell];
    [self refreshHandler];
        
    if ([commentsTableView indexPathForSelectedRow]) {
        [commentsTableView scrollToRowAtIndexPath:[commentsTableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:animated];
    }
    
    [super viewWillAppear:animated];
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

#pragma mark -

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, commentsTableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);
    
    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];
    
    commentsTableView.tableHeaderView = refreshButton;
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
    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
        
    [self setCommentsArray:[sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]]];
    
    for (NSDictionary *dict in commentsArray) {
        NSString *str = [dict valueForKey:@"comment_id"];
        [commentsDict setValue:dict forKey:str];
    }
    
    if (([commentsArray count] > 0) && (![(NSDictionary *)[commentsArray objectAtIndex:0] objectForKey:@"author_url"])) {
        progressAlert = [[WPProgressHUD alloc] initWithLabel:@"updating"];
        [progressAlert show];
        
        [self performSelectorInBackground:@selector(downloadRecentComments) withObject:nil];
    }
    
    [self calculateSections];
    [commentsTableView reloadData];
}

- (void)showCommentAtIndex:(int)index {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:nil];
    
    [delegate.navigationController pushViewController:commentViewController animated:YES];
    
    [commentViewController showComment:commentsArray atIndex:index];
    [commentViewController release];
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
    return ([sectionHeaders count] == 0) ? @"No Comments" : [[sectionHeaders objectAtIndex:section] objectForKey:@"date"];  
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ([sectionHeaders count] == 0) ? 0 : [[[sectionHeaders objectAtIndex:section] objectForKey:@"numberOfComments"] intValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PageCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    id comment = [[sectionHeaders objectAtIndex:indexPath.section] objectForKey:[NSString stringWithFormat:@"%i", indexPath.row]];
    
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
    [self showCommentAtIndex:[[[[sectionHeaders objectAtIndex:indexPath.section] objectForKey:[NSString stringWithFormat:@"%i", indexPath.row]] objectForKey:@"index"] intValue]];
}

- (void)calculateSections {
    NSMutableDictionary *dates = [[NSMutableDictionary alloc] init];
    NSMutableArray *sectionDateMapping = [[NSMutableArray alloc] init];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];
    
    int index = 0;
    for (NSDictionary *comment in commentsArray) {
        NSString *dateString = [dateFormat stringFromDate:[comment objectForKey:@"date_created_gmt"]];
        [comment setValue:[NSNumber numberWithInt:index] forKey:@"index"];

        if ([dates objectForKey:dateString] == nil) {
            [dates setObject:[NSNumber numberWithInt:[dates count]] forKey:dateString];
            
            NSMutableDictionary *commentContainer = [[NSMutableDictionary alloc] init];
            [commentContainer setObject:dateString forKey:@"date"];
            [commentContainer setObject:[NSNumber numberWithInt:1] forKey:@"numberOfComments"];
            [commentContainer setObject:comment forKey:@"0"];
            
            [sectionDateMapping addObject:commentContainer];
            [commentContainer release];
        }
        else {
            int dateArrayIndex = [[dates objectForKey:dateString] intValue];
            NSNumber *numberOfComments = [NSNumber numberWithInt:[[[sectionDateMapping objectAtIndex:dateArrayIndex] objectForKey:@"numberOfComments"] intValue] +1];
            [[sectionDateMapping objectAtIndex:dateArrayIndex] setObject:numberOfComments forKey:@"numberOfComments"];
            [[sectionDateMapping objectAtIndex:dateArrayIndex] setObject:comment forKey:[NSString stringWithFormat:@"%i", [numberOfComments intValue] -1]];
        }
        index++;
    }
    self.sectionHeaders = sectionDateMapping;
    
    [dateFormat release];
    [sectionDateMapping release];
    [dates release];
}

@end