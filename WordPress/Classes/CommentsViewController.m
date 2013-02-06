//
//  CommentsViewController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import "WPTableViewControllerSubclass.h"
#import "CommentsViewController.h"
#import "CommentTableViewCell.h"
#import "CommentViewController.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"
#import "ReplyToCommentViewController.h"
#import "UIColor+Helpers.h"
#import "UIBarButtonItem+Styled.h"

@interface CommentsViewController () <CommentViewControllerDelegate, UIActionSheetDelegate>
@property (nonatomic,strong) CommentViewController *commentViewController;
@property (nonatomic,strong) NSIndexPath *currentIndexPath;
- (void)updateSelectedComments;
- (void)deselectAllComments;
- (void)moderateCommentsWithSelector:(SEL)selector;
- (Comment *)commentWithId:(NSNumber *)commentId;
- (void)confirmDeletingOfComments;
@end

@interface CommentsViewController (Private)
- (void)tryToSelectLastComment;
- (void)showCommentAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation CommentsViewController {
    NSMutableArray *_selectedComments;
}

@synthesize wantedCommentId = _wantedCommentId;
@synthesize commentViewController = _commentViewController;
@synthesize currentIndexPath = _currentIndexPath;
@synthesize lastSelectedCommentID = _lastSelectedCommentID;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.commentViewController.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle Methods

- (id)init {
    self = [super init];
    if(self) {
        self.title = NSLocalizedString(@"Comments", @"");
    }
    return self;
}


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    if (!IS_IPAD) {
        self.swipeActionsEnabled = YES;        
    }
        
    spamButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_flag"] style:UIBarButtonItemStylePlain target:self action:@selector(spamSelectedComments:)];
    unapproveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_unapprove"] style:UIBarButtonItemStylePlain target:self action:@selector(unapproveSelectedComments:)];
    approveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_approve"] style:UIBarButtonItemStylePlain target:self action:@selector(approveSelectedComments:)];
    deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_delete"] style:UIBarButtonItemStylePlain target:self action:@selector(confirmDeletingOfComments)];

    if (IS_IPHONE) {
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.toolbarItems = [NSArray arrayWithObjects:approveButton, spacer, unapproveButton, spacer, spamButton, spacer, deleteButton, nil];
    }

    self.tableView.accessibilityLabel = @"Comments";       // required for UIAutomation for iOS 4
	if([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		self.tableView.accessibilityIdentifier = @"Comments";  // required for UIAutomation for iOS 5
	}
    
    if (_selectedComments == nil)
        _selectedComments = [[NSMutableArray alloc] init];
    
    self.editButtonItem.enabled = [[self.resultsController fetchedObjects] count] > 0 ? YES : NO;
    
    // Do not show row dividers for empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
     _selectedComments = nil;
     spamButton = nil;
     unapproveButton = nil;
     approveButton = nil;
     deleteButton = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewWillAppear:animated];
    [self setEditing:NO animated:animated];
    if (IS_IPHONE) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    } else {
        self.toolbarItems = [NSArray arrayWithObject:self.editButtonItem];
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:NO];
    }
    self.commentViewController.delegate = nil;
    self.commentViewController = nil;
    self.panelNavigationController.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
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
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [actionSheet showFromBarButtonItem:deleteButton animated:YES];
}

- (void)cancelReplyToCommentViewController:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self deselectAllComments];
    [self updateSelectedComments];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if (IS_IPHONE) {
        [self.navigationController setToolbarHidden:!editing animated:animated];
    } else {
        if (editing) { 
            // intentionally doubling spacers to get the layout we want on the ipad
            self.toolbarItems = [NSArray arrayWithObjects:self.editButtonItem, spacer,  approveButton, spacer, spacer, unapproveButton, spacer, spacer, spamButton, spacer, spacer, deleteButton, spacer, nil];
        } else {
            self.toolbarItems = [NSArray arrayWithObject:self.editButtonItem];
        }
        //make sure the panel is completely visible
        if (self.panelNavigationController) {
            [self.panelNavigationController viewControllerWantsToBeFullyVisible:self];
        }
        if (self.swipeActionsEnabled) {
            [self removeSwipeView:YES];
        }
    }
    
    [deleteButton setEnabled:!editing];
    [approveButton setEnabled:!editing];
    [unapproveButton setEnabled:!editing];
    [spamButton setEnabled:!editing];

    if ( IS_IPAD && !editing && self.currentIndexPath )
        [self tryToSelectLastComment];

	[self deselectAllComments];
}

- (void) stopEditing:(id)sender {
    [self setEditing:NO animated:YES];
}

- (void) startEditing:(id)sender {
    [self setEditing:YES animated:YES];
}

- (void)configureCell:(CommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    cell.comment = comment;
    cell.checked = [_selectedComments containsObject:comment];
    cell.editing = self.editing;
}

#pragma mark -
#pragma mark Action Sheet Delegate Methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    if(buttonIndex == 0) {
        [self deleteSelectedComments:deleteButton];
    }
}

#pragma mark - DetailViewDelegate

- (void)resetView {
    //Reset a few things if extra panels were popped off on the iPad
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath: [self.tableView indexPathForSelectedRow] animated: NO];
    }
    self.commentViewController = nil;
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)deleteSelectedComments:(id)sender {
    [self moderateCommentsWithSelector:@selector(remove)];
}

- (IBAction)approveSelectedComments:(id)sender {
    [self moderateCommentsWithSelector:@selector(approve)];
}

- (IBAction)unapproveSelectedComments:(id)sender {
    [self moderateCommentsWithSelector:@selector(unapprove)];
}

- (IBAction)spamSelectedComments:(id)sender {
    [self moderateCommentsWithSelector:@selector(spam)];
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    [FileLogger log:@"%@ %@%@", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector)];
    
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
            if( [comment.commentID intValue] == [currentComentDetails.commentID intValue] ) {
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
    [self updateSelectedComments];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommentsChangedNotificationName object:self.blog];
    [self removeSwipeView:NO];
}

- (void)updateSelectedComments {
    int i, approvedCount, unapprovedCount, spamCount, count = [_selectedComments count];

    approvedCount = unapprovedCount = spamCount = 0;

    for (i = 0; i < count; i++) {
        Comment *comment = [_selectedComments objectAtIndex:i];

        if ([comment.status isEqualToString:@"hold"]) {
            unapprovedCount++;
        } else if ([comment.status isEqualToString:@"approve"]) {
            approvedCount++;
        } else if ([comment.status isEqualToString:@"spam"]) {
            spamCount++;
        }
    }

    [deleteButton setEnabled:(count > 0)];
    [approveButton setEnabled:((count - approvedCount) > 0)];
    [unapproveButton setEnabled:((count - unapprovedCount) > 0)];
    [spamButton setEnabled:((count - spamCount) > 0)];

}

- (void)deselectAllComments {
    for (Comment *comment in _selectedComments) {
        // In iOS4, indexPathForObject crashes when comment isn't in the results controller,
        // which happens after deleting comments
        @try {
            NSIndexPath *indexPath = [self.resultsController indexPathForObject:comment];
            if (indexPath) {
                CommentTableViewCell *cell = (CommentTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (cell) {
                    cell.checked = NO;
                }
            }
        }
        @catch (NSException *exception) {
        }
    }
    [_selectedComments removeAllObjects];
}

//Just highlight 
- (void)tryToSelectLastComment {
    WPFLogMethod();
    //try to move the comments list on the last user selected comment
	if(self.lastSelectedCommentID != nil) {
		NSArray *sections = [self.resultsController sections];
		int currentSectionIndex = 0;
		for (currentSectionIndex = 0; currentSectionIndex < [sections count]; currentSectionIndex++) {
			id <NSFetchedResultsSectionInfo> sectionInfo = nil;
			sectionInfo = [sections objectAtIndex:currentSectionIndex];
			
			int currentCommentIndex = 0;
			NSArray *commentsForSection = [sectionInfo objects];
			
			for (currentCommentIndex = 0; currentCommentIndex < [commentsForSection count]; currentCommentIndex++) {
				Comment *cmt = [commentsForSection objectAtIndex:currentCommentIndex];
				//NSLog(@"comment ID == %@", cmt.commentID);
				//NSLog(@"self.comment ID == %@", self.lastUserSelectedCommentID);
				if([cmt.commentID  compare:self.lastSelectedCommentID] == NSOrderedSame) { 
					self.currentIndexPath = [NSIndexPath indexPathForRow:currentCommentIndex inSection:currentSectionIndex];
					[self.tableView selectRowAtIndexPath:self.currentIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                    return;
				}
			}
		}
	}
    
    /*Last selected comment is gone, try to select something?
    Comment *comment;
    if (self.currentIndexPath) {
        @try {
            comment = [self.resultsController objectAtIndexPath:self.currentIndexPath];
        }
        @catch (NSException * e) {
            WPFLog(@"Can't highlight comment at indexPath: (%i,%i)", self.currentIndexPath.section, self.currentIndexPath.row);
            WPFLog(@"sections: %@", self.resultsController.sections);
            WPFLog(@"results: %@", self.resultsController.fetchedObjects);
            comment = nil;
        }
    }
	if(comment)
        [self.tableView selectRowAtIndexPath:self.currentIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    */
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
        self.currentIndexPath = indexPath;
        self.lastSelectedCommentID = comment.commentID; //store the latest user selection
        BOOL animated = ([self commentViewController] == nil) && IS_IPHONE;
        
        self.commentViewController = [[CommentViewController alloc] init];
        self.commentViewController.delegate = self;
        [self.commentViewController showComment:comment];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        [self.panelNavigationController pushViewController:self.commentViewController fromViewController:self animated:animated];
    } else {
        [self.panelNavigationController popToViewController:self animated:NO];
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

- (IBAction)replyToSelectedComment:(id)sender {
    
    // CommentViewController disables replies when there is no internet connection.
    // So we won't show the edit/reply screen here either.
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    Comment *selectedComment = [_selectedComments objectAtIndex:0];

    ReplyToCommentViewController *replyToCommentViewController = [[ReplyToCommentViewController alloc]
                                                                   initWithNibName:@"ReplyToCommentViewController"
                                                                   bundle:nil];

    replyToCommentViewController.delegate = self;
    replyToCommentViewController.comment = [selectedComment newReply];
    replyToCommentViewController.title = NSLocalizedString(@"Comment Reply", @"Comment Reply view title");

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:replyToCommentViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navController animated:YES];

    [self removeSwipeView:NO];
}

- (Comment *)commentWithId:(NSNumber *)commentId {
    Comment *comment = [[[self.resultsController fetchedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentId]] lastObject];
    
    return comment;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    if (comment.isNew) {
        cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
        if ([comment.status isEqual:@"hold"]) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [UIView animateWithDuration:1.0
                                      delay:1.0
                                    options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
                                     [cell.backgroundView setAlpha:0.7f];
                                 } completion:nil];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [UIView animateWithDuration:1.0
                                      delay:1.0
                                    options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
                                 } completion:^(BOOL finished) {
                                     [UIView animateWithDuration:0.5
                                                           delay:1.0
                                                         options:UIViewAnimationOptionAllowUserInteraction
                                                      animations:^{
                                                          cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
                                                          [cell.backgroundView setAlpha:1.0f];
                                                      }
                                                      completion:nil];
                                 }];
            });
        }
        comment.isNew = NO;
    } else if ([comment.status isEqual:@"hold"]) {
        cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
        [cell.backgroundView setAlpha:0.7f];
    } else {
        cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
        [cell.backgroundView setAlpha:1.0f];
    }

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [Comment titleForStatus:[sectionInfo name]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    float cellH = [CommentTableViewCell calculateCommentCellHeight:comment.content availableWidth:self.view.bounds.size.width];
//    WPLog(@"Expected size: %f", cellH);
    return cellH;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        [self tableView:tableView didCheckRowAtIndexPath:indexPath];
    } else {
        [self showCommentAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath {
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    Comment *comment = cell.comment;
	
	//danroundhill - added nil check based on crash reports
	if (comment != nil){
	
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

		if ([_selectedComments containsObject:comment]) {
			cell.checked = NO;
			[_selectedComments removeObject:comment];
		} else {
			cell.checked = YES;
			[_selectedComments addObject:comment];
		}

		[self updateSelectedComments];
	}
}

#pragma mark -
#pragma mark Comment navigation

- (NSIndexPath *)indexPathForPreviousComment {
    NSIndexPath *currentIndexPath = self.currentIndexPath;
    if (currentIndexPath == nil) return nil;

    NSIndexPath *indexPath = nil;
    if (currentIndexPath.row == 0 && currentIndexPath.section > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:currentIndexPath.section - 1];
        indexPath = [NSIndexPath indexPathForRow:sectionInfo.numberOfObjects - 1 inSection:currentIndexPath.section - 1];
    } else if (currentIndexPath.row > 0) {
        indexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:currentIndexPath.section];
    }
    return indexPath;
}

- (BOOL)hasPreviousComment {
    return ([self indexPathForPreviousComment] != nil);
}

- (void)showPreviousComment {
    NSIndexPath *indexPath = [self indexPathForPreviousComment];

    if (indexPath) {
        [self showCommentAtIndexPath:indexPath];
	}
}

- (NSIndexPath *)indexPathForNextComment {
    NSIndexPath *currentIndexPath = self.currentIndexPath;
    if (currentIndexPath == nil) return nil;

    NSIndexPath *indexPath = nil;
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:currentIndexPath.section];
    if ((currentIndexPath.row + 1) >= sectionInfo.numberOfObjects) {
        // Was last row in section
        if ((currentIndexPath.section + 1) < [[self.resultsController sections] count]) {
            // There are more sections
            indexPath = [NSIndexPath indexPathForRow:0 inSection:currentIndexPath.section + 1];
        }
    } else {
        indexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:currentIndexPath.section];
    }

    return indexPath;
}

- (BOOL)hasNextComment {
    return ([self indexPathForNextComment] != nil);
}

- (void)showNextComment {
    NSIndexPath *indexPath = [self indexPathForNextComment];

    if (indexPath) {
        [self showCommentAtIndexPath:indexPath];
    }
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
    // To comply with apple ownership and naming conventions, returned cell should have a retain count > 0, so retain the dequeued cell.
    static NSString *cellIdentifier = @"CommentCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        [cell setBackgroundView:imageView];
    }
    return cell;
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    [self.blog syncCommentsWithSuccess:success failure:failure];
}

- (BOOL)isSyncing {
	return self.blog.isSyncingComments;
}

- (void)configureSwipeView:(UIView *)swipeView forIndexPath:(NSIndexPath *)indexPath {
    CGFloat swipeViewWidth = swipeView.bounds.size.width;
    CGFloat padding = 2.0f;
    CGFloat buttonCount = 4;
    CGFloat height = 37.0f;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    CGFloat y = (cell.bounds.size.height - height) / 2.0f;

    /*
     | padding || button padding | button | button padding || button padding | button | button padding || ... || padding |
     */
    CGFloat buttonWidth = (swipeViewWidth - 2.0f * padding) / buttonCount - 2 * padding;
    CGFloat x = padding * 2.0f;

    UIButton *button;
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    [_selectedComments removeAllObjects];
    [_selectedComments addObject:comment];

//    UIImage* buttonImage = [[UIImage imageNamed:@"UISegmentBarBlackButton"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
//    UIImage* buttonPressedImage = [[UIImage imageNamed:@"UISegmentBarBlackButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];

    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(x, y, buttonWidth, height);
    if([comment.status isEqualToString:@"approve"]){
        [button setImage:[UIImage imageNamed:@"toolbar_swipe_unapprove"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(unapproveSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [button setImage:[UIImage imageNamed:@"toolbar_swipe_approve"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(approveSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
    }
    [swipeView addSubview:button];
    x += buttonWidth + 2 * padding;
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"toolbar_swipe_flag"] forState:UIControlStateNormal];
    button.frame = CGRectMake(x, y, buttonWidth, height);
    [button addTarget:self action:@selector(spamSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
    [swipeView addSubview:button];
    x += buttonWidth + 2 * padding;
        
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"toolbar_swipe_trash"] forState:UIControlStateNormal];
    button.frame = CGRectMake(x, y, buttonWidth, height);
    [button addTarget:self action:@selector(deleteSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
    [swipeView addSubview:button];
    x += buttonWidth + 2 * padding;
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"toolbar_swipe_reply"] forState:UIControlStateNormal];
    button.frame = CGRectMake(x, y, buttonWidth, height);
    [button addTarget:self action:@selector(replyToSelectedComment:) forControlEvents:UIControlEventTouchUpInside];
    [swipeView addSubview:button];

}

- (void)removeSwipeView:(BOOL)animated {
    if (!self.editing) {
        [_selectedComments removeAllObjects];
    }
    [super removeSwipeView:animated];
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
