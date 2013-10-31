
//  CommentsViewController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import "WPTableViewControllerSubclass.h"
#import "CommentsViewController.h"
#import "NewCommentsTableViewCell.h"
#import "CommentViewController.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"
#import "ReplyToCommentViewController.h"
#import "UIColor+Helpers.h"
#import "UIBarButtonItem+Styled.h"

@interface CommentsViewController ()

@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@end

@implementation CommentsViewController

CGFloat const CommentsStandardOffset = 16.0;
CGFloat const CommentsSectionHeaderHeight = 24.0;

- (id)init {
    self = [super init];
    if(self) {
        self.title = NSLocalizedString(@"Comments", @"");
    }
    return self;
}

- (void)dealloc {
    WPFLogMethod();
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)noResultsText
{
    return NSLocalizedString(@"No comments yet", @"Displayed when the user pulls up the comments view and they have no comments");
}

- (void)viewDidLoad {
    WPFLogMethod();
    
    [super viewDidLoad];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.tableView.accessibilityLabel = @"Comments";       // required for UIAutomation for iOS 4
	if([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		self.tableView.accessibilityIdentifier = @"Comments";  // required for UIAutomation for iOS 5
	}
    
    self.editButtonItem.enabled = [[self.resultsController fetchedObjects] count] > 0 ? YES : NO;
    
    // Do not show row dividers for empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (UIColor *)backgroundColorForRefreshHeaderView
{
    return [WPStyleGuide itsEverywhereGrey];
}

- (void)viewWillAppear:(BOOL)animated {
    WPFLogMethod();

	[super viewWillAppear:animated];
    
    self.panelNavigationController.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    WPFLogMethod();
    
    [super viewWillDisappear:animated];
    
    self.panelNavigationController.delegate = nil;
}


- (void)configureCell:(NewCommentsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    cell.comment = comment;
}

#pragma mark - DetailViewDelegate

- (void)resetView {
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath: [self.tableView indexPathForSelectedRow] animated:NO];
    }
}

#pragma mark -
#pragma mark Action Methods

- (void)showCommentAtIndexPath:(NSIndexPath *)indexPath {
    WPFLogMethodParam(indexPath);
	Comment *comment;
    if (indexPath) {
        @try {
            comment = [self.resultsController objectAtIndexPath:indexPath];
        }
        @catch (NSException * e) {
            DDLogInfo(@"Can't select comment at indexPath: (%i,%i)", indexPath.section, indexPath.row);
            DDLogInfo(@"sections: %@", self.resultsController.sections);
            DDLogInfo(@"results: %@", self.resultsController.fetchedObjects);
            comment = nil;
        }
    }
    
	if(comment) {
        [WPMobileStats trackEventForWPCom:StatsEventCommentsViewCommentDetails];
        
        self.currentIndexPath = indexPath;
        self.lastSelectedCommentID = comment.commentID; //store the latest user selection
        
        CommentViewController *vc = [[CommentViewController alloc] init];
        vc.comment = comment;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        [self.panelNavigationController pushViewController:vc fromViewController:self animated:YES];
    } else {
        [self.panelNavigationController popToViewController:self animated:YES];
    }
}

- (void)setWantedCommentId:(NSNumber *)wantedCommentId {
    if (![wantedCommentId isEqual:_wantedCommentId]) {
         _wantedCommentId = nil;
        if (wantedCommentId) {
            // First check if we already have the comment
            Comment *comment = [self commentWithId:wantedCommentId];
            if (comment) {
                NSIndexPath *wantedIndexPath = [self.resultsController indexPathForObject:comment];
                [self.tableView scrollToRowAtIndexPath:wantedIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
                [self showCommentAtIndexPath:wantedIndexPath];
            } else {
                [self willChangeValueForKey:@"wantedCommentId"];
                _wantedCommentId = wantedCommentId;
                [self didChangeValueForKey:@"wantedCommentId"];
                [self syncItemsWithUserInteraction:NO];
            }
        }
    }
}

- (Comment *)commentWithId:(NSNumber *)commentId {
    Comment *comment = [[[self.resultsController fetchedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentId]] lastObject];
    
    return comment;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSString *title = [Comment titleForStatus:[sectionInfo name]];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), CommentsSectionHeaderHeight)];
    view.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    label.text = [title uppercaseString];
    label.font = [WPStyleGuide labelFont];
    [label sizeToFit];
    CGFloat y = (CGRectGetHeight(view.frame) - CGRectGetHeight(label.frame))/2.0;
    label.frame = CGRectMake(16, y, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame));
    [view addSubview:label];

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CommentsSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    return [NewCommentsTableViewCell rowHeightForComment:comment andMaxWidth:CGRectGetWidth(self.tableView.bounds)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showCommentAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath {
}


#pragma mark - Subclass methods

- (NSString *)entityName {
    return @"Comment";
}

- (NSDate *)lastSyncDate {
    return self.blog.lastCommentsSync;
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(blog == %@ AND status != %@)", self.blog, @"spam"];
    NSSortDescriptor *sortDescriptorStatus = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorStatus, sortDescriptorDate];
    fetchRequest.fetchBatchSize = 10;
    return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
    return @"status";
}

- (UITableViewCell *)newCell {
    static NSString *cellIdentifier = @"CommentCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[NewCommentsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    [self.blog syncCommentsWithSuccess:success failure:failure];
}

- (BOOL)isSyncing {
	return self.blog.isSyncingComments;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [super controllerDidChangeContent:controller];
    
    if ([[self.resultsController fetchedObjects] count] > 0) {
        self.editButtonItem.enabled = YES;
    } else {
        self.editButtonItem.enabled = NO;
        self.currentIndexPath = nil;
    }
}
@end
