//
//  CommentViewController.m
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import "CommentViewController.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h"
#import "WPWebViewController.h"
#import "UIImageView+Gravatar.h"
#import "SFHFKeychainUtils.h"

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

-(void)reachabilityChanged:(BOOL)reachable;
-(void)openInAppWebView:(NSURL*)url;
@end

@implementation CommentViewController {
    AMBlockToken *_reachabilityToken;
}

@synthesize replyToCommentViewController, editCommentViewController, commentsViewController, wasLastCommentPending, commentAuthorUrlButton, commentAuthorEmailButton;
@synthesize commentPostTitleButton, commentPostTitleLabel;
@synthesize comment = _comment, isVisible;
@synthesize delegate;

#pragma mark -
#pragma mark View Lifecycle

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self.comment removeObserver:self forKeyPath:@"status"];
    self.comment = nil;
    [segmentedControl release];
    [segmentBarItem release];
	[replyToCommentViewController release];
	[editCommentViewController release];
	[commentsViewController release];
	[commentAuthorUrlButton release];
	[commentAuthorEmailButton release];
	[commentPostTitleButton release];
	[commentPostTitleLabel release];
	commentBodyWebView.delegate = nil;
    [commentBodyWebView stopLoading];
    [commentBodyWebView release];
   
    [super dealloc];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidLoad];
	
    if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
        segmentedControl = [[UISegmentedControl alloc] initWithItems:
                            [NSArray arrayWithObjects:
                             [UIImage imageNamed:@"up_dim.png"],
                             [UIImage imageNamed:@"down_dim.png"],
                             nil]];
    } else {
        segmentedControl = [[UISegmentedControl alloc] initWithItems:
                            [NSArray arrayWithObjects:
                             [UIImage imageNamed:@"up.png"],
                             [UIImage imageNamed:@"down.png"],
                             nil]];        
    }
    
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    
    gravatarImageView.layer.cornerRadius = 10.0f;
    gravatarImageView.layer.masksToBounds = YES;
    
    segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	
	[self addOrRemoveSegmentedControl];
	
	self.title = NSLocalizedString(@"Comment", @"");
	
	commentBodyWebView.backgroundColor = [UIColor whiteColor];
	//hide the shadow for the UIWebView, nicked from stackoverflow.com/questions/1074320/remove-uiwebview-shadow/
	for(UIView *wview in [[[commentBodyWebView subviews] objectAtIndex:0] subviews]) { 
		if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
	}

    if (self.comment) {
        [self showComment:self.comment];
    }
    
    if ([approveButton respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        approveButton.tintColor = color;
        actionButton.tintColor = color;
        replyButton.tintColor = color;
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    if (_reachabilityToken) {
        [_comment.blog removeObserverWithBlockToken:_reachabilityToken];
        [_reachabilityToken release]; _reachabilityToken = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [approveButton release]; approveButton = nil;
    [actionButton release]; actionButton = nil;
    [replyButton release]; replyButton = nil;
    [segmentedControl release]; segmentedControl = nil;
    [gravatarImageView release]; gravatarImageView = nil;
    self.commentAuthorEmailButton = nil;
    self.commentAuthorUrlButton = nil;
	self.commentPostTitleButton = nil;
	self.commentPostTitleLabel = nil;
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

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
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
#pragma mark Reachability

- (void)reachabilityChanged:(BOOL)reachable {
    approveButton.enabled = reachable;
    replyButton.enabled = reachable;
    actionButton.enabled = reachable;
    if (reachable) {
        // Load gravatar if it wasn't loaded yet
        [gravatarImageView setImageWithGravatarEmail:[self.comment.author_email trim]];
    }
}


#pragma mark -
#pragma mark UIActionSheetDelegate methods

//not truly an ActionSheetDelegate method, but it's where we call the ActionSheet...
- (void) launchModerateMenu {
	if(self.commentsViewController.blog.isSyncingComments) {
		[self showSynchInProgressAlert];
		return;
	} 
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil
													otherButtonTitles: NSLocalizedString(@"Delete Comment", @""), NSLocalizedString(@"Mark Comment as Spam", @""), NSLocalizedString(@"Edit Comment", @""),nil];
	//otherButtonTitles: conditionalButtonTitle, NSLocalizedString(@"Mark Comment as Spam", @""),nil];
	
	actionSheet.tag = 301;
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	if (DeviceIsPad() == YES) {
        actionButton.enabled = NO;
		[actionSheet showFromBarButtonItem:actionButton animated:YES];
	} else {
		[actionSheet showInView:self.view];
	}
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate setAlertRunning:YES];
	
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
        actionButton.enabled = YES;
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
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:NO];
}


#pragma mark -
#pragma mark ReplyToCommentViewController methods
//These methods call the ReplyToCommentViewController as well as handling the "back-referenced" cancel button click
//that has to be run here given the view heirarchy...

- (void)showSynchInProgressAlert {
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
	if (self.replyToCommentViewController) {
		self.replyToCommentViewController.delegate = nil;
	}
	
	self.replyToCommentViewController = [[[ReplyToCommentViewController alloc] 
									 initWithNibName:@"ReplyToCommentViewController" 
									 bundle:nil] autorelease];
	replyToCommentViewController.delegate = self;
	replyToCommentViewController.comment = [[self.comment newReply] autorelease];
	replyToCommentViewController.title = NSLocalizedString(@"Comment Reply", @"Comment Reply view title");
	
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:replyToCommentViewController] autorelease];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navController animated:YES];
}

- (void)dismissEditViewController;
{
    [self dismissModalViewControllerAnimated:YES];
}


- (void)closeReplyViewAndSelectTheNewComment {
	[self dismissEditViewController];
    // TODO: Select new comment or dismiss comment view on iPhone
}

- (void)cancelView:(id)sender {

	//there are no changes
	if (!replyToCommentViewController.hasChanges && !editCommentViewController.hasChanges) {
		[self dismissEditViewController];
		
		if(sender == replyToCommentViewController) {			
			[replyToCommentViewController.comment remove]; //delete the empty comment
			replyToCommentViewController.comment = nil;
			
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
	
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
	
    [actionSheet release];
}

- (void)launchEditComment {
	[self showEditCommentViewWithAnimation:YES];
}


- (void)showEditCommentViewWithAnimation:(BOOL)animate {
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
	self.editCommentViewController = [[[EditCommentViewController alloc] 
									 initWithNibName:@"EditCommentViewController" 
									 bundle:nil] autorelease];
	editCommentViewController.commentViewController = self;
	editCommentViewController.comment = self.comment;
	editCommentViewController.title = NSLocalizedString(@"Edit Comment", @"");
	
	if (DeviceIsPad() == YES) {
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:editCommentViewController] autorelease];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		[self presentModalViewController:navController animated:YES];
	} else {
		[appDelegate.navigationController pushViewController:self.editCommentViewController animated:YES];
	}
}


#pragma mark -
#pragma mark ReplyToCommentViewControllerDelegate Methods

- (void)cancelReplyToCommentViewController:(id)sender {
	[self cancelView:sender];
	if (self.commentsViewController) {
//		[self.commentsViewController setReplying:NO];
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
        [self.delegate showPreviousComment];
    } else {
        [self.delegate showNextComment];
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
	
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
	
    [actionSheet release];
	
}

- (void)deleteComment:(id)sender {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(remove)];
}

- (void)approveComment:(id)sender {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(approve)];
}

- (void)unApproveComment:(id)sender {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(unapprove)];
}

- (void)spamComment:(id)sender {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(spam)];
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

- (void)moderateCommentWithSelector:(SEL)selector {
    Blog *currentBlog = self.comment.blog;
    [self.comment performSelector:selector];
    if (!DeviceIsPad()) {
        [self.navigationController popViewControllerAnimated:YES];
    }
   [[NSNotificationCenter defaultCenter] postNotificationName:kCommentsChangedNotificationName object:currentBlog];
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

    rect = commentPostTitleButton.frame;
    rect.origin.y += pendingLabelHeight;
    commentPostTitleButton.frame = rect;

	rect = commentPostTitleLabel.frame;
	rect.origin.y+= pendingLabelHeight;
	commentPostTitleLabel.frame = rect;
	
    rect = commentDateLabel.frame;
    rect.origin.y += pendingLabelHeight;
    commentDateLabel.frame = rect;

    rect = commentBodyWebView.frame;
    rect.origin.y += pendingLabelHeight;
    rect.size.height -= pendingLabelHeight;
    commentBodyWebView.frame = rect;
	
	rect = labelHolder.frame;
	rect.size.height += pendingLabelHeight;
	labelHolder.frame = rect;
	
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
		
		rect = commentPostTitleButton.frame;
		rect.origin.y -= pendingLabelHeight;
		commentPostTitleButton.frame = rect;

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
		
		rect = labelHolder.frame;
		rect.size.height -= pendingLabelHeight;
		labelHolder.frame = rect;
	}
}


#pragma mark -
#pragma mark Public Methods

- (void)setComment:(Comment *)comment {
    if ([_comment isEqual:comment]) {
        return;
    }
    if (_reachabilityToken) {
        [_comment.blog removeObserverWithBlockToken:_reachabilityToken];
    }

    [_comment removeObserver:self forKeyPath:@"status"];
    [self willChangeValueForKey:@"comment"];
    [_comment release];
    _comment = [comment retain];
    [self didChangeValueForKey:@"comment"];
    [_comment addObserver:self forKeyPath:@"status" options:0 context:nil];

    _reachabilityToken = [[comment.blog addObserverForKeyPath:@"reachable" task:^(id obj, NSDictionary *change) {
        Blog *blog = (Blog *)obj;
        [self reachabilityChanged:blog.reachable];
    }] retain];

    [self reachabilityChanged:comment.blog.reachable];
}

- (void)showComment:(Comment *)comment {
    self.comment = comment;
    static NSDateFormatter *dateFormatter = nil;

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
	[gravatarImageView setImageWithGravatarEmail:[comment.author_email trim]];
    commentAuthorLabel.text = [[comment.author stringByDecodingXMLCharacters] trim];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateNormal];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateHighlighted];
	[commentAuthorUrlButton setTitle:[comment.author_url trim] forState:UIControlStateSelected];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateNormal];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateHighlighted];
	[commentAuthorEmailButton setTitle:[comment.author_email trim] forState:UIControlStateSelected];
    if (comment.author_email && ![comment.author_email isEqualToString:@""] && [MFMailComposeViewController canSendMail]) {
        commentAuthorEmailButton.enabled = YES;
        [commentAuthorEmailButton setTitleColor:[UIColor colorWithRed:0.1289f green:0.457f blue:0.6054f alpha:1.0f] forState:UIControlStateNormal];
    } else {
        commentAuthorEmailButton.enabled = NO;
        [commentAuthorEmailButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    if (comment.postTitle) {
		NSString *postTitleOn = NSLocalizedString(@"on ", @"(Comment) on (Post Title)");
		
		NSString *postTitle = [[comment.postTitle stringByDecodingXMLCharacters] trim];
		
		CGSize sz = [postTitleOn sizeWithFont:commentPostTitleLabel.font];
		CGRect frm = commentPostTitleLabel.frame;
		CGFloat widthDiff = frm.size.width - sz.width;

		frm.size.width = sz.width;
		commentPostTitleLabel.frame = frm;
		
		frm = commentPostTitleButton.frame;
		frm.origin.x = frm.origin.x - widthDiff;
		frm.size.width = frm.size.width + widthDiff;
		commentPostTitleButton.frame = frm;
		
		commentPostTitleLabel.text = postTitleOn;
		[commentPostTitleButton setTitle:postTitle forState:UIControlStateNormal];
	}
	if(comment.dateCreated != nil)
		commentDateLabel.text = [@"" stringByAppendingString:[dateFormatter stringFromDate:comment.dateCreated]];
	else
		commentDateLabel.text = @"";
	
	NSString *htmlString;
	if (comment.content == nil)
		htmlString = [NSString stringWithFormat:@"<html><head></head><body><p>%@</p></body></html>", @"<br />"];
	else
		htmlString = [NSString stringWithFormat:@"<html><head><style type='text/css'>* { margin:0; padding:0 5px 0 0; } p { color:black; font-family:Helvetica; font-size:16px; } a { color:#21759b; text-decoration:none; }</style></head><body><p>%@</p></body></html>", [[comment.content trim] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]];
	commentBodyWebView.delegate = self;
	[commentBodyWebView loadHTMLString:htmlString baseURL:nil];

    if ([comment.status isEqualToString:@"hold"] && ![pendingLabelHolder superview]) {
		[self insertPendingLabel];		
	} else if (![comment.status isEqualToString:@"hold"]){
		[self removePendingLabel];
    }

    [approveButton setTarget:self];
    if ([self isApprove]) {
        [approveButton setImage:[UIImage imageNamed:@"approve.png"]];
        [approveButton setAction:@selector(approveComment:)];
	} else {
        [approveButton setImage:[UIImage imageNamed:@"unapprove.png"]];
        [approveButton setAction:@selector(unApproveComment:)];
	}
    
    [segmentedControl setEnabled:[self.delegate hasPreviousComment] forSegmentAtIndex:0];
    [segmentedControl setEnabled:[self.delegate hasNextComment] forSegmentAtIndex:1];
}

- (IBAction)viewURL{
	NSURL *url = [NSURL URLWithString: [self.comment.author_url trim]];
    [self openInAppWebView:url];
}

- (void)sendEmail{
	if (self.comment.author_email && [MFMailComposeViewController canSendMail]) {
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

- (void)openInAppWebView:(NSURL*)url {
    Blog *blog = [[self comment] blog];
    
	if (url != nil && [[url description] length] > 0) {
        WPWebViewController *webViewController;
        if (DeviceIsPad()) {
            webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
        }
        else {
            webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
        }
        [webViewController setUrl:url];

        if (blog.isPrivate && [blog isWPcom]) {
            NSError *error;
            webViewController.username = blog.username;
            webViewController.password = [SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:@"WordPress.com" error:&error];
        }
        
        if ( self.panelNavigationController  )
            [self.panelNavigationController pushViewController:webViewController fromViewController:self animated:YES];
	}
}

- (IBAction)handlePostTitleButtonTapped:(id)sender {
    [self openInAppWebView:[NSURL URLWithString:self.comment.link]];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
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

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
	if (inType == UIWebViewNavigationTypeLinkClicked) {
        [self openInAppWebView:[inRequest URL]];
		return NO;
	}
	return YES;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([self isViewLoaded]) {
        [self showComment:self.comment];
    }
}

@end
