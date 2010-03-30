//
//  CommentViewController.m
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import "CommentViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
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


@synthesize replyToCommentViewController, editCommentViewController, commentsViewController, wasLastCommentPending;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [commentDetails release];
    [segmentedControl release];
    [segmentBarItem release];
	[replyToCommentViewController release];
	[editCommentViewController release];
	[commentsViewController release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
	
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
    self.navigationItem.rightBarButtonItem = segmentBarItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self performSelector:@selector(reachabilityChanged)];
	//[self updateCommentText];
	//if ([commentStatus isEqualToString:@"hold"]) {
//		wasLastCommentPending = YES;
//	}else{
		wasLastCommentPending = NO;
//	}

    [super viewWillAppear:animated];
	
	//NSDictionary *comment = [commentDetails objectAtIndex:currentIndex];
	NSLog(@"commentStatus is: %@", commentStatus);	
}

- (void)reachabilityChanged {
    connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
    UIColor *textColor = connectionStatus == YES ? [UIColor blackColor] : [UIColor grayColor];

    commentAuthorLabel.textColor = textColor;
    commentPostTitleLabel.textColor = textColor;
    commentDateLabel.textColor = textColor;
    commentBodyLabel.textColor = textColor;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //[self resizeCommentBodyLabel];
    //[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	//[super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	if(UIInterfaceOrientationIsLandscape(self.commentsViewController.interfaceOrientation)){
		NSLog(@"inside 999CVC if - landscape");
	}else {
		NSLog(@"inside 999CVC if - portriat");
	}
		
		
//    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//
//    if ([delegate isAlertRunning] == YES) {
//        return NO;
//    } else {
//        return YES;
//    }
	NSLog(@"inside CommentViewController's should autorotate");
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
	[actionSheet showInView:self.view];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];
	
	[actionSheet release];	
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
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
			[self discard];
		}
			
		if (buttonIndex == 1) {
			[self cancel];
		}
	}
		
	
	NSLog(@"buttonIndex is: %d", buttonIndex);
//handle action sheet for approve/spam/edit
    if ([actionSheet tag] == 301) {
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
	
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
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
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	
		replyToCommentViewController = [[[ReplyToCommentViewController alloc] 
										 initWithNibName:@"ReplyToCommentViewController" 
										 bundle:nil]autorelease];
		replyToCommentViewController.commentViewController = self;
	    //replyToCommentViewController.commentsViewController = self.commentsViewController;
		replyToCommentViewController.commentDetails = commentDetails;
	    replyToCommentViewController.currentIndex = currentIndex;
		replyToCommentViewController.title = @"Comment Reply";
	
	
    [delegate.navigationController pushViewController:self.replyToCommentViewController animated:YES];
}


- (void)cancelView:(id)sender {
	
	if (!replyToCommentViewController.hasChanges && !editCommentViewController.hasChanges) {
		[self.navigationController popViewControllerAnimated:YES];
		//replyToCommentViewController.hasChanges = NO;
        return;
    }//else if (!editCommentViewController.hasChanges) {
//        [self.navigationController popViewControllerAnimated:YES];
//		//editCommentViewController.hasChanges = NO;
//        return;
//    }
	
	
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
											   delegate:self cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:@"Discard"
											   otherButtonTitles:nil];
    actionSheet.tag = 401;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	
	if (replyToCommentViewController.hasChanges) { 
		[actionSheet showInView:replyToCommentViewController.view];
	}else if (editCommentViewController.hasChanges) {
		[actionSheet showInView:editCommentViewController.view];
		}
	
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];
	
    [actionSheet release];
	NSLog(@"last line of cancelView");
}

- (void)launchEditComment {
	[self showEditCommentViewWithAnimation:YES];
}



- (void)showEditCommentViewWithAnimation:(BOOL)animate {
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	
	editCommentViewController = [[[EditCommentViewController alloc] 
									 initWithNibName:@"EditCommentViewController" 
									 bundle:nil]autorelease];
	editCommentViewController.commentViewController = self;
	//replyToCommentViewController.commentsViewController = self.commentsViewController;
	editCommentViewController.commentDetails = commentDetails;
	editCommentViewController.currentIndex = currentIndex;
	editCommentViewController.title = @"Edit Comment";
	
	
    [delegate.navigationController pushViewController:self.editCommentViewController animated:YES];
}

	
#pragma mark -
#pragma mark Action Sheet Button Helper Methods



- (void)discard {
//    hasChanges = NO;
    replyToCommentViewController.navigationItem.rightBarButtonItem = nil;
//    [self stopTimer];
//    [[BlogDataManager sharedDataManager] clearAutoSavedContext];
    [self.navigationController popViewControllerAnimated:YES];
	
}

- (void)cancel {
    //hasChanges = YES;
	NSLog(@"first line of CommentViewControler:cancel");
	
    if ([[replyToCommentViewController.leftView title] isEqualToString:@"Comment"])
        [replyToCommentViewController.leftView setTitle:@"Cancel"];
}



#pragma mark -
#pragma mark Action Methods

- (void)segmentAction:(id)sender {
	if ([commentStatus isEqualToString:@"hold"]) {
		wasLastCommentPending = YES;
	}else {
		wasLastCommentPending = NO;
	}

    if (currentIndex > -1) {
        if ([sender selectedSegmentIndex] == 0 && currentIndex > 0) {
            [self showComment:commentDetails atIndex:currentIndex - 1];
        } else if ([sender selectedSegmentIndex] == 1 && currentIndex < [commentDetails count] - 1) {
            [self showComment:commentDetails atIndex:currentIndex + 1];
        }
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
	
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
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
    if (![[Reachability sharedReachability] remoteHostStatus] != NotReachable) {
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
	if ([commentStatus isEqualToString:@"hold"]) {
		return YES;
    } else  {
        return NO;
	}
	
	
}


- (void)moderateCommentWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self isConnectedToHost]) {
        BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];

        NSArray *selectedComment = [NSArray arrayWithObjects:[commentDetails objectAtIndex:currentIndex], nil];

        [sharedDataManager performSelector:selector withObject:selectedComment withObject:[sharedDataManager currentBlog]];

        [sharedDataManager loadCommentTitlesForCurrentBlog];
        [self.navigationController popViewControllerAnimated:YES];
    }

    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
}

- (void)deleteThisComment {
    [self moderateCommentWithSelector:@selector(deleteComment:forBlog:)];
}

- (void)approveThisComment {
    [self moderateCommentWithSelector:@selector(approveComment:forBlog:)];
}

- (void)markThisCommentAsSpam {
    [self moderateCommentWithSelector:@selector(spamComment:forBlog:)];
}

- (void)unapproveThisComment {
    [self moderateCommentWithSelector:@selector(unApproveComment:forBlog:)];
}

- (void)resizeCommentBodyLabel {  //:(BOOL)wasLastPending {
	
	//if pending label will be shown, scrollView.contentSize has to reflect the extra pixels taken by the pending label
	if ([commentStatus isEqualToString:@"hold"]){ 
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
	
	pendingLabelHolder.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BORDER_COLOR;
		pendingLabel.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;

		[labelHolder addSubview:pendingLabelHolder];
		//[labelHolder sizeToFit];
		
		//[self.contentView addSubview:checkButton];
        //checkButton.alpha = 1;
        //checkButton.enabled = YES;
        //self.accessoryType = UITableViewCellAccessoryNone;
    
    
    rect = gravatarImageView.frame;
    rect.origin.y += pendingLabelHeight;
    gravatarImageView.frame = rect;
    
    rect = commentAuthorLabel.frame;
    rect.origin.y += pendingLabelHeight;
    commentAuthorLabel.frame = rect;
    
    rect = commentAuthorUrlLabel.frame;
    rect.origin.y += pendingLabelHeight;
	commentAuthorUrlLabel.frame = rect;
	
    rect = commentAuthorEmailLabel.frame;
    rect.origin.y += pendingLabelHeight;
	commentAuthorEmailLabel.frame = rect;
    
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
		
		rect = commentAuthorUrlLabel.frame;
		rect.origin.y -= pendingLabelHeight;
		//rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
		commentAuthorUrlLabel.frame = rect;
		
		rect = commentAuthorEmailLabel.frame;
		rect.origin.y -= pendingLabelHeight;
		//rect.size.width = OTHER_LABEL_WIDTH - buttonOffset;
		commentAuthorEmailLabel.frame = rect;
		
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

- (void)showComment:(NSArray *)comments atIndex:(int)index {
    currentIndex = index;
	commentDetails = [comments mutableCopy];
	NSLog(@"this is the NSArray commentDetails from showComment %@", commentDetails);
    NSDictionary *comment = [commentDetails objectAtIndex:currentIndex];
	NSLog(@"this is the nsdict 'comment' from showComment %@", comment);
    
    static NSDateFormatter *dateFormatter = nil;
    int count = [commentDetails count];

    NSString *author = [[comment valueForKey:@"author"] trim];
    NSString *postTitle = [[comment valueForKey:@"post_title"] trim];
    NSString *commentBody = [[comment valueForKey:@"content"] trim];
    NSDate *createdAt = [comment valueForKey:@"date_created_gmt"];
    //NSString *commentStatus = [comment valueForKey:@"status"];
	commentStatus = [comment valueForKey:@"status"];
    NSString *authorEmail = [comment valueForKey:@"author_email"];
    NSString *authorUrl = [comment valueForKey:@"author_url"];

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
    
	gravatarImageView.email = authorEmail;
	commentAuthorEmailLabel.text = authorEmail;
    commentAuthorLabel.text = author;
    commentAuthorUrlLabel.text = authorUrl;
    commentPostTitleLabel.text = [@"on " stringByAppendingString:postTitle];
    commentDateLabel.text = [@"" stringByAppendingString:[dateFormatter stringFromDate:createdAt]];
    commentBodyLabel.text = commentBody;
    
    [self resizeCommentBodyLabel];

    self.navigationItem.title = [NSString stringWithFormat:@"%d of %d", currentIndex + 1, count];

    if ([commentStatus isEqualToString:@"hold"] && wasLastCommentPending == NO) {
        //[approveAndUnapproveButtonBar setHidden:NO];
        //[deleteButtonBar setHidden:YES];
		[self insertPendingLabel];
		NSLog(@"inside if commentStatus is hold");
		//[self resizeCommentBodyLabel];//:wasLastCommentPending];
		[approveAndUnapproveButtonBar setHidden:YES];
		[deleteButtonBar setHidden:NO];
		
	}else if ([commentStatus isEqualToString:@"hold"] && wasLastCommentPending == YES) {
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

//    [approveButton setEnabled:NO];
//    [unapproveButton setEnabled:NO];
//    [spamButton1 setEnabled:YES];
//    [spamButton2 setEnabled:YES];
//
//    if ([commentStatus isEqualToString:@"hold"]) {
//        [approveButton setEnabled:YES];
//    } else if ([commentStatus isEqualToString:@"approve"]) {
//        [unapproveButton setEnabled:YES];
//    } else if ([commentStatus isEqualToString:@"spam"]) {
//        [spamButton1 setEnabled:NO];
//        [spamButton2 setEnabled:NO];
//    }
	
    [segmentedControl setEnabled:TRUE forSegmentAtIndex:0];
    [segmentedControl setEnabled:TRUE forSegmentAtIndex:1];

    if (currentIndex == 0) {
        [segmentedControl setEnabled:FALSE forSegmentAtIndex:0];
    } else if (currentIndex == [commentDetails count] - 1) {
        [segmentedControl setEnabled:FALSE forSegmentAtIndex:1];
    }
}

@end
