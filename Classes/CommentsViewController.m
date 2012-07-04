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
#import "ReplyToCommentViewController.h"
#import "UIColor+Helpers.h"

@interface CommentsViewController () <CommentViewControllerDelegate>
@property (nonatomic,retain) CommentViewController *commentViewController;
@property (nonatomic,retain) NSIndexPath *currentIndexPath;
- (void)updateSelectedComments;
- (void)deselectAllComments;
- (void)moderateCommentsWithSelector:(SEL)selector;
- (Comment *)commentWithId:(NSNumber *)commentId;
@end

@implementation CommentsViewController {
    NSMutableArray *_selectedComments;
}

@synthesize wantedCommentId = _wantedCommentId;
@synthesize commentViewController = _commentViewController;
@synthesize currentIndexPath = _currentIndexPath;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.commentViewController.delegate = nil;
    self.commentViewController = nil;
    self.currentIndexPath = nil;
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
    self.swipeActionsEnabled = YES;
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Comments", @"");
    
    
    spamButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_flag"] style:UIBarButtonItemStylePlain target:self action:@selector(spamSelectedComments:)];
    unapproveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_unapprove"] style:UIBarButtonItemStylePlain target:self action:@selector(unapproveSelectedComments:)];
    approveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_approve"] style:UIBarButtonItemStylePlain target:self action:@selector(spamSelectedComments:)];
    deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_delete"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteSelectedComments:)];
    
    if ([spamButton respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        spamButton.tintColor = color;
        unapproveButton.tintColor = color;
        approveButton.tintColor = color;
        deleteButton.tintColor = color;
    }

//    spamButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Spam", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(spamSelectedComments:)];
//    unapproveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Unapprove", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(unapproveSelectedComments:)];
//    approveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Approve", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(approveSelectedComments:)];
//    deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelectedComments:)];
//    deleteButton.style = UIBarButtonItemStyleBordered;

    if (IS_IPHONE) {
        UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
        self.toolbarItems = [NSArray arrayWithObjects:approveButton, spacer, unapproveButton, spacer, spamButton, spacer, deleteButton, nil];
    }

    self.tableView.accessibilityLabel = @"Comments";       // required for UIAutomation for iOS 4
	if([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		self.tableView.accessibilityIdentifier = @"Comments";  // required for UIAutomation for iOS 5
	}
    
    _selectedComments = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [_selectedComments release]; _selectedComments = nil;
    [spamButton release]; spamButton = nil;
    [unapproveButton release]; unapproveButton = nil;
    [approveButton release]; approveButton = nil;
    [deleteButton release]; deleteButton = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewWillAppear:animated];
    [self setEditing:NO animated:animated];
    if (IS_IPHONE) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    } else {
        self.toolbarItems = [NSArray arrayWithObject:self.editButtonItem];
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:animated];
    }
    self.commentViewController.delegate = nil;
    self.commentViewController = nil;
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
	
    UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    if (IS_IPHONE) {
        [self.navigationController setToolbarHidden:!editing animated:animated];        
    } else {
        if (editing) { 
            // intentionally doubling spacers to get the layout we want on the ipad
            self.toolbarItems = [NSArray arrayWithObjects:self.editButtonItem, spacer,  approveButton, spacer, spacer, unapproveButton, spacer, spacer, spamButton, spacer, spacer, deleteButton, spacer, nil];
        } else {
            self.toolbarItems = [NSArray arrayWithObject:self.editButtonItem];
        }
        if ([self.editButtonItem respondsToSelector:@selector(setTintColor:)]) {
            self.editButtonItem.tintColor = [UIColor UIColorFromHex:0x336699];
        }
    }
    
    if (editing) {
        //set up the blue button for nav bar
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom]; 
        UIFont *titleFont = [UIFont boldSystemFontOfSize:12];
        CGSize titleSize = [NSLocalizedString(@"Done", @"") sizeWithFont:titleFont];
        CGFloat buttonWidth = titleSize.width + 20;
        button.frame = CGRectMake(0, 0, buttonWidth, 30);
        
        [button setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        button.titleLabel.font = titleFont;
        button.titleLabel.shadowColor = [UIColor blackColor];
        button.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        [button addTarget:self action:@selector(stopEditing:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        self.navigationItem.rightBarButtonItem = doneButton;
        [doneButton release];
    } else {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(startEditing:)];
        self.navigationItem.rightBarButtonItem = editButton;
        [editButton release];
    }
    
    [deleteButton setEnabled:!editing];
    [approveButton setEnabled:!editing];
    [unapproveButton setEnabled:!editing];
    [spamButton setEnabled:!editing];

	[self deselectAllComments];
}

- (void) stopEditing:(id)sender {
    [self setEditing:NO animated:YES];
}

- (void) startEditing:(id)sender {
    [self setEditing:YES animated:YES];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    //Change title color on iOS 4
    if (![[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        UILabel *titleView = (UILabel *)self.navigationItem.titleView;
        if (!titleView) {
            titleView = [[UILabel alloc] initWithFrame:CGRectZero];
            titleView.backgroundColor = [UIColor clearColor];
            titleView.font = [UIFont boldSystemFontOfSize:20.0];
            titleView.shadowColor = [UIColor whiteColor];
            titleView.shadowOffset = CGSizeMake(0.0, 1.0);
            titleView.textColor = [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0];
            
            self.navigationItem.titleView = titleView;
            [titleView release];
        }
        titleView.text = title;
        [titleView sizeToFit];
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
    [self removeSwipeView:NO];
}

- (IBAction)approveSelectedComments:(id)sender {
    [self moderateCommentsWithSelector:@selector(approve)];
    [self removeSwipeView:NO];
}

- (IBAction)unapproveSelectedComments:(id)sender {
    [self moderateCommentsWithSelector:@selector(unapprove)];
    [self removeSwipeView:NO];
}

- (IBAction)spamSelectedComments:(id)sender {
    [self removeSwipeView:NO];
    [self moderateCommentsWithSelector:@selector(spam)];
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    [FileLogger log:@"%@ %@%@", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector)];
    [_selectedComments makeObjectsPerformSelector:selector];
    [self deselectAllComments];
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

//    [approveButton setTitle:(((count - approvedCount) > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Approve (%d)", @""), count - approvedCount]:NSLocalizedString(@"Approve", @""))];
//    [unapproveButton setTitle:(((count - unapprovedCount) > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Unapprove (%d)", @""), count - unapprovedCount]:NSLocalizedString(@"Unapprove", @""))];
//    [spamButton setTitle:(((count - spamCount) > 0) ? [NSString stringWithFormat:NSLocalizedString(@"Spam (%d)", @""), count - spamCount]:NSLocalizedString(@"Spam", @""))];
}

- (void)deselectAllComments {
    for (Comment *comment in _selectedComments) {
        NSIndexPath *indexPath = [self.resultsController indexPathForObject:comment];
        if (indexPath) {
            CommentTableViewCell *cell = (CommentTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                cell.checked = NO;
            }
        }
    }
    [_selectedComments removeAllObjects];
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
        self.currentIndexPath = indexPath;
        BOOL commentViewControllerVisible = YES;
        if (self.commentViewController == nil) {
            commentViewControllerVisible = NO;
            self.commentViewController = [[[CommentViewController alloc] init] autorelease];
            self.commentViewController.delegate = self;
        }
        [self.commentViewController showComment:comment];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        if (!commentViewControllerVisible) {
            [self.panelNavigationController pushViewController:self.commentViewController fromViewController:self animated:YES];
        }
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
                                                      }
                                                      completion:nil];
                                 }];
            });
        }
        comment.isNew = NO;
    } else if ([comment.status isEqual:@"hold"]) {
        cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
    } else {
        cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
    }

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [Comment titleForStatus:[sectionInfo name]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    CGSize commentSize = [comment.content sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(self.view.bounds.size.width - 16, 80)];
    return COMMENT_ROW_HEIGHT - 60 + MIN(commentSize.height, 60);
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
    NSSortDescriptor *sortDescriptorStatus = [[[NSSortDescriptor alloc] initWithKey:@"status" ascending:NO] autorelease];
    NSSortDescriptor *sortDescriptorDate = [[[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptorStatus, sortDescriptorDate, nil] autorelease];
    [fetchRequest setSortDescriptors:sortDescriptors];
    return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
    return @"status";
}

- (UITableViewCell *)newCell {
    // To comply with apple ownership and naming conventions, returned cell should have a retain count > 0, so retain the dequeued cell.
    static NSString *cellIdentifier = @"CommentCell";
    UITableViewCell *cell = [[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier] retain];
    if (cell == nil) {
        cell = [[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
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
    CGFloat height = 35.f;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    CGFloat y = (cell.bounds.size.height - height) / 2.f;

    /*
     | padding || button padding | button | button padding || button padding | button | button padding || ... || padding |
     */
    CGFloat buttonWidth = (swipeViewWidth - 2.0f * padding) / buttonCount - 2 * padding;
    CGFloat x = padding * 2;

    UIButton *button;
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    [_selectedComments removeAllObjects];
    [_selectedComments addObject:comment];

    UIImage* buttonImage = [[UIImage imageNamed:@"UISegmentBarBlackButton"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
    UIImage* buttonPressedImage = [[UIImage imageNamed:@"UISegmentBarBlackButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
    
    button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, buttonWidth, height)];
    if ([comment.status isEqualToString:@"approve"]) {
        [button addTarget:self action:@selector(unapproveSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:NSLocalizedString(@"Unapprove", @"") forState:UIControlStateNormal];
    } else {
        [button addTarget:self action:@selector(approveSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:NSLocalizedString(@"Approve", @"") forState:UIControlStateNormal];
    }
    button.titleLabel.font = [UIFont systemFontOfSize:13.f];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    [swipeView addSubview:button];
    [button release];
    x += buttonWidth + 2 * padding;
    
    button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, buttonWidth, height)];
    [button addTarget:self action:@selector(deleteSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:NSLocalizedString(@"Trash", @"") forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13.f];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    [swipeView addSubview:button];
    [button release];
    x += buttonWidth + 2 * padding;

    button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, buttonWidth, height)];
    [button addTarget:self action:@selector(spamSelectedComments:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:NSLocalizedString(@"Spam", @"") forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13.f];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    [swipeView addSubview:button];
    [button release];
    x += buttonWidth + 2 * padding;

    button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, buttonWidth, height)];
    [button addTarget:self action:@selector(replyToSelectedComment:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:NSLocalizedString(@"Reply", @"") forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13.f];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    [swipeView addSubview:button];
    [button release];
}

- (void)removeSwipeView:(BOOL)animated {
    if (!self.editing) {
        [_selectedComments removeAllObjects];
    }
    [super removeSwipeView:animated];
}

@end
