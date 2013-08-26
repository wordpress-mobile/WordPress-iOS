
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
#import "WPStyleGuide.h"

@interface CommentsViewController () <UIActionSheetDelegate> {
    NSMutableArray *_selectedComments;
}

@property (nonatomic,strong) CommentViewController *commentViewController;
@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@end

@implementation CommentsViewController

CGFloat const ModerateCommentsActionSheetTag = 10;
CGFloat const ConfirmDeletionActionSheetTag = 20;
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

- (void)viewDidLoad {
    WPFLogMethod();
    
    [super viewDidLoad];
    
    self.tableView.accessibilityLabel = @"Comments";       // required for UIAutomation for iOS 4
	if([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		self.tableView.accessibilityIdentifier = @"Comments";  // required for UIAutomation for iOS 5
	}
    
    if (_selectedComments == nil) {
        _selectedComments = [[NSMutableArray alloc] init];
    }
    
    self.editButtonItem.enabled = [[self.resultsController fetchedObjects] count] > 0 ? YES : NO;
    
    // Do not show row dividers for empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    WPFLogMethod();

	[super viewWillAppear:animated];
    
    self.commentViewController = nil;
    self.panelNavigationController.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    WPFLogMethod();
    [super viewWillDisappear:animated];
    
    self.panelNavigationController.delegate = nil;
}

#pragma mark -
- (void)confirmDeletingOfComments {
    int selectedCommentsCount = [_selectedComments count];
    NSString *titleString =  selectedCommentsCount > 1 ? [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete %d comments?", @""), selectedCommentsCount] : NSLocalizedString(@"Are you sure you want to delete the comment?", @""); 
    UIActionSheet *actionSheet;
    actionSheet = [[UIActionSheet alloc] initWithTitle:titleString 
                                              delegate:self 
                                     cancelButtonTitle:nil
                                destructiveButtonTitle:NSLocalizedString(@"Delete", @"") 
                                     otherButtonTitles:NSLocalizedString(@"Cancel", @""), nil ];
    actionSheet.tag = ConfirmDeletionActionSheetTag;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [actionSheet showInView:self.view];
}

- (void)cancelReplyToCommentViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configureCell:(NewCommentsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    cell.comment = comment;
}

#pragma mark -
#pragma mark Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ModerateCommentsActionSheetTag) {
        [self processModerateCommentActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    } else if (actionSheet.tag == ConfirmDeletionActionSheetTag) {
        if (buttonIndex == 0) {
            [self deleteSelectedComments:nil];
        }
    }
}

- (void)processModerateCommentActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    NSDictionary *mixpanelProperties = @{@"comment_count": @([_selectedComments count])};
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Approve Comment", nil)]) {
        [WPMobileStats trackEventForWPCom:StatsEventCommentsApproved properties:mixpanelProperties];
        [self moderateCommentsWithSelector:@selector(approve)];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Unapprove Comment", nil)]) {
        [WPMobileStats trackEventForWPCom:StatsEventCommentsUnapproved properties:mixpanelProperties];
        [self moderateCommentsWithSelector:@selector(unapprove)];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
        [WPMobileStats trackEventForWPCom:StatsEventCommentsDeleted properties:mixpanelProperties];
        [self confirmDeletingOfComments];
        return;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Flag as Spam", nil)]) {
        [WPMobileStats trackEventForWPCom:StatsEventCommentsFlagAsSpam properties:mixpanelProperties];
        [self moderateCommentsWithSelector:@selector(spam)];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Reply", nil)]) {
        [self replyToSelectedComment:nil];
    } else {
        [_selectedComments removeAllObjects];
        return;
    }
    
    [_selectedComments removeAllObjects];
    
    [self.tableView reloadData];
}

#pragma mark - DetailViewDelegate

- (void)resetView {
    //Reset a few things if extra panels were popped off on the iPad
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath: [self.tableView indexPathForSelectedRow] animated:NO];
    }
    self.commentViewController = nil;
}

#pragma mark -
#pragma mark Action Methods

- (void)deleteSelectedComments:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventCommentsDeleted properties:@{@"comment_count": @([_selectedComments count])}];
    [self moderateCommentsWithSelector:@selector(remove)];
}

- (void)approveSelectedComments:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventCommentsApproved properties:@{@"comment_count": @([_selectedComments count])}];
    [self moderateCommentsWithSelector:@selector(approve)];
}

- (void)unapproveSelectedComments:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventCommentsUnapproved properties:@{@"comment_count": @([_selectedComments count])}];
    [self moderateCommentsWithSelector:@selector(unapprove)];
}

- (void)spamSelectedComments:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventCommentsFlagAsSpam properties:@{@"comment_count": @([_selectedComments count])}];
    [self moderateCommentsWithSelector:@selector(spam)];
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    WPFLogMethodParam(NSStringFromSelector(selector));
    
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    //If the item shown in the 3rd panel was selected and the (spam|remove) action is called we need to dismiss the 3rd panel, or show another comment there.
    //Dismiss it for now.
    if( IS_IPAD && ( [@"remove" isEqualToString:NSStringFromSelector(selector)] ||  [@"spam" isEqualToString:NSStringFromSelector(selector)] ) 
       && self.commentViewController != nil && self.commentViewController.comment != nil ) {
        Comment *currentComentDetails = self.commentViewController.comment;
        for (Comment *comment in _selectedComments) {
            if([comment.commentID intValue] == [currentComentDetails.commentID intValue]) {
                [self.panelNavigationController popToViewController:self animated:NO];
                break;
            }
        }
    }
    
    if([self isSyncing]) {
        [self.blog.api cancelAllHTTPOperations];
        // Implemented by the super class but the interface is hidden.
        [self performSelector:@selector(hideRefreshHeader)];
    }
    
    [_selectedComments makeObjectsPerformSelector:selector];
    [self deselectAllComments];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommentsChangedNotificationName object:self.blog];
    [self removeSwipeView:NO];
}

- (void)deselectAllComments {
    [_selectedComments removeAllObjects];
}

- (void)showCommentAtIndexPath:(NSIndexPath *)indexPath {
    WPFLogMethodParam(indexPath);
	Comment *comment;
    if (indexPath) {
        @try {
            comment = [self.resultsController objectAtIndexPath:indexPath];
        }
        @catch (NSException * e) {
            WPFLog(@"Can't select comment at indexPath: (%i,%i)", indexPath.section, indexPath.row);
            WPFLog(@"sections: %@", self.resultsController.sections);
            WPFLog(@"results: %@", self.resultsController.fetchedObjects);
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

- (void)replyToSelectedComment:(id)sender {
    
    // CommentViewController disables replies when there is no internet connection.
    // So we won't show the edit/reply screen here either.
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    [WPMobileStats trackEventForWPCom:StatsEventCommentsReplied];
    
    Comment *selectedComment = [_selectedComments objectAtIndex:0];

    ReplyToCommentViewController *replyToCommentViewController = [[ReplyToCommentViewController alloc]
                                                                   initWithNibName:@"ReplyToCommentViewController"
                                                                   bundle:nil];

    replyToCommentViewController.delegate = self;
    replyToCommentViewController.comment = [selectedComment newReply];
    replyToCommentViewController.title = NSLocalizedString(@"Comment Reply", @"Comment Reply view title");

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:replyToCommentViewController];
    navController.navigationBar.translucent = NO;
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navController animated:YES completion:nil];
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString *approveOrUnapproveString;
    if ([comment.status isEqualToString:@"approve"]) {
        approveOrUnapproveString = NSLocalizedString(@"Unapprove Comment", nil);
    } else {
        approveOrUnapproveString = NSLocalizedString(@"Approve Comment", nil);
    }
    
    [_selectedComments removeAllObjects];
    [_selectedComments addObject:comment];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Moderate Comment", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Delete", nil), approveOrUnapproveString, NSLocalizedString(@"Flag as Spam", nil), NSLocalizedString(@"Reply", nil), nil];
    actionSheet.tag = ModerateCommentsActionSheetTag;
    [actionSheet showFromRect:cell.frame inView:self.view animated:YES];
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Moderate", nil);
}

#pragma mark - Subclass methods

- (NSString *)entityName {
    return @"Comment";
}

- (NSDate *)lastSyncDate {
    return self.blog.lastCommentsSync;
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [super fetchRequest];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(blog == %@ AND status != %@)", self.blog, @"spam"]];
    NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorStatus, sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
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
