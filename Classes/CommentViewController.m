//
//  CommentViewController.m
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import "CommentViewController.h"
#import "WPReachability.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"


#define COMMENT_BODY_TOP        100
#define COMMENT_BODY_MAX_HEIGHT 4000
#define COMMENT_BODY_PADDING 20
#define JUST_TO_AVIID_COMPILER_ERRORS 400

#define kCustomButtonHeight     30.0

@interface CommentViewController (Private)

- (void)resizeCommentBodyLabel;
- (BOOL)isConnectedToHost;
- (BOOL)isApprove;
- (void)moderateCommentWithSelector:(SEL)selector;
- (void)deleteThisComment;
- (void)approveThisComment;
- (void)markThisCommentAsSpam;
- (void)unapproveThisComment;
- (void)cancel;
- (void)discard;

- (void)showReplyToCommentViewWithAnimation:(BOOL)animate;
- (void)showEditCommentViewWithAnimation:(BOOL)animate;
- (void)insertPendingLabel;
- (void)removePendingLabel;

- (void)launchReplyToComments;
- (void)launchEditComment;

@end

@implementation CommentViewController


@synthesize replyToCommentViewController, editCommentViewController, commentsViewController, wasLastCommentPending, commentAuthorUrlButton, commentAuthorEmailButton;
@synthesize comment = _comment, isVisible;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    self.comment = nil;
    [segmentedControl release];
    [segmentBarItem release];
	[replyToCommentViewController release];
	[editCommentViewController release];
	[commentsViewController release];
	[commentAuthorUrlButton release];
	[commentAuthorEmailButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (CGSize)contentSizeForViewInPopover;
{
	return CGSizeMake(320, 400);
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	
    segmentedControl = [[UISegmentedControl alloc] initWithItems:
                        [NSArray arrayWithObjects:
                         [UIImage imageNamed:@"up.png"],
                         [UIImage imageNamed:@"down.png"],
                         nil]];
    
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    
    segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	
	[self addOrRemoveSegmentedControl];
	
	self.navigationItem.title = @"Comment";
	
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self performSelector:@selector(reachabilityChanged)];
	wasLastCommentPending = NO;
	isVisible = YES;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	isVisible = NO;
    [super viewWillDisappear:animated];
}

- (void)reachabilityChanged {
    connectionStatus = ([[WPReachability sharedReachability] remoteHostStatus] != NotReachable);
    UIColor *textColor = connectionStatus == YES ? [UIColor blackColor] : [UIColor grayColor];

    commentAuthorLabel.textColor = textColor;
    commentPostTitleLabel.textColor = textColor;
    commentDateLabel.textColor = textColor;
    commentBodyLabel.textColor = textColor;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //[self resizeCommentBodyLabel];
    //[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self addOrRemoveSegmentedControl];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

//not truly an ActionSheetDelegate method, but it's where we call the ActionSheet...
- (void) launchModerateMenu {
	NSString *conditionalButtonTitle = nil;
	
	if ([self isApprove]) {
		conditionalButtonTitle = @"Approve Comment";
	} else {
		conditionalButtonTitle = @"Unapprove Comment";
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
															 delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
													otherButtonTitles: conditionalButtonTitle, @"Mark Comment as Spam", @"Edit Comment",nil];
													//otherButtonTitles: conditionalButtonTitle, @"Mark Comment as Spam",nil];
	
	actionSheet.tag = 301;
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	if (DeviceIsPad() == YES) {
        spamButton1.enabled = NO;
		[actionSheet showFromBarButtonItem:spamButton1 animated:YES];
	} else {
		[actionSheet showInView:self.view];
	}
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];
	
	[actionSheet release];	
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	
//handle action sheet from trash button
	if ([actionSheet tag] == 501) {
		if (buttonIndex == 0) {
			[self deleteComment:nil];
		}
		
		if (buttonIndex == 1) {
			
		}
	}
	
	//handle action sheet from replyToCommentsViewController
	if ([actionSheet tag] == 401) {
		if (buttonIndex == 0) {
			if (replyToCommentViewController.hasChanges) { 
				replyToCommentViewController.hasChanges = NO;
				[replyToCommentViewController.comment remove];
			} 
			[self discard];
		}
		
		if (buttonIndex == 1) {
			[self cancel];
		}
	}
	
	
	//handle action sheet from editCommentsViewController
	if ([actionSheet tag] == 601) {
		if (buttonIndex == 0) {
			editCommentViewController.hasChanges = NO;
			[self discard];
		}
		
		if (buttonIndex == 1) {
			[self cancel];
		}
	}
		
	
	//handle action sheet for approve/spam/edit
    if ([actionSheet tag] == 301) {
        spamButton1.enabled = YES;
        if (buttonIndex == 0) {  //Approve/Unapprove conditional button was selected
			if ([self isApprove]) {
				[self approveComment:nil];
			} else {
				[self unApproveComment:nil];
			}
        }
		
        if (buttonIndex == 1) {  //Mark as Spam was selected
            [self spamComment:nil];
        }
		
		if (buttonIndex == 2) {  //Edit Comment was selected
			[self launchEditComment];
			//[self showEditCommentModalViewWithAnimation:YES];
			//... or [self editThisComment]; (if we need more data loading perhaps)
			//yet to be written...
			//launch the modal editing view and load it with the selected comment
			//editing view to save new comment and return to this screen with new comment loaded into detail
			//consider making this edit view and the reply-to-comment edit view the same xib
			//   and load data conditionally
        }
    }
	
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}


#pragma mark -
#pragma mark ReplyToCommentViewController methods
//These methods call the ReplyToCommentViewController as well as handling the "back-referenced" cancel button click
//that has to be run here given the view heirarchy...

- (void)launchReplyToComments {
	[self showReplyToCommentViewWithAnimation:YES];
}
- (void)showReplyToCommentViewWithAnimation:(BOOL)animate {
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
		self.replyToCommentViewController = [[[ReplyToCommentViewController alloc] 
										 initWithNibName:@"ReplyToCommentViewController" 
										 bundle:nil]autorelease];
		replyToCommentViewController.commentViewController = self;
		replyToCommentViewController.comment = [[self.comment newReply] autorelease];
		replyToCommentViewController.title = @"Comment Reply";
	
	
	if (DeviceIsPad() == NO) {
		[delegate.navigationController pushViewController:self.replyToCommentViewController animated:YES];
	} else {
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:replyToCommentViewController] autorelease];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		[self presentModalViewController:navController animated:YES];
	}
}

- (void)dismissEditViewController;
{
	if (DeviceIsPad() == NO) {
        [self.navigationController popViewControllerAnimated:YES];
	}
	else if (DeviceIsPad() == YES) {
		[self dismissModalViewControllerAnimated:YES];
		
	}
}

- (void)cancelView:(id)sender {
	
	//there are no changes
	if (!replyToCommentViewController.hasChanges && !editCommentViewController.hasChanges) {
		[self dismissEditViewController];
		
		if(sender == replyToCommentViewController) { 
			
			//NSNumber *parentCommentID = [replyToCommentViewController.comment.parentID copy]; 
			
			[replyToCommentViewController.comment remove]; //delete the empty comment 
			
			//on iPad we should reselect and show the current comment on the right side
			//http://ios.trac.wordpress.org/ticket/750
			/*
			if (DeviceIsPad() == YES) { 
				NSIndexPath *currentCommentIndexPath = nil;
				NSArray *sections = [commentsViewController.resultsController sections];
				
				int currentSectionIndex = 0;
				for (currentSectionIndex = 0; currentSectionIndex < [sections count]; currentSectionIndex++) {
					id <NSFetchedResultsSectionInfo> sectionInfo = nil;
					sectionInfo = [sections objectAtIndex:currentSectionIndex];
					
					int currentCommentIndex = 0;
					NSArray *commentsForSection = [sectionInfo objects];
					
					for (currentCommentIndex = 0; currentCommentIndex < [commentsForSection count]; currentCommentIndex++) {
						Comment *cmt = [commentsForSection objectAtIndex:currentCommentIndex];
						NSLog(@"comment ID == %@", cmt.commentID);
						NSLog(@"self.comment ID == %@", parentCommentID);
						if([cmt.commentID  compare:parentCommentID] == NSOrderedSame) { 
							currentCommentIndexPath = [NSIndexPath indexPathForRow:currentCommentIndex inSection:currentSectionIndex];
							[commentsViewController showCommentAtIndexPath:currentCommentIndexPath];
							return;
						}
					}
				}
			}
			*/
			/* 
			 I tried to use this code but doesn't work. the currentIndexPath is always nil bc self.comment is nil
			 NSFetchedResultsController *resCtrl = [commentsViewController resultsController];
			 
			 NSIndexPath *currentIndexPath = [resCtrl indexPathForObject:self.comment];
			 if(currentIndexPath != nil) {
			 [commentsViewController showCommentAtIndexPath:currentIndexPath];
			 }
			 */
			
		} //sender == replyToCommentViewController
		
		return;
	}
	
		
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
											   delegate:self cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:@"Discard"
											   otherButtonTitles:nil];
    
	if (replyToCommentViewController.hasChanges)
		actionSheet.tag = 401;
	else if (editCommentViewController.hasChanges)
		actionSheet.tag = 601;
    
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	
	if (replyToCommentViewController.hasChanges) { 
		[actionSheet showInView:replyToCommentViewController.view];
	}else if (editCommentViewController.hasChanges) {
		[actionSheet showInView:editCommentViewController.view];
	}
	
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];
	
    [actionSheet release];
}

- (void)launchEditComment {
	[self showEditCommentViewWithAnimation:YES];
}


- (void)showEditCommentViewWithAnimation:(BOOL)animate {
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
	self.editCommentViewController = [[[EditCommentViewController alloc] 
									 initWithNibName:@"EditCommentViewController" 
									 bundle:nil]autorelease];
	editCommentViewController.commentViewController = self;
	//replyToCommentViewController.commentsViewController = self.commentsViewController;
	editCommentViewController.comment = self.comment;
	editCommentViewController.title = @"Edit Comment";
	
	if (DeviceIsPad() == YES) {
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:editCommentViewController] autorelease];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		[self presentModalViewController:navController animated:YES];
	} else {
		[delegate.navigationController pushViewController:self.editCommentViewController animated:YES];
	}
}

	
#pragma mark -
#pragma mark Action Sheet Button Helper Methods



- (void)discard {
//    hasChanges = NO;
    replyToCommentViewController.navigationItem.rightBarButtonItem = nil;
	[self dismissEditViewController];
}

- (void)cancel {	
    //if ([[replyToCommentViewController.leftView title] isEqualToString:@"Comment"])
    //    [replyToCommentViewController.leftView setTitle:@"Cancel"];
}



#pragma mark -
#pragma mark Action Methods

- (void)segmentAction:(id)sender {
	if ([self.comment.status isEqualToString:@"hold"]) {
		wasLastCommentPending = YES;
	}else {
		wasLastCommentPending = NO;
	}
    if (segmentedControl.selectedSegmentIndex == 0) {
        [commentsViewController showPreviousComment];
    } else {
        [commentsViewController showNextComment];
    }

}

- (void)launchDeleteCommentActionSheet {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure?"
															 delegate:self cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:@"Delete"
													otherButtonTitles:nil];
    actionSheet.tag = 501;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
	
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];
	
    [actionSheet release];
	
}

- (void)deleteComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting..."];
    [progressAlert show];
    [self performSelectorInBackground:@selector(deleteThisComment) withObject:nil];
}

- (void)approveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(approveThisComment) withObject:nil];
}

- (void)unApproveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(unapproveThisComment) withObject:nil];
}

- (void)spamComment:(id)sender {
   progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
    [progressAlert show];

    [self performSelectorInBackground:@selector(markThisCommentAsSpam) withObject:nil];
	
}

- (BOOL)isConnectedToHost {
    if (![[WPReachability sharedReachability] remoteHostStatus] != NotReachable) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
                                            message:@"Operation is not supported now."
                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectionFailAlert show];
        [connectionFailAlert release];
        return NO;
    }

    return YES;
}
- (BOOL)isApprove {
	if ([self.comment.status isEqualToString:@"hold"]) {
		return YES;
    } else  {
        return NO;
	}
}


- (void)moderateCommentWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL fails = NO;
    if ([self isConnectedToHost]) {
		if(![self.comment performSelector:selector])
			fails = YES;
    }
	
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
		
	if(fails)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:@"Something went wrong during comments moderation."];	
    else {
		 [self.navigationController popViewControllerAnimated:YES];
	}

	[pool release];
}

- (void)deleteThisComment {
    [self moderateCommentWithSelector:@selector(remove)];
	if (DeviceIsPad() == YES)
		[self.commentsViewController performSelectorOnMainThread:@selector(trySelectSomethingAndShowIt) withObject:nil waitUntilDone:NO];
}

- (void)approveThisComment {
    [self moderateCommentWithSelector:@selector(approve)];
}

- (void)markThisCommentAsSpam {
    [self moderateCommentWithSelector:@selector(spam)];
}

- (void)unapproveThisComment {
    [self moderateCommentWithSelector:@selector(unapprove)];
}

- (void)resizeCommentBodyLabel {  //:(BOOL)wasLastPending {
	
	//if pending label will be shown, scrollView.contentSize has to reflect the extra pixels taken by the pending label
	if ([self.comment.status isEqualToString:@"hold"]){ 
		float pendingLabelHeight = pendingLabelHolder.frame.size.height;
		CGSize size = [commentBodyLabel.text sizeWithFont:commentBodyLabel.font
										constrainedToSize:CGSizeMake(self.view.frame.size.width - COMMENT_BODY_PADDING, COMMENT_BODY_MAX_HEIGHT)
											lineBreakMode:commentBodyLabel.lineBreakMode];
		//scrollView.contentSize = CGSizeMake(size.width, COMMENT_BODY_TOP + 45.0f + size.height);
		scrollView.contentSize = CGSizeMake(size.width, COMMENT_BODY_TOP + pendingLabelHeight + COMMENT_BODY_PADDING + size.height);
		commentBodyLabel.frame = CGRectMake(commentBodyLabel.frame.origin.x, COMMENT_BODY_TOP, size.width, size.height);
		
		
	}else{

    CGSize size = [commentBodyLabel.text sizeWithFont:commentBodyLabel.font
                    constrainedToSize:CGSizeMake(self.view.frame.size.width - COMMENT_BODY_PADDING, COMMENT_BODY_MAX_HEIGHT)
                        lineBreakMode:commentBodyLabel.lineBreakMode];
    scrollView.contentSize = CGSizeMake(size.width, COMMENT_BODY_TOP + size.height);
	//scrollView.contentSize = CGSizeMake(size.width, commentBodyLabel.frame.origin.y + size.height);
    commentBodyLabel.frame = CGRectMake(commentBodyLabel.frame.origin.x, COMMENT_BODY_TOP, size.width, size.height);
	}
}

#pragma mark resize top UIView

- (void)insertPendingLabel {
	
	/*
	 move all the labels down to accomodate the pending header
	 which is 40 high.
	 */
	
    CGRect rect;

	float pendingLabelHeight = pendingLabelHolder.frame.size.height;
    //int pendingLabelOffset = 0;
    
    //if (isPending) {
//        pendingLabelOffset = 100;
//		UILabel *myLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
//		myLabel2.text = @"only Xcode";
//		myLabel2.textAlignment = UITextAlignmentCenter;
//		myLabel2.textColor = [UIColor yellowColor];
//		myLabel2.shadowColor = [UIColor whiteColor];
//		myLabel2.shadowOffset = CGSizeMake(1,1);
//		myLabel2.font = [UIFont fontWithName:@"Zapfino" size:20];
//		myLabel2.backgroundColor = [UIColor greenColor];
	
		pendingLabelHolder.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;

		[labelHolder addSubview:pendingLabelHolder];
		//[labelHolder sizeToFit];
		
		//[self.contentView addSubview:checkButton];
        //checkButton.alpha = 1;
        //checkButton.enabled = YES;
        //self.accessoryType = UITableViewCellAccessoryNone;
    
    
	rect = pendingLabelHolder.frame;
	rect.size.width = [pendingLabelHolder superview].frame.size.width;
	pendingLabelHolder.frame = rect;
	
    rect = gravatarImageView.frame;
    rect.origin.y += pendingLabelHeight;
    gravatarImageView.frame = rect;
    
    rect = commentAuthorLabel.frame;
    rect.origin.y += pendingLabelHeight;
    commentAuthorLabel.frame = rect;
    
    rect = commentAuthorUrlButton.frame;
    rect.origin.y += pendingLabelHeight;
	commentAuthorUrlButton.frame = rect;
	
    rect = commentAuthorEmailButton.frame;
    rect.origin.y += pendingLabelHeight;
	commentAuthorEmailButton.frame = rect;
    
    rect = commentPostTitleLabel.frame;
    rect.origin.y += pendingLabelHeight;
    commentPostTitleLabel.frame = rect;
	
	rect = commentDateLabel.frame;
    rect.origin.y += pendingLabelHeight;
    commentDateLabel.frame = rect;
	
	rect = commentBodyLabel.frame;
    rect.origin.y += pendingLabelHeight;
    commentBodyLabel.frame = rect;
	
	[labelHolder sizeToFit];
	
	

	}

- (void)removePendingLabel {
	
	if ([pendingLabelHolder superview] == labelHolder) {
		float pendingLabelHeight = pendingLabelHolder.frame.size.height;
		[pendingLabelHolder removeFromSuperview];
	
		CGRect rect = gravatarImageView.frame;
		rect.origin.y -= pendingLabelHeight;
		gravatarImageView.frame = rect;
		
		rect = commentAuthorLabel.frame;
		rect.origin.y -= pendingLabelHeight;
		//rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
		commentAuthorLabel.frame = rect;
		
		rect = commentAuthorUrlButton.frame;
		rect.origin.y -= pendingLabelHeight;
		//rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
		commentAuthorUrlButton.frame = rect;
		
		rect = commentAuthorEmailButton.frame;
		rect.origin.y -= pendingLabelHeight;
		//rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
		commentAuthorEmailButton.frame = rect;
		
		rect = commentPostTitleLabel.frame;
		rect.origin.y -= pendingLabelHeight;
		//rect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
		commentPostTitleLabel.frame = rect;
		
		rect = commentDateLabel.frame;
		rect.origin.y -= pendingLabelHeight;
		//rect.size.width = COMMENT_LABEL_WIDTH - buttonOffset;
		commentDateLabel.frame = rect;
	}
}


#pragma mark -
#pragma mark Public Methods

- (void)showComment:(Comment *)comment {
    self.comment = comment;
    static NSDateFormatter *dateFormatter = nil;

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
    NSLog(@"Comment: %@", comment);
	NSLog(@"Trimmed: %@", [comment.author_url trim]);
	gravatarImageView.email = [comment.author_email trim];
    commentAuthorLabel.text = [comment.author trim];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateNormal];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateHighlighted];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateSelected];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateNormal];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateHighlighted];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateSelected];
    if (comment.postTitle)
        commentPostTitleLabel.text = [@"on " stringByAppendingString:[comment.postTitle trim]];
	if(comment.dateCreated != nil)
		commentDateLabel.text = [@"" stringByAppendingString:[dateFormatter stringFromDate:comment.dateCreated]];
	else
		commentDateLabel.text = @"";
	commentBodyLabel.text = [comment.content trim];
    
    [self resizeCommentBodyLabel];

    if ([comment.status isEqualToString:@"hold"] && ![pendingLabelHolder superview]) {
        //[approveAndUnapproveButtonBar setHidden:NO];
        //[deleteButtonBar setHidden:YES];
		[self insertPendingLabel];
		//[self resizeCommentBodyLabel];//:wasLastCommentPending];
		[approveAndUnapproveButtonBar setHidden:YES];
		[deleteButtonBar setHidden:NO];
		
	} else if ([comment.status isEqualToString:@"hold"] && [pendingLabelHolder superview]) {
		//[self resizeCommentBodyLabel];
		CGRect rect;
		rect = commentBodyLabel.frame;
		rect.origin.y += pendingLabelHolder.frame.size.height;
		commentBodyLabel.frame = rect;
	} else {
        //[approveAndUnapproveButtonBar setHidden:YES];
        //[deleteButtonBar setHidden:NO];
		[self removePendingLabel];
		//[self resizeCommentBodyLabel];//:wasLastCommentPending];
		[approveAndUnapproveButtonBar setHidden:YES];
		[deleteButtonBar setHidden:NO];

    }

    [segmentedControl setEnabled:[commentsViewController hasPreviousComment] forSegmentAtIndex:0];
    [segmentedControl setEnabled:[commentsViewController hasNextComment] forSegmentAtIndex:1];
}

- (void)viewURL{
	NSURL *url = [NSURL URLWithString: [self.comment.author_url trim]];
	if (url != nil) {
		[[UIApplication sharedApplication] openURL:url];
	}
}

- (void)sendEmail{
	if (self.comment.author_email) {
		MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
		controller.mailComposeDelegate = self;
		NSArray *recipient = [[NSArray alloc] initWithObjects:[self.comment.author_email trim], nil];
		[controller setToRecipients: recipient];
		[controller setSubject:[NSString stringWithFormat:@"Re: %@", self.comment.postTitle]]; 
		[controller setMessageBody:[NSString stringWithFormat:@"Hi %@,", self.comment.author] isHTML:NO];
		[self presentModalViewController:controller animated:YES];
		[recipient release];
		[controller release];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller  didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)addOrRemoveSegmentedControl {
	if (DeviceIsPad() && self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight){
		self.navigationItem.rightBarButtonItem = nil;
	}	
	else
		self.navigationItem.rightBarButtonItem = segmentBarItem;
}

@end
