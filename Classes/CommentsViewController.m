
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
#import "Reachability.h"
#import "BlogViewController.h"
#import "ReplyToCommentViewController.h"

@interface CommentsViewController (Private)

- (void)setEditing:(BOOL)value;
- (void)updateSelectedComments;
- (void)moderateCommentsWithSelector:(SEL)selector;
- (void)deleteComments;
- (void)approveComments;
- (void)markCommentsAsSpam;
- (void)unapproveComments;
- (NSMutableArray *)commentsOnHold;
- (Comment *)commentWithId:(NSNumber *)commentId;
@end

@implementation CommentsViewController {
    NSMutableArray *_selectedComments;
}

@synthesize wantedCommentId = _wantedCommentId;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle Methods

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Comments", @"");
    spamButton.title = NSLocalizedString(@"Spam", @"");
    unapproveButton.title = NSLocalizedString(@"Unapprove", @"");
    approveButton.title = NSLocalizedString(@"Approve", @"");
        
    self.tableView.accessibilityLabel = @"Comments";       // required for UIAutomation for iOS 4
	if([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		self.tableView.accessibilityIdentifier = @"Comments";  // required for UIAutomation for iOS 5
	}
    
    _selectedComments = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [_selectedComments release]; _selectedComments = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewWillAppear:animated];
    [self setEditing:NO];
    //selectedIndexPath = nil;    
    [editToolbar setHidden:YES];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillDisappear:animated];
}

#pragma mark -

- (void)cancelReplyToCommentViewController:(id)sender {
	if (DeviceIsPad() == NO) {
		WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate.navigationController popViewControllerAnimated:YES];
	}
	else if (DeviceIsPad() == YES) {
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (void)setEditing:(BOOL)editing {
    [super setEditing:editing];
	
    // Adjust comments table view height to fit toolbar (if it's visible).
    CGFloat toolbarHeight = editing ? editToolbar.bounds.size.height : 0;
    CGRect mainViewBounds = self.view.bounds;
    CGRect rect = CGRectMake(mainViewBounds.origin.x,
                             mainViewBounds.origin.y,
                             mainViewBounds.size.width,
                             mainViewBounds.size.height - toolbarHeight);
	
    self.tableView.frame = rect;
	
    [editToolbar setHidden:!editing];
    [deleteButton setEnabled:!editing];
    [approveButton setEnabled:!editing];
    [unapproveButton setEnabled:!editing];
    [spamButton setEnabled:!editing];
	
	if(editing && _selectedComments) { //if we are switching to editing mode and there were selected comments
		if(_selectedComments.count > 0) { 
			if ([[self.resultsController fetchedObjects] count] > 0) {
				
				NSMutableArray *commentsToKeep = [NSMutableArray array] ;
				for (Comment  *commentInfo in [self.resultsController fetchedObjects]) {
					if ([_selectedComments containsObject:commentInfo]) {
						[commentsToKeep addObject:commentInfo];
					} 					
				}

				[_selectedComments removeAllObjects];
                [_selectedComments addObjectsFromArray:commentsToKeep];				
			} else {
				[_selectedComments removeAllObjects];
			}
		}
		[self updateSelectedComments];
	}	
}

- (void)configureCell:(CommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    cell.comment = comment;
    cell.checked = [_selectedComments containsObject:comment];
    cell.editing = self.editing;
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
    [_selectedComments makeObjectsPerformSelector:selector];
    if (self.editing) {
        for (Comment *comment in _selectedComments) {
            NSIndexPath *indexPath = [self.resultsController indexPathForObject:comment];
            if (indexPath) {
                CommentTableViewCell *cell = (CommentTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (cell) {
                    cell.checked = NO;
                }
            }
        }
    }
    [_selectedComments removeAllObjects];
    [self updateSelectedComments];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommentsChangedNotificationName object:self.blog];
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

    [approveButton setTitle:(((count - approvedCount) > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Approve (%d)", @""), count - approvedCount]:NSLocalizedString(@"Approve", @""))];
    [unapproveButton setTitle:(((count - unapprovedCount) > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Unapprove (%d)", @""), count - unapprovedCount]:NSLocalizedString(@"Unapprove", @""))];
    [spamButton setTitle:(((count - spamCount) > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Spam (%d)", @""), count - spamCount]:NSLocalizedString(@"Spam", @""))];
}

- (void)showCommentAtIndexPath:(NSIndexPath *)indexPath {
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
        CommentViewController *commentViewController = [[CommentViewController alloc] init];
        commentViewController.comment = comment;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.panelNavigationController pushViewController:commentViewController fromViewController:self animated:YES];
    } else {
        [self.panelNavigationController popToViewController:self animated:NO];
    }
}

- (void)setWantedCommentId:(NSNumber *)wantedCommentId {
    if (![wantedCommentId isEqual:_wantedCommentId]) {
        [_wantedCommentId release]; _wantedCommentId = nil;
        if (wantedCommentId) {
            // First check if we already have the comment
            Comment *comment = [self commentWithId:wantedCommentId];
            if (comment) {
                NSIndexPath *wantedIndexPath = [self.resultsController indexPathForObject:comment];
                [self.tableView scrollToRowAtIndexPath:wantedIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
                [self showCommentAtIndexPath:wantedIndexPath];
            } else {
                [self willChangeValueForKey:@"wantedCommentId"];
                _wantedCommentId = [wantedCommentId retain];
                [self didChangeValueForKey:@"wantedCommentId"];
                [self syncItemsWithUserInteraction:NO];
            }
        }
    }
}

- (IBAction)replyToSelectedComment:(id)sender {
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
  Comment *selectedComment = [_selectedComments objectAtIndex:0];
  
  ReplyToCommentViewController *replyToCommentViewController = [[[ReplyToCommentViewController alloc] 
                                        initWithNibName:@"ReplyToCommentViewController" 
                                        bundle:nil] autorelease];
  
  replyToCommentViewController.delegate = self;
  replyToCommentViewController.comment = [[selectedComment newReply] autorelease];
  replyToCommentViewController.title = NSLocalizedString(@"Comment Reply", @"Comment Reply view title");
	
	if (DeviceIsPad() == NO) {
		[delegate.navigationController pushViewController:replyToCommentViewController animated:YES];
	} else {
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:replyToCommentViewController] autorelease];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		[self presentModalViewController:navController animated:YES];
	}  
}

- (Comment *)commentWithId:(NSNumber *)commentId {
    Comment *comment = [[[self.resultsController fetchedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentId]] lastObject];
    
    return comment;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [Comment titleForStatus:[sectionInfo name]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return COMMENT_ROW_HEIGHT;
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
    NSIndexPath *currentIndexPath = self.tableView.indexPathForSelectedRow;
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
    NSIndexPath *currentIndexPath = self.tableView.indexPathForSelectedRow;
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
    static NSString *cellIdentifier = @"CommentCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier] retain];
    if (cell == nil) {
        cell = [[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    [self.blog syncCommentsWithSuccess:success failure:failure];
}

@end
