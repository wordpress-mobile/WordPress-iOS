
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
#import "UIColor+Helpers.h"
#import "WPTableViewSectionHeaderView.h"
#import "Comment.h"

@interface CommentsViewController ()

@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@end

@implementation CommentsViewController

CGFloat const CommentsStandardOffset = 16.0;
CGFloat const CommentsSectionHeaderHeight = 24.0;

- (void)dealloc {
    DDLogMethod();
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)noResultsTitleText
{
    return NSLocalizedString(@"No comments yet", @"Displayed when the user pulls up the comments view and they have no comments");
}

- (void)viewDidLoad {
    DDLogMethod();
    
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Comments", @"");
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.tableView.accessibilityLabel = @"Comments";       // required for UIAutomation for iOS 4
	if([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		self.tableView.accessibilityIdentifier = @"Comments";  // required for UIAutomation for iOS 5
	}
    
    self.editButtonItem.enabled = [[self.resultsController fetchedObjects] count] > 0 ? YES : NO;
    
    // Do not show row dividers for empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    DDLogMethod();

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    DDLogMethod();
    
    [super viewWillDisappear:animated];    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Returning to the comments list while the reply-to keyboard is visible
    // messes with the bottom contentInset. Let's reset it just in case.
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = 0;
    self.tableView.contentInset = contentInset;
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
    DDLogMethodParam(indexPath);
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
        
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [self.navigationController popToViewController:self animated:YES];
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
                [self syncItems];
            }
        }
    }
}

- (Comment *)commentWithId:(NSNumber *)commentId {
    Comment *comment = [[[self.resultsController fetchedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentId]] lastObject];
    
    return comment;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Don't show a section title if there's only one section
    if ([tableView numberOfSections] <= 1)
        return nil;
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSString *title = [Comment titleForStatus:[sectionInfo name]];
    return title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    // Don't show a section title if there's only one section
    if ([tableView numberOfSections] <= 1) {
        return nil;
    }
    
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self tableView:self.tableView titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    // Don't show a section title if there's only one section
    if ([tableView numberOfSections] <= 1) {
        return IS_IPHONE ? 1 : WPTableViewTopMargin;
    }
    
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
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
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(blog == %@ AND status != %@ AND status != %@)", self.blog, CommentStatusSpam, CommentStatusDraft];
    NSSortDescriptor *sortDescriptorStatus = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorStatus, sortDescriptorDate];
    fetchRequest.fetchBatchSize = 10;
    return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
    return @"status";
}

- (Class)cellClass {
    return [NewCommentsTableViewCell class];
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
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
