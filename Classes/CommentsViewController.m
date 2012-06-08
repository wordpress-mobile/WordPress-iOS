
//
//  CommentsViewController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

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
- (void)updateBadge;
- (void)reloadTableView;
- (void)limitToOnHold;
- (void)doNotLimit;
- (NSMutableArray *)commentsOnHold;
- (void) setupGestureRecognizers;
- (void) setupModerationSwipeView;
- (void) removeModerationSwipeView:(BOOL)animated;
@end

@implementation CommentsViewController

@synthesize editButtonItem, commentsArray, indexForCurrentPost, lastUserSelectedCommentID;
@synthesize selectedIndexPath;
@synthesize commentViewController;
@synthesize blog = _blog;
@synthesize resultsController = _resultsController;
@synthesize moderationSwipeCell, moderationSwipeDirection;
@synthesize moderationApproveButton, moderationSpamButton, moderationReplyButton;
@synthesize dateOfPreviouslyOldestComment;
@synthesize wantedCommentId = _wantedCommentId;

#pragma mark -
#pragma mark Memory Management

- (void)viewDidUnload {
    [super viewDidUnload];

    self.moderationSwipeView = nil;
    self.moderationApproveButton = nil;
    self.moderationSpamButton = nil;
    self.moderationReplyButton = nil;
}

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.resultsController.delegate = nil;
	self.resultsController = nil;
	self.dateOfPreviouslyOldestComment = nil;
    [commentsArray release];
    [commentsDict release];
    [selectedComments release];
    [editButtonItem release];
	[selectedIndexPath release], selectedIndexPath = nil;
	[lastUserSelectedCommentID release], lastUserSelectedCommentID = nil;
	[commentViewController release], commentViewController = nil;
	[_refreshHeaderView release]; _refreshHeaderView = nil;
    [moderationSwipeView release];
    [moderationSwipeCell release];
	[newCommentIndexPaths release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

- (CommentViewController *)commentViewController;
{
	if (!commentViewController) {
		commentViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:nil];
		commentViewController.commentsViewController = self;
		
		[commentViewController view]; // DWC kindakludge - make sure it's got a view
	}
	return commentViewController;
}

#pragma mark -
#pragma mark View Lifecycle Methods

- (void)awakeFromNib {
	newCommentIndexPaths = [[NSMutableArray array] retain];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Comments", @"");
    spamButton.title = NSLocalizedString(@"Spam", @"");
    unapproveButton.title = NSLocalizedString(@"Unapprove", @"");
    approveButton.title = NSLocalizedString(@"Approve", @"");
    [moderationApproveButton setTitle:NSLocalizedString(@"Approve", @"") forState:UIControlStateNormal];
    [moderationSpamButton setTitle:NSLocalizedString(@"Spam", @"") forState:UIControlStateNormal];
    [moderationReplyButton setTitle:NSLocalizedString(@"Reply", @"") forState:UIControlStateNormal];
        
    commentsDict = [[NSMutableDictionary alloc] init];
    selectedComments = [[NSMutableArray alloc] init];
    
    [commentsTableView setDataSource:self];
    commentsTableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    commentsTableView.allowsSelectionDuringEditing = YES;
    
    commentsTableView.isAccessibilityElement = YES;
    commentsTableView.accessibilityLabel = @"Comments";       // required for UIAutomation for iOS 4
	if([commentsTableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		commentsTableView.accessibilityIdentifier = @"Comments";  // required for UIAutomation for iOS 5
	}

    
    editButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStyleBordered
                                                     target:self action:@selector(editComments)];
	
    selectedComments = [[NSMutableArray alloc] init];

    [self setupModerationSwipeView];
    [self setupGestureRecognizers];
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewWillAppear:animated];
    [self setEditing:NO];
    //selectedIndexPath = nil;    
    [editToolbar setHidden:YES];
    self.navigationItem.rightBarButtonItem = editButtonItem;

	@try {
		if(self.blog.lastCommentsSync != nil)  //first startup, comments are not there
			if ([commentsTableView indexPathForSelectedRow]) {
				[commentsTableView scrollToRowAtIndexPath:[commentsTableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];

				if (DeviceIsPad() == NO) // iPhone table views should not appear selected
					[commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:animated];
			}
		
	}
	@catch (NSException * e) {
		self.selectedIndexPath = nil;
		NSLog(@"Can't select comment during viewWillAppear");
		NSLog(@"sections: %@", self.resultsController.sections);
		NSLog(@"results: %@", self.resultsController.fetchedObjects);
		return;
	}
	

	//in same cases the lastSyncDate could be nil. Start a sync, so the user never get an ampty screen.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![self isSyncing] && ([self lastSyncDate] == nil || [defaults boolForKey:@"refreshCommentsRequired"])) {
        [self triggerRefresh];
		[defaults setBool:false forKey:@"refreshCommentsRequired"];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (!DeviceIsPad())
		editButtonItem.title = NSLocalizedString(@"Edit", @"");
    [super viewWillDisappear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if (DeviceIsPad() == NO) {
		[commentsTableView reloadData];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}
	return NO;
}

- (void)setBlog:(Blog *)blog {
    if (_blog == blog) 
        return;
    [_blog release];
    _blog = [blog retain];
    self.resultsController = nil;
    NSError *error = nil;
    [self.resultsController performFetch:&error];
    [self.tableView reloadData];
    if ([self.resultsController.fetchedObjects count] == 0) {
        if (![self isSyncing]) {
            CGPoint offset = commentsTableView.contentOffset;
            offset.y = - 65.0f;
            commentsTableView.contentOffset = offset;
            [_refreshHeaderView egoRefreshScrollViewDidEndDragging:commentsTableView];
        }
    }
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
	
    if (editing) {
        editButtonItem.title = NSLocalizedString(@"Done", @"");
        editButtonItem.style = UIBarButtonItemStyleDone;
    } else {
        editButtonItem.title = NSLocalizedString(@"Edit", @"");
        editButtonItem.style = UIBarButtonItemStyleBordered;
    }
    
    [commentsTableView setEditing:value animated:YES];
	
	if(editing && selectedComments) { //if we are switching to editing mode and there were selected comments
		if(selectedComments.count > 0) { 
			if ([[self.resultsController fetchedObjects] count] > 0) {
				
				NSMutableArray *commentsToKeep = [NSMutableArray array] ;
				for (Comment  *commentInfo in [self.resultsController fetchedObjects]) {
					if ([selectedComments containsObject:commentInfo]) {
						[commentsToKeep addObject:commentInfo];
					} 					
				}

				self.selectedComments = nil;
				self.selectedComments = commentsToKeep;
				
			} else {
				[selectedComments removeAllObjects];
			}
		}
		[self updateSelectedComments];
	}
	
	_refreshHeaderView.hidden = value;
}

- (void)editComments {
    [self removeModerationSwipeView:NO];
    [self setEditing:!editing];
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)deleteSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];
    [self moderateCommentsWithSelector:@selector(remove)];
}

- (IBAction)approveSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];
    [self moderateCommentsWithSelector:@selector(approve)];
}

- (IBAction)unapproveSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];
    [self moderateCommentsWithSelector:@selector(unapprove)];
}

- (IBAction)spamSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];
    [self moderateCommentsWithSelector:@selector(spam)];
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    [FileLogger log:@"%@ %@%@", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector)];
    [selectedComments makeObjectsPerformSelector:selector];
    if (editing) {
        for (Comment *comment in selectedComments) {
            NSIndexPath *indexPath = [self.resultsController indexPathForObject:comment];
            if (indexPath) {
                CommentTableViewCell *cell = (CommentTableViewCell *)[commentsTableView cellForRowAtIndexPath:indexPath];
                if (cell) {
                    cell.checked = NO;
                }
            }
        }
    }
    [selectedComments removeAllObjects];
    [self updateSelectedComments];
}

- (void)updateSelectedComments {
    int i, approvedCount, unapprovedCount, spamCount, count = [selectedComments count];

    approvedCount = unapprovedCount = spamCount = 0;

    for (i = 0; i < count; i++) {
        Comment *comment = [selectedComments objectAtIndex:i];

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
    @try {
		if(self.blog.lastCommentsSync == nil) { //first startup, comments are not there
			comment = nil;
		} else {
			comment = [self.resultsController objectAtIndexPath:indexPath];
			WPLog(@"Selected comment at indexPath: (%i,%i)", indexPath.section, indexPath.row);
		}
    }
    @catch (NSException * e) {
        NSLog(@"Can't select comment at indexPath: (%i,%i)", indexPath.section, indexPath.row);
        NSLog(@"sections: %@", self.resultsController.sections);
        NSLog(@"results: %@", self.resultsController.fetchedObjects);
        comment = nil;
    }
    
	if(comment != nil) {        
		[self.commentViewController showComment:comment];
        [self.panelNavigationController pushViewController:self.commentViewController fromViewController:self animated:YES];
    } else {
        [self.panelNavigationController popToViewController:self animated:NO];
    }
}

- (void)setSelectedIndexPath:(NSIndexPath *)indexPath {
    if (selectedIndexPath != indexPath) {
        [selectedIndexPath release];
        selectedIndexPath = indexPath;
        if (selectedIndexPath != nil) {
            [selectedIndexPath retain];
            [self showCommentAtIndexPath:selectedIndexPath];
        }
    } else {
		if (selectedIndexPath != nil) 
			[self showCommentAtIndexPath:selectedIndexPath];
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
                self.selectedIndexPath = wantedIndexPath;
                [commentsTableView scrollToRowAtIndexPath:wantedIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
            } else {
                [self willChangeValueForKey:@"wantedCommentId"];
                _wantedCommentId = [wantedCommentId retain];
                [self didChangeValueForKey:@"wantedCommentId"];
                [self triggerRefresh];
            }
        }
    }
}

- (IBAction)replyToSelectedComment:(id)sender {
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
  Comment *selectedComment = [selectedComments objectAtIndex:0];
  
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
  
  [self removeModerationSwipeView:YES];
}

#pragma mark -
#pragma mark Segmented View Controls

- (void)reloadTableView {
	[self updateBadge];
	willReloadTable = NO;
    [commentsTableView reloadData];
	if (DeviceIsPad()) {
		[commentsTableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}

#pragma mark -
#pragma mark Comments Scoping

- (void)limitToOnHold {
}

- (void)doNotLimit {
}

#pragma mark Gesture recognizers

- (void) setupGestureRecognizers
{
    if (DeviceIsPad()) return;

  UISwipeGestureRecognizer* rightSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)] autorelease];
  rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
  
  // Apple's docs: Although this class was publicly available starting with iOS 3.2, it was in development a short period prior to that
  // check if it responds to the selector locationInView:. This method was not added to the class until iOS 3.2.
  if (![rightSwipeGestureRecognizer respondsToSelector:@selector(locationInView:)]) 
    return;
  
  [commentsTableView addGestureRecognizer:rightSwipeGestureRecognizer];

  UISwipeGestureRecognizer* leftSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)] autorelease];
  leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
  [commentsTableView addGestureRecognizer:leftSwipeGestureRecognizer];
}

- (void)swipe:(UISwipeGestureRecognizer *)recognizer direction:(UISwipeGestureRecognizerDirection)direction
{
  if (recognizer && recognizer.state == UIGestureRecognizerStateEnded)
  {
    if (animatingRemovalOfModerationSwipeView) return;
    
    CGPoint location = [recognizer locationInView:commentsTableView];
    NSIndexPath* indexPath = [commentsTableView indexPathForRowAtPoint:location];
    CommentTableViewCell* cell = (CommentTableViewCell *)[commentsTableView cellForRowAtIndexPath:indexPath];
  
    if (cell.frame.origin.x != 0)
    {
      [self removeModerationSwipeView:YES];
      return;
    }
    [self removeModerationSwipeView:NO];
  
    if (cell!= moderationSwipeCell)
    {
      [moderationApproveButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
      
      if ([cell.comment.status isEqualToString:@"hold"]) {
        // not approved
        [moderationApproveButton setTitle:NSLocalizedString(@"Approve", @"") forState:UIControlStateNormal];
        [moderationApproveButton addTarget:self action:@selector(approveSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
      } else  {
        // approved
        [moderationApproveButton setTitle:NSLocalizedString(@"Unapprove", @"") forState:UIControlStateNormal];
        [moderationApproveButton addTarget:self action:@selector(unapproveSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
      }
      
      [commentsTableView addSubview:moderationSwipeView];
      self.moderationSwipeCell = cell;
      
      [selectedComments removeAllObjects];
      [selectedComments addObject:cell.comment];
      
      CGRect cellFrame = cell.frame;
      moderationSwipeDirection = direction;
      moderationSwipeView.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? -cellFrame.size.width : cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);

      [UIView beginAnimations:nil context:nil];
      [UIView setAnimationDuration:0.2];
      moderationSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
      cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? cellFrame.size.width : -cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
      [UIView commitAnimations];
    }
  }
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer
{
  [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer
{
  [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionRight];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  [self removeModerationSwipeView:YES];
}

- (void)removeModerationSwipeView:(BOOL)animated
{
  if (!moderationSwipeCell || (moderationSwipeCell.frame.origin.x == 0 && moderationSwipeView.superview == nil)) return;
  
  if (animated)
  {
    animatingRemovalOfModerationSwipeView = YES;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (moderationSwipeDirection == UISwipeGestureRecognizerDirectionRight)
    {
      moderationSwipeView.frame = CGRectMake(-moderationSwipeView.frame.size.width + 5.0,moderationSwipeView.frame.origin.y,moderationSwipeView.frame.size.width, moderationSwipeView.frame.size.height);
      moderationSwipeCell.frame = CGRectMake(5.0, moderationSwipeCell.frame.origin.y, moderationSwipeCell.frame.size.width, moderationSwipeCell.frame.size.height);
    }
    else
    {
      moderationSwipeView.frame = CGRectMake(moderationSwipeView.frame.size.width - 5.0,moderationSwipeView.frame.origin.y,moderationSwipeView.frame.size.width, moderationSwipeView.frame.size.height);
      moderationSwipeCell.frame = CGRectMake(-5.0, moderationSwipeCell.frame.origin.y, moderationSwipeCell.frame.size.width, moderationSwipeCell.frame.size.height);
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopOne:finished:context:)];
    [UIView commitAnimations];
  }
  else
  {
    [moderationSwipeView removeFromSuperview];
    moderationSwipeCell.frame = CGRectMake(0,moderationSwipeCell.frame.origin.y,moderationSwipeCell.frame.size.width, moderationSwipeCell.frame.size.height);
    self.moderationSwipeCell = nil;
  }
}

- (NSIndexPath *)tableView:(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self removeModerationSwipeView:YES];
  return indexPath;
}

- (void)animationDidStopOne:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.1];
  if (moderationSwipeDirection == UISwipeGestureRecognizerDirectionRight)
  {
    moderationSwipeView.frame = CGRectMake(-moderationSwipeView.frame.size.width + 10.0,moderationSwipeView.frame.origin.y,moderationSwipeView.frame.size.width, moderationSwipeView.frame.size.height);
    moderationSwipeCell.frame = CGRectMake(10.0, moderationSwipeCell.frame.origin.y, moderationSwipeCell.frame.size.width, moderationSwipeCell.frame.size.height);
  }
  else
  {
    moderationSwipeView.frame = CGRectMake(moderationSwipeView.frame.size.width - 10.0,moderationSwipeView.frame.origin.y,moderationSwipeView.frame.size.width, moderationSwipeView.frame.size.height);
    moderationSwipeCell.frame = CGRectMake(-10.0, moderationSwipeCell.frame.origin.y, moderationSwipeCell.frame.size.width, moderationSwipeCell.frame.size.height);
  }
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animationDidStopTwo:finished:context:)];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];
  [UIView commitAnimations];
}

- (void)animationDidStopTwo:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
  [UIView commitAnimations];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.1];
  if (moderationSwipeDirection == UISwipeGestureRecognizerDirectionRight)
  {
    moderationSwipeView.frame = CGRectMake(-moderationSwipeView.frame.size.width ,moderationSwipeView.frame.origin.y,moderationSwipeView.frame.size.width, moderationSwipeView.frame.size.height);
    moderationSwipeCell.frame = CGRectMake(0, moderationSwipeCell.frame.origin.y, moderationSwipeCell.frame.size.width, moderationSwipeCell.frame.size.height);
  }
  else
  {
    moderationSwipeView.frame = CGRectMake(moderationSwipeView.frame.size.width ,moderationSwipeView.frame.origin.y,moderationSwipeView.frame.size.width, moderationSwipeView.frame.size.height);
    moderationSwipeCell.frame = CGRectMake(0, moderationSwipeCell.frame.origin.y, moderationSwipeCell.frame.size.width, moderationSwipeCell.frame.size.height);
  }
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animationDidStopThree:finished:context:)];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];
  [UIView commitAnimations];
}

- (void)animationDidStopThree:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
  animatingRemovalOfModerationSwipeView = NO;
  self.moderationSwipeCell = nil;
  [moderationSwipeView removeFromSuperview];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editing) {
        [self tableView:tableView didCheckRowAtIndexPath:indexPath];
    } else {
        if (DeviceIsPad() && self.selectedIndexPath && [self.selectedIndexPath isEqual:[tableView indexPathForSelectedRow]]) {
            return;
        }
        // Disabled while debugging panels
        // It should go away eventually and handle if the comment displayed changes when syncing
        if(self.blog.isSyncingComments && NO) {
            //the blog is using the network connection and cannot be stoped, show a message to the user
            UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
                                                                          message:NSLocalizedString(@"The blog is syncing with the server. Please try later.", @"")
                                                                         delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [blogIsCurrentlyBusy show];
            [blogIsCurrentlyBusy release];
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
        
        
        self.selectedIndexPath = indexPath;
        
        // we should keep the reference to the last comment selected by the user
        Comment *comment;
        @try {
            if(self.blog.lastCommentsSync == nil) { //first startup, comments are not there
                comment = nil;
            } else {
                comment = [self.resultsController objectAtIndexPath:indexPath];
            }
        }
        @catch (NSException * e) {
            comment = nil;
        }
        self.lastUserSelectedCommentID = nil;
        if(comment != nil) {
            self.lastUserSelectedCommentID = comment.commentID; //store the latest user selection
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!editing) {
        self.selectedIndexPath = nil;
    }
}

- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath {
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    Comment *comment = cell.comment;
	
	//danroundhill - added nil check based on crash reports
	if (comment != nil){
	
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
}

#pragma mark -
#pragma mark Update Badge

- (void)updateBadge {
    return;
    NSString *badge = nil;
	
	if (indexForCurrentPost < -1) {
		
		NSMutableArray *commentsOnHold = [self commentsOnHold];
		
		if ([commentsOnHold count] > 0) {
			badge = [[NSNumber numberWithInt:[commentsOnHold count]] stringValue];
		}
	}
    self.tabBarItem.badgeValue = badge;
}

#pragma mark -
#pragma mark Comment navigation

- (BOOL)hasPreviousComment {
    if (selectedIndexPath == nil) return NO;
    return (selectedIndexPath.section > 0 || selectedIndexPath.row > 0);
}

- (BOOL)hasNextComment {
    if (selectedIndexPath == nil) return NO;
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:selectedIndexPath.section];
    return (selectedIndexPath.section + 1 < [[self.resultsController sections] count]
            || selectedIndexPath.row + 1 < sectionInfo.numberOfObjects);
}
- (void)showPreviousComment {
    if (selectedIndexPath == nil) return;
    NSIndexPath *indexPath = nil;
    if (self.selectedIndexPath.row == 0 && self.selectedIndexPath.section > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:selectedIndexPath.section - 1];
        indexPath = [NSIndexPath indexPathForRow:sectionInfo.numberOfObjects - 1 inSection:selectedIndexPath.section - 1];
    } else if (self.selectedIndexPath.row > 0) {
        indexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:selectedIndexPath.section];        
    }

    if (indexPath) {
        self.selectedIndexPath = indexPath;
        [commentsTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
	}
}

- (void)showNextComment {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:selectedIndexPath.section];
    NSIndexPath *indexPath = nil;
    if ((selectedIndexPath.row + 1) >= sectionInfo.numberOfObjects) {
        // Was last row in section
        if ((selectedIndexPath.section + 1) < [[self.resultsController sections] count]) {
            // There are more sections
            indexPath = [NSIndexPath indexPathForRow:0 inSection:selectedIndexPath.section + 1];
        }
    } else {
        indexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row + 1 inSection:selectedIndexPath.section];
    }

    if (indexPath) {
        self.selectedIndexPath = indexPath;
        [commentsTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Comment";
}

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) {
        return _resultsController;
    }
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:appDelegate.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(blog == %@ AND status != %@)", self.blog, @"spam"]];
    NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorStatus, sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aResultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:appDelegate.managedObjectContext
                                                      sectionNameKeyPath:@"status"
                                                      cacheName:[NSString stringWithFormat:@"%@-%@", [self entityName], [self.blog objectID]]];
    self.resultsController = aResultsController;
    _resultsController.delegate = self;
    
    [aResultsController release];
    [fetchRequest release];
    [sortDescriptorStatus release]; sortDescriptorStatus = nil;
    [sortDescriptorDate release]; sortDescriptorDate = nil;
    [sortDescriptors release]; sortDescriptors = nil;
    
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        NSLog(@"Couldn't fetch comments");
        _resultsController = nil;
    }
    
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [commentsTableView beginUpdates];
    [selectionWanted release]; selectionWanted = nil;
}

- (void)setReplying:(BOOL)value {
	replying = value;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [commentsTableView endUpdates];

    if (!editing && !replying) {
        if (selectionWanted) {
            if (![selectionWanted isEqual:[commentsTableView indexPathForSelectedRow]]) {
                self.selectedIndexPath = selectionWanted;
                [commentsTableView selectRowAtIndexPath:selectionWanted animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }

    [selectionWanted release]; selectionWanted = nil;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {

        case NSFetchedResultsChangeInsert:
            [commentsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            Comment *comment = (Comment *)anObject;
            comment.isNew = YES;
            if ((DeviceIsPad() && selectionWanted == nil) || (self.wantedCommentId && [self.wantedCommentId isEqual:comment.commentID])) {
                selectionWanted = [newIndexPath retain];
            }
            break;

        case NSFetchedResultsChangeDelete:
            [commentsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:((CommentTableViewCell *)[commentsTableView cellForRowAtIndexPath:indexPath]) atIndexPath:newIndexPath];
            
            if (DeviceIsPad() && selectionWanted == nil && [self.selectedIndexPath isEqual:indexPath]) {
                selectionWanted = [newIndexPath retain];
            }
            break;

        case NSFetchedResultsChangeMove:
            [commentsTableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [commentsTableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            if (DeviceIsPad() && selectionWanted == nil && [self.selectedIndexPath isEqual:indexPath]) {
                selectionWanted = [newIndexPath retain];
            }
            break;
    }    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [commentsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [commentsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	if (!editing)
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

@end
