//
//  CommentViewController.m
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import "CommentViewController.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"
#import "NSString+XMLExtensions.h"
#import "WPWebViewController.h"
#import "UIImageView+Gravatar.h"

#define COMMENT_BODY_TOP        100
#define COMMENT_BODY_MAX_HEIGHT 4000
#define COMMENT_BODY_PADDING 20
#define JUST_TO_AVIID_COMPILER_ERRORS 400

#define kCustomButtonHeight     30.0

@interface CommentViewController (Private)
- (void)showSynchInProgressAlert;
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

-(void)reachabilityChanged:(NSNotification*)note;

@end

@implementation CommentViewController


@synthesize replyToCommentViewController, editCommentViewController, commentsViewController, wasLastCommentPending, commentAuthorUrlButton, commentAuthorEmailButton;
@synthesize comment = _comment, isVisible;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.comment = nil;
    [segmentedControl release];
    [segmentBarItem release];
	[replyToCommentViewController release];
	[editCommentViewController release];
	[commentsViewController release];
	[commentAuthorUrlButton release];
	[commentAuthorEmailButton release];
	commentBodyWebView.delegate = nil;
    [commentBodyWebView stopLoading];
    [commentBodyWebView release];
    [pendingApproveButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
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
    
    gravatarImageView.layer.cornerRadius = 10.0f;
    gravatarImageView.layer.masksToBounds = YES;
    
    segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	
	[self addOrRemoveSegmentedControl];
	
	self.navigationItem.title = NSLocalizedString(@"Comment", @"");
	
	commentBodyWebView.backgroundColor = [UIColor whiteColor];
	//hide the shadow for the UIWebView, nicked from stackoverflow.com/questions/1074320/remove-uiwebview-shadow/
	for(UIView *wview in [[[commentBodyWebView subviews] objectAtIndex:0] subviews]) { 
		if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
	}
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(reachabilityChanged:) 
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    
    if (self.comment) {
        [self showComment:self.comment];
    }
}

- (void)viewDidUnload {
    [pendingApproveButton release];
    pendingApproveButton = nil;
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [segmentedControl release]; segmentedControl = nil;
    [gravatarImageView release]; gravatarImageView = nil;
    self.commentAuthorEmailButton = nil;
    self.commentAuthorUrlButton = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	wasLastCommentPending = NO;
	isVisible = YES;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	isVisible = NO;
    [super viewWillDisappear:animated];
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability *reach = [note object];
    WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ( reach == appDelegate.currentBlogReachability ) { //The reachability of the current blog changed
        connectionStatus = ( [reach isReachable] );
        UIColor *textColor = connectionStatus == YES ? [UIColor blackColor] : [UIColor grayColor];
        commentAuthorLabel.textColor = textColor;
        commentPostTitleLabel.textColor = textColor;
        commentDateLabel.textColor = textColor;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
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
	if(self.commentsViewController.blog.isSyncingComments) {
		[self showSynchInProgressAlert];
		return;
	} 
	
	NSString *conditionalButtonTitle = nil;

	if ([self isApprove]) {
		conditionalButtonTitle = NSLocalizedString(@"Approve Comment", @"");
	} else {
		conditionalButtonTitle = NSLocalizedString(@"Unapprove Comment", @"");
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil
													otherButtonTitles: NSLocalizedString(@"Delete Comment", @""), NSLocalizedString(@"Mark Comment as Spam", @""), NSLocalizedString(@"Edit Comment", @""),nil];
	//otherButtonTitles: conditionalButtonTitle, NSLocalizedString(@"Mark Comment as Spam", @""),nil];
	
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
        if (buttonIndex == 0) {  //Delete comment was selected
			[self deleteComment:nil];
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

-(void) showSynchInProgressAlert {
	//the blog is using the network connection and cannot be stoped, show a message to the user
	UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
																  message:NSLocalizedString(@"The blog is syncing with the server. Please try later.", @"")
																 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
	[blogIsCurrentlyBusy show];
	[blogIsCurrentlyBusy release];
}

- (void)launchReplyToComments {
	if(self.commentsViewController.blog.isSyncingComments) {
		[self showSynchInProgressAlert];
	} else {
		[self showReplyToCommentViewWithAnimation:YES];
	}
}
- (void)showReplyToCommentViewWithAnimation:(BOOL)animate {
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
		self.replyToCommentViewController = [[[ReplyToCommentViewController alloc] 
										 initWithNibName:@"ReplyToCommentViewController" 
										 bundle:nil]autorelease];
		replyToCommentViewController.commentViewController = self;
		replyToCommentViewController.comment = [[self.comment newReply] autorelease];
		replyToCommentViewController.title = NSLocalizedString(@"Comment Reply", @"Comment Reply view title");
	
	
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


- (void) closeReplyViewAndSelectTheNewComment {
	[self dismissEditViewController];
	[self.commentsViewController trySelectSomething];
}

- (void)cancelView:(id)sender {
	
	//there are no changes
	if (!replyToCommentViewController.hasChanges && !editCommentViewController.hasChanges) {
		[self dismissEditViewController];
		
		if(sender == replyToCommentViewController) {
			commentsViewController.selectedIndexPath = nil; //the selectedIndex path is on the reply comment
			
			[replyToCommentViewController.comment remove]; //delete the empty comment
			
			if (DeviceIsPad() == YES)  //an half-patch for #790: sometimes the modal view is not disposed when click on cancel. 
				[self dismissModalViewControllerAnimated:YES]; 		
		} 
		return;
	}
	
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"")
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
											   destructiveButtonTitle:NSLocalizedString(@"Discard", @"")
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
	editCommentViewController.comment = self.comment;
	editCommentViewController.title = NSLocalizedString(@"Edit Comment", @"");
	
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
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure?", @"")
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
											   destructiveButtonTitle:NSLocalizedString(@"Delete", @"")
													otherButtonTitles:nil];
    actionSheet.tag = 501;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
	
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];
	
    [actionSheet release];
	
}

- (void)deleteComment:(id)sender {
	if(self.commentsViewController.blog.isSyncingComments) {
		[self showSynchInProgressAlert];
		return;
	}
    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Deleting...", @"")];
    [progressAlert show];
    [self performSelectorInBackground:@selector(deleteThisComment) withObject:nil];
}

- (void)approveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Moderating...", @"")];
    [progressAlert show];

    [self performSelectorInBackground:@selector(approveThisComment) withObject:nil];
}

- (void)unApproveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Moderating...", @"")];
    [progressAlert show];

    [self performSelectorInBackground:@selector(unapproveThisComment) withObject:nil];
}

- (void)spamComment:(id)sender {
   progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Moderating...", @"")];
    [progressAlert show];

    [self performSelectorInBackground:@selector(markThisCommentAsSpam) withObject:nil];
	
}

- (BOOL)isConnectedToHost {
    WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.currentBlogAvailable == NO ) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No connection to host.", @"")
                                            message:NSLocalizedString(@"Operation is not supported now.", @"Can't do operation (comment moderate/edit) since there's no connection")
                                            delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
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

- (void)didFailModerateComment {
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:NSLocalizedString(@"Sorry, something went wrong during comment moderation. Please try again.", @"")];	
}

- (void)didModerateComment {
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)moderateCommentWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL fails = NO;
    if ([self isConnectedToHost]) {
		if(![self.comment performSelector:selector])
			fails = YES;
    }
    
    if (fails) {
        [self performSelectorOnMainThread:@selector(didFailModerateComment) withObject:NO waitUntilDone:YES];
    } else {
        [self performSelectorOnMainThread:@selector(didModerateComment) withObject:NO waitUntilDone:YES];        
    }

	[pool release];
}

- (void)deleteThisComment {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(remove)];
	if (DeviceIsPad() == YES)
		[self.commentsViewController performSelectorOnMainThread:@selector(trySelectSomethingAndShowIt) withObject:nil waitUntilDone:NO];
}

- (void)approveThisComment {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(approve)];
}

- (void)markThisCommentAsSpam {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(spam)];
	if (DeviceIsPad() == YES)
		[self.commentsViewController performSelectorOnMainThread:@selector(trySelectSomethingAndShowIt) withObject:nil waitUntilDone:NO];
}

- (void)unapproveThisComment {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(unapprove)];
}

#pragma mark resize top UIView

- (void)insertPendingLabel {
	
	/*
	 move all the labels down to accomodate the pending header
	 which is 40 high.
	 */
	
    CGRect rect;

	float pendingLabelHeight = pendingLabelHolder.frame.size.height;
    pendingLabelHolder.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
    pendingLabel.text = NSLocalizedString(@"Pending Comment", @"");
    
	[labelHolder addSubview:pendingLabelHolder];
    
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

    rect = commentBodyWebView.frame;
    rect.origin.y += pendingLabelHeight;
    rect.size.height -= pendingLabelHeight;
    commentBodyWebView.frame = rect;
	
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
		commentAuthorLabel.frame = rect;
		
		rect = commentAuthorUrlButton.frame;
		rect.origin.y -= pendingLabelHeight;
		commentAuthorUrlButton.frame = rect;
		
		rect = commentAuthorEmailButton.frame;
		rect.origin.y -= pendingLabelHeight;
		commentAuthorEmailButton.frame = rect;
		
		rect = commentPostTitleLabel.frame;
		rect.origin.y -= pendingLabelHeight;
		commentPostTitleLabel.frame = rect;
		
		rect = commentDateLabel.frame;
		rect.origin.y -= pendingLabelHeight;
		commentDateLabel.frame = rect;
		
		rect = commentBodyWebView.frame;
		rect.origin.y -= pendingLabelHeight;
		rect.size.height += pendingLabelHeight;
		commentBodyWebView.frame = rect;
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
	[gravatarImageView setImageWithGravatarEmail:[comment.author_email trim]];
    commentAuthorLabel.text = [comment.author trim];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateNormal];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateHighlighted];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateSelected];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateNormal];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateHighlighted];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateSelected];
    if (comment.postTitle)
        commentPostTitleLabel.text = [NSLocalizedString(@"on ", @"(Comment) on (Post Title)") stringByAppendingString:[[comment.postTitle stringByDecodingXMLCharacters] trim]];
	if(comment.dateCreated != nil)
		commentDateLabel.text = [@"" stringByAppendingString:[dateFormatter stringFromDate:comment.dateCreated]];
	else
		commentDateLabel.text = @"";
	
	NSString *htmlString;
	if (comment.content == nil)
		htmlString = [NSString stringWithFormat:@"<html><head></head><body><p>%@</p></body></html>", @"<br />"];
	else
		htmlString = [NSString stringWithFormat:@"<html><head><script> document.ontouchmove = function(event) { if (document.body.scrollHeight == document.body.clientHeight) event.preventDefault(); } </script><style type='text/css'>* { margin:0; padding:0 5px 0 0; } p { color:black; font-family:Helvetica; font-size:16px; } a { color:#21759b; text-decoration:none; }</style></head><body><p>%@</p></body></html>", [[comment.content trim] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]];
	commentBodyWebView.delegate = self;
	[commentBodyWebView loadHTMLString:htmlString baseURL:nil];

    if ([comment.status isEqualToString:@"hold"] && ![pendingLabelHolder superview]) {
		[self insertPendingLabel];
		[approveAndUnapproveButtonBar setHidden:YES];
		[deleteButtonBar setHidden:NO];
		
	} else if (![comment.status isEqualToString:@"hold"]){
		[self removePendingLabel];
		[approveAndUnapproveButtonBar setHidden:YES];
		[deleteButtonBar setHidden:NO];

    }

    [pendingApproveButton setTarget:self];
    if ([self isApprove]) {
        [pendingApproveButton setImage:[UIImage imageNamed:@"approve.png"]];
        [pendingApproveButton setAction:@selector(approveComment:)];
	} else {
        [pendingApproveButton setImage:[UIImage imageNamed:@"unapprove.png"]];
        [pendingApproveButton setAction:@selector(unApproveComment:)];
	}
    
    [segmentedControl setEnabled:[commentsViewController hasPreviousComment] forSegmentAtIndex:0];
    [segmentedControl setEnabled:[commentsViewController hasNextComment] forSegmentAtIndex:1];
}

- (void)viewURL{
	NSURL *url = [NSURL URLWithString: [self.comment.author_url trim]];
	if (url != nil) {
        WPWebViewController *webViewController;
        if (DeviceIsPad()) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        }
        [webViewController setUrl:url];
        if (DeviceIsPad())
            [self presentModalViewController:webViewController animated:YES];
        else
            [self.navigationController pushViewController:webViewController animated:YES];
	}
}

- (void)sendEmail{
	if (self.comment.author_email) {
		MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
		controller.mailComposeDelegate = self;
		NSArray *recipient = [[NSArray alloc] initWithObjects:[self.comment.author_email trim], nil];
		[controller setToRecipients: recipient];
		[controller setSubject:[NSString stringWithFormat:NSLocalizedString(@"Re: %@", @""), self.comment.postTitle]]; 
		[controller setMessageBody:[NSString stringWithFormat:NSLocalizedString(@"Hi %@,", @""), self.comment.author] isHTML:NO];
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
	if (DeviceIsPad() && (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)){
		self.navigationItem.rightBarButtonItem = nil;
	}	
	else
		self.navigationItem.rightBarButtonItem = segmentBarItem;
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
	if (inType == UIWebViewNavigationTypeLinkClicked) {
        WPWebViewController *webViewController;
        if (DeviceIsPad()) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        }
        [webViewController setUrl:[inRequest URL]];
        if (DeviceIsPad())
            [self presentModalViewController:webViewController animated:YES];
        else
            [self.navigationController pushViewController:webViewController animated:YES];
		return NO;
	}
	return YES;
}

@end
