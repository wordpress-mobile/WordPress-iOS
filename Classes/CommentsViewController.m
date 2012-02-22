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
#import "WPProgressHUD.h"
#import "Reachability.h"
#import "CommentViewController.h"
#import "BlogViewController.h"
#import "ReplyToCommentViewController.h"

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
- (void)updateBadge;
- (void)reloadTableView;
- (void)limitToOnHold;
- (void)doNotLimit;
- (NSMutableArray *)commentsOnHold;
- (NSDate *)lastSyncDate;
- (BOOL)isSyncing;
- (void) setupGestureRecognizers;
- (void) setupModerationSwipeView;
- (void) removeModerationSwipeView:(BOOL)animated;
@end

@implementation CommentsViewController

@synthesize editButtonItem, selectedComments, commentsArray, indexForCurrentPost, lastUserSelectedCommentID;
@synthesize selectedIndexPath;
@synthesize commentViewController;
@synthesize isSecondaryViewController;
@synthesize blog;
@synthesize resultsController;
@synthesize moderationSwipeView, moderationSwipeCell, moderationSwipeDirection;

#pragma mark -
#pragma mark Memory Management

- (void)viewDidUnload
{
  [super viewDidUnload];
  
  self.moderationSwipeView = nil;
}

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.resultsController.delegate = nil;
	self.resultsController = nil;
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
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

- (CGSize)contentSizeForViewInPopover;
{
	float height = MIN([commentsArray count] * COMMENT_ROW_HEIGHT + REFRESH_BUTTON_HEIGHT + kSectionHeaderHight, 600);
	return CGSizeMake(320.0, height);
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

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    spamButton.title = NSLocalizedString(@"Spam", @"");
    unapproveButton.title = NSLocalizedString(@"Unapprove", @"");
    approveButton.title = NSLocalizedString(@"Approve", @"");
    
    commentsDict = [[NSMutableDictionary alloc] init];
    selectedComments = [[NSMutableArray alloc] init];
    
    [commentsTableView setDataSource:self];
    commentsTableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    commentsTableView.allowsSelectionDuringEditing = YES;
    
    editButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStyleBordered
                                                     target:self action:@selector(editComments)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentsSynced:) name:@"CommentRefreshNotification" object:nil];
	
    if (_refreshHeaderView == nil) {
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - commentsTableView.bounds.size.height, self.view.frame.size.width, commentsTableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[commentsTableView addSubview:_refreshHeaderView];
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
	
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
	
	[self refreshCommentsList];
    	
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
		CGPoint offset = commentsTableView.contentOffset;
		offset.y = - 65.0f;
		commentsTableView.contentOffset = offset;
		[commentsTableView setContentOffset:offset];
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:commentsTableView];
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

#pragma mark -

- (void) cancelView {
	[self.navigationController popViewControllerAnimated:YES];
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
	
    editButtonItem.title = editing ? NSLocalizedString(@"Cancel", @"") : NSLocalizedString(@"Edit", @"");
    
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
    [self refreshCommentsList];
}

- (void)editComments {
  [self removeModerationSwipeView:NO];
  
	if ([UIApplication sharedApplication].networkActivityIndicatorVisible) {
		UIAlertView *currentlyUpdatingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Currently Syncing", @"") message:NSLocalizedString(@"The edit feature is disabled while syncing. Please try again in a few seconds.", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
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
	[self setEditing:false];
	[self syncComments];
}

- (void)syncComments {
    [self.blog syncCommentsWithSuccess:^() {
        [self refreshCommentsList];
    } failure:^(NSError *error) {
        [self refreshCommentsList];
        NSDictionary *errInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.blog, @"currentBlog", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kXML_RPC_ERROR_OCCURS object:error userInfo:errInfo];
    }];
}

- (void)refreshCommentsList {
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:commentsTableView];
    if (!selectedComments) {
        selectedComments = [[NSMutableArray alloc] init];
    } /* else {
        [selectedComments removeAllObjects];
    }*/
	
    [editButtonItem setEnabled:([[self.resultsController fetchedObjects] count] > 0)];	
	[self reloadTableView];
	
	if (DeviceIsPad() == YES) {
		
		//we must check if the user has changed blog meanwhile
		BOOL presence = NO;
		WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
		
		UINavigationController *master = [delegate masterNavigationController];
		UIViewController *topVC = master.topViewController;
		if (topVC && [topVC isKindOfClass:[BlogViewController class]]) {
			BlogViewController *tmp = (BlogViewController *)topVC;
			if( tmp.tabBarController.selectedViewController == self)
				presence = YES;
		}
		
		/*	Another way to do that
		 UINavigationController *master = [delegate masterNavigationController];
		 // O : BlogsViewController
		 //1 : BlogViewController
		 if(master && ([master.viewControllers count] > 1) ) {
		 UIViewController *ctrlRight = [master.viewControllers objectAtIndex:1];
		 if([ctrlRight isKindOfClass:[BlogViewController class]]) {
		 BlogViewController *tmp = (BlogViewController*)ctrlRight;
		 if(tmp.tabBarController.selectedViewController == self)
		 presence = YES;
		 }
		 }
		 */
		if(presence)
			if (self.selectedIndexPath && !self.isSecondaryViewController) {
				[commentsTableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
				[self showCommentAtIndexPath:self.selectedIndexPath];
			}
	}
}

- (IBAction)deleteSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];

    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Deleting...", @"")];
    [progressAlert show];

    [self performSelectorInBackground:@selector(deleteComments) withObject:nil];
}

- (IBAction)approveSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];

    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Moderating...", @"")];
    [progressAlert show];

    [self performSelectorInBackground:@selector(approveComments) withObject:nil];
}

- (IBAction)unapproveSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];

    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Moderating...", @"")];
    [progressAlert show];

    [self performSelectorInBackground:@selector(unapproveComments) withObject:nil];
}

- (IBAction)spamSelectedComments:(id)sender {
    [self removeModerationSwipeView:NO];

    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Moderating...", @"")];
    [progressAlert show];

    [self performSelectorInBackground:@selector(markCommentsAsSpam) withObject:nil];
}

- (void)didModerateComments {
    [self setEditing:NO];
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [FileLogger log:@"%@ %@%@", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector)];
	BOOL fails = NO;
    for (Comment *comment in selectedComments) {
        if(![comment performSelector:selector])
			fails = YES;
    }
    [self performSelectorOnMainThread:@selector(didModerateComments) withObject:nil waitUntilDone:NO];
    
	if(fails)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:NSLocalizedString(@"Sorry, something went wrong during comment moderation. Please try again.", @"")];
	[pool release];
}

- (void)deleteComments {
    [self moderateCommentsWithSelector:@selector(remove)];
	[self performSelectorOnMainThread:@selector(trySelectSomethingAndShowIt) withObject:nil waitUntilDone:NO];
}

- (void)approveComments {
    [self moderateCommentsWithSelector:@selector(approve)];
}

- (void)markCommentsAsSpam {
    [self moderateCommentsWithSelector:@selector(spam)];
	[self performSelectorOnMainThread:@selector(trySelectSomethingAndShowIt) withObject:nil waitUntilDone:NO];
}

- (void)unapproveComments {
    [self moderateCommentsWithSelector:@selector(unapprove)];
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
		//push an the WP logo on the right. 
		WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
		[delegate showContentDetailViewController:nil];		
        return;
    }
	
	if (self.isSecondaryViewController) {
		[self.navigationController pushViewController:self.commentViewController animated:YES];
	} else {
		if (!self.commentViewController.isVisible) {
			WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
			[delegate showContentDetailViewController:self.commentViewController];
		}
	}
	
	if(comment != nil)
		[self.commentViewController showComment:comment];
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

- (IBAction)replyToSelectedComment:(id)sender {
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
  Comment *selectedComment = [selectedComments objectAtIndex:0];
  
  ReplyToCommentViewController *replyToCommentViewController = [[[ReplyToCommentViewController alloc] 
                                        initWithNibName:@"ReplyToCommentViewController" 
                                        bundle:nil] autorelease];
  
  replyToCommentViewController.commentViewController = nil;
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
    [commentsTableView reloadData];
}

#pragma mark -
#pragma mark Comments Scoping

- (void)limitToOnHold {
}

- (void)doNotLimit {
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSDictionary *dict = [selectedComments objectAtIndex:indexPath.row];
	Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
	if ([comment.status isEqualToString:@"hold"]) {
		cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
	} else {
		cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
	}

	if (DeviceIsPad() == YES && !self.isSecondaryViewController) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [Comment titleForStatus:[sectionInfo name]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CommentCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];

    if (cell == nil) {
        cell = [[[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
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

- (void) setupModerationSwipeView
{
  for (UIView* subview in moderationSwipeView.subviews)
  {
    if ([subview isKindOfClass:[UIButton class]])
    {
        UIImage* buttonImage = [[UIImage imageNamed:@"UISegmentBarBlackButton.png"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
        UIImage* buttonPressedImage = [[UIImage imageNamed:@"UISegmentBarBlackButtonHighlighted.png"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];

        UIButton* button = (UIButton*)subview;
        [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    }
  }

  self.moderationSwipeView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"dotted-pattern.png"]];

  UIImage* shadow = [[UIImage imageNamed:@"inner-shadow.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
  UIImageView* shadowImageView = [[[UIImageView alloc] initWithFrame:moderationSwipeView.frame] autorelease];
  shadowImageView.alpha = 0.6;
  shadowImageView.image = shadow;

  [self.moderationSwipeView insertSubview:shadowImageView atIndex:0];  
}

#pragma mark Gesture recognizers

- (void) setupGestureRecognizers
{
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
      UIButton *moderationApproveButton = (UIButton*)[moderationSwipeView viewWithTag:3];
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
      [UIView setAnimationDuration:0.4];
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

- (void) removeModerationSwipeView:(BOOL)animated
{
  if (!moderationSwipeCell || (moderationSwipeCell.frame.origin.x == 0 && moderationSwipeView.superview == nil)) return;
  
  if (animated)
  {
    animatingRemovalOfModerationSwipeView = YES;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.4];
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
  [UIView setAnimationDuration:0.2];
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
  [UIView setAnimationDuration:0.2];
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
	if(self.blog.isSyncingComments) {
		//the blog is using the network connection and cannot be stoped, show a message to the user
		UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
																	  message:NSLocalizedString(@"The blog is syncing with the server. Please try later.", @"")
																	 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
		[blogIsCurrentlyBusy show];
		[blogIsCurrentlyBusy release];
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		return;
	}
	
	
    if (editing) {
        [self tableView:tableView didCheckRowAtIndexPath:indexPath];
    } else {
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
#pragma mark Notifications

- (void)commentsSynced:(NSNotification *)notification {
	[self refreshCommentsList];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"Shake detected. Refreshing...");
	if(event.subtype == UIEventSubtypeMotionShake)
		[self refreshCommentsList];
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
    }
}


- (void)trySelectSomething {
	
	//try to move the comments list on the last user selected comment
	if(self.lastUserSelectedCommentID != nil) {
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
				if([cmt.commentID  compare:self.lastUserSelectedCommentID] == NSOrderedSame) { 
					self.selectedIndexPath = [NSIndexPath indexPathForRow:currentCommentIndex inSection:currentSectionIndex];
					[commentsTableView scrollToRowAtIndexPath:self.selectedIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
				}
			}
		}
	}	
	
	if (!DeviceIsPad())
        return;

	//On ipad we should show the comments on the right side and we should highlight the comments within the comments list	
	
    if (!self.selectedIndexPath) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        @try {
            if ([resultsController fetchedObjects] &&
                ([[resultsController fetchedObjects] count] > 0) &&
                [resultsController objectAtIndexPath:indexPath]) {
                self.selectedIndexPath = indexPath;
            }
        }
        @catch (NSException * e) {
            NSLog(@"Caught exception when looking for a post to select. Maybe there are no posts yet?");
			self.selectedComments = nil;
        }
	}

	if (!self.selectedIndexPath) {
		//nothing is selected, push an the WP logo on the right.
		WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
		[delegate showContentDetailViewController:nil];
	} else {
		[commentsTableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	
}
	
//this is used after a comment delete
- (void)trySelectSomethingAndShowIt{
	if (!DeviceIsPad())
        return;
	
	if (!self.selectedIndexPath) {
		[self trySelectSomething];
	}
	// sometimes, iPad table views should
	if (self.selectedIndexPath && !self.isSecondaryViewController) {
		[commentsTableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self showCommentAtIndexPath:self.selectedIndexPath];
	}
}



#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Comment";
}

- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
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
    resultsController.delegate = self;
    
    [aResultsController release];
    [fetchRequest release];
    [sortDescriptorStatus release]; sortDescriptorStatus = nil;
    [sortDescriptorDate release]; sortDescriptorDate = nil;
    [sortDescriptors release]; sortDescriptors = nil;
    
    NSError *error = nil;
    if (![resultsController performFetch:&error]) {
        NSLog(@"Couldn't fetch comments");
        resultsController = nil;
    }
    NSLog(@"fetched comments: %@", [resultsController fetchedObjects]);
    
    return resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    //    [commentsTableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    //    [commentsTableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    [commentsTableView reloadData];
    
    if (!DeviceIsPad()) {
        return;
    }
    switch (type) {
        case NSFetchedResultsChangeDelete:
            [self trySelectSomething];
			break;
        case NSFetchedResultsChangeInsert:
            self.selectedIndexPath = newIndexPath;
            [commentsTableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		case NSFetchedResultsChangeMove:
            self.selectedIndexPath = newIndexPath;
            [commentsTableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		default:
            [commentsTableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            break;
    }
}

- (BOOL)isSyncing {
	return self.blog.isSyncingComments;
}

-(NSDate *) lastSyncDate {
	return self.blog.lastCommentsSync;
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

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[self refreshHandler];
	_refreshHeaderView.hidden = NO; // Just in case
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return [self isSyncing]; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [self lastSyncDate]; // should return date data source was last changed
}

@end
