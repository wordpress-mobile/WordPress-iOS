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
#import "UIColor+Helpers.h"
#import "UIBarButtonItem+Styled.h"

#define COMMENT_BODY_TOP        100
#define COMMENT_BODY_MAX_HEIGHT 4000
#define COMMENT_BODY_PADDING 20

#define kCustomButtonHeight     30.0

@interface CommentViewController (Private)
- (void)showSynchInProgressAlert;
- (BOOL)isConnectedToHost;
- (BOOL)isApprove;
- (void)moderateCommentWithSelector:(SEL)selector;
- (void)cancel;
- (void)discard;

- (void)showReplyToCommentViewWithAnimation:(BOOL)animate;
- (void)showEditCommentViewWithAnimation:(BOOL)animate;
- (void)insertPendingLabel;
- (void)removePendingLabel;

- (void)launchReplyToComments;

-(void)reachabilityChanged:(BOOL)reachable;
-(void)openInAppWebView:(NSURL*)url;
@end

@implementation CommentViewController {
    AMBlockToken *_reachabilityToken;
}

@synthesize replyToCommentViewController, editCommentViewController, commentsViewController, wasLastCommentPending, commentAuthorUrlButton, commentAuthorEmailButton;
@synthesize commentPostTitleButton, commentPostTitleLabel;
@synthesize comment = _comment, isVisible;
@synthesize delegate, toolbar;

#pragma mark -
#pragma mark View Lifecycle

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];

    [self.comment removeObserver:self forKeyPath:@"status"];
    if (_reachabilityToken) {
        [_comment.blog removeObserverWithBlockToken:_reachabilityToken];
        _reachabilityToken = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.delegate = nil;
	commentBodyWebView.delegate = nil;
    [commentBodyWebView stopLoading];
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
    
    segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	
	[self addOrRemoveSegmentedControl];
	
	self.title = NSLocalizedString(@"Comment", @"");
	
	commentBodyWebView.backgroundColor = [UIColor whiteColor];
	//hide the shadow for the UIWebView, nicked from stackoverflow.com/questions/1074320/remove-uiwebview-shadow/
	for(UIView *wview in [[[commentBodyWebView subviews] objectAtIndex:0] subviews]) { 
		if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
	}
    
    //toolbar items
    UIBarButtonItem *approveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_approve"] style:UIBarButtonItemStylePlain target:self action:@selector(approveComment)];
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_delete"] style:UIBarButtonItemStylePlain target:self action:@selector(launchDeleteCommentActionSheet)];
    UIBarButtonItem *spamButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_flag"] style:UIBarButtonItemStylePlain target:self action:@selector(spamComment)];
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_edit"] style:UIBarButtonItemStylePlain target:self action:@selector(launchEditComment)];
    UIBarButtonItem *replyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_reply"] style:UIBarButtonItemStylePlain target:self action:@selector(launchReplyToComments)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolbar setItems: [NSArray arrayWithObjects:approveButton, spacer, deleteButton, spacer, spamButton, spacer, editButton, spacer, replyButton, nil]];
    
    if (self.comment) {
        [self showComment:self.comment];
        [self reachabilityChanged:self.comment.blog.reachable];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    if (_reachabilityToken) {
        [_comment.blog removeObserverWithBlockToken:_reachabilityToken];
         _reachabilityToken = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
     segmentedControl = nil;
     gravatarImageView = nil;
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark Reachability

- (void)reachabilityChanged:(BOOL)reachable {
    
    for (int i=0;i < [[toolbar items] count]; i++) {
        if ([[[toolbar items] objectAtIndex:i] isKindOfClass:[UIBarButtonItem class]]) {
            UIBarButtonItem *button = [[toolbar items] objectAtIndex:i];
            button.enabled = reachable;
        }
    }
    if (reachable) {
        // Load gravatar if it wasn't loaded yet
        [gravatarImageView setImageWithGravatarEmail:[self.comment.author_email trim]];
    }
}


#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

//handle action sheet from trash button
	if ([actionSheet tag] == 501) {
		if (buttonIndex == 0) {
			[self deleteComment];
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
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:NO];
    isShowingActionSheet = NO;
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
	
	self.replyToCommentViewController = [[ReplyToCommentViewController alloc] 
									 initWithNibName:@"ReplyToCommentViewController" 
									 bundle:nil];
	replyToCommentViewController.delegate = self;
	replyToCommentViewController.comment = [self.comment newReply];
	replyToCommentViewController.title = NSLocalizedString(@"Comment Reply", @"Comment Reply view title");
	
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:replyToCommentViewController];
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
}

- (void)cancelView:(id)sender {

	//there are no changes
	if (!replyToCommentViewController.hasChanges && !editCommentViewController.hasChanges) {
		[self dismissEditViewController];
		
		if(sender == replyToCommentViewController) {			
			[replyToCommentViewController.comment remove]; //delete the empty comment
			replyToCommentViewController.comment = nil;
			
			if (IS_IPAD == YES)  //an half-patch for #790: sometimes the modal view is not disposed when click on cancel. 
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
        if (IS_IPAD)
            [actionSheet showFromBarButtonItem:replyToCommentViewController.navigationItem.leftBarButtonItem animated:YES];
        else
            [actionSheet showInView:replyToCommentViewController.view];
	}else if (editCommentViewController.hasChanges) {
        if (IS_IPAD)
            [actionSheet showFromBarButtonItem:editCommentViewController.navigationItem.leftBarButtonItem animated:YES];
        else
            [actionSheet showInView:editCommentViewController.view];
	}
	isShowingActionSheet = YES;
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
	
}

- (void)launchEditComment {
	[self showEditCommentViewWithAnimation:YES];
}


- (void)showEditCommentViewWithAnimation:(BOOL)animate {
	self.editCommentViewController = [[EditCommentViewController alloc] 
									 initWithNibName:@"EditCommentViewController" 
									 bundle:nil];
	editCommentViewController.commentViewController = self;
	editCommentViewController.comment = self.comment;
	editCommentViewController.title = NSLocalizedString(@"Edit Comment", @"");

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editCommentViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navController animated:animate];
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
    if (!isShowingActionSheet) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this comment?", @"")
                                                                 delegate:self 
                                                        cancelButtonTitle:nil 
                                                   destructiveButtonTitle:NSLocalizedString(@"Delete", @"")
                                                        otherButtonTitles:NSLocalizedString(@"Cancel", @""), nil];
        actionSheet.tag = 501;
        actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
        if (IS_IPAD)
            [actionSheet showFromBarButtonItem:[[toolbar items] objectAtIndex: 2] animated:YES];
        else 
            [actionSheet showInView:self.view];
        isShowingActionSheet = YES;
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate setAlertRunning:YES];
        
    }
}

- (void)deleteComment {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(remove)];
}

- (void)approveComment {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(approve)];
}

- (void)unApproveComment {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self moderateCommentWithSelector:@selector(unapprove)];
}

- (void)spamComment {
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.comment performSelector:selector];
#pragma clang diagnostic pop
    if (!IS_IPAD) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.panelNavigationController popToRootViewControllerAnimated:YES];
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
    pendingLabelHolder.backgroundColor = [UIColor UIColorFromHex:0xf6f6dc alpha:1.0f];
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
    _comment = comment;
    [self didChangeValueForKey:@"comment"];
    [_comment addObserver:self forKeyPath:@"status" options:0 context:nil];

    _reachabilityToken = [comment.blog addObserverForKeyPath:@"reachable" task:^(id obj, NSDictionary *change) {
        Blog *blog = (Blog *)obj;
        [self reachabilityChanged:blog.reachable];
    }];

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
		htmlString = [NSString stringWithFormat:@"<html><head><meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1\"><style type='text/css'>* { margin:0; padding:0 5px 0 0; } p { color:black; font-family:Helvetica; font-size:16px; } a { color:#21759b; text-decoration:none; }</style></head><body><p>%@</p></body></html>", [[comment.content trim] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]];
	commentBodyWebView.delegate = self;
	[commentBodyWebView loadHTMLString:htmlString baseURL:nil];

    if ([comment.status isEqualToString:@"hold"] && ![pendingLabelHolder superview]) {
		[self insertPendingLabel];		
	} else if (![comment.status isEqualToString:@"hold"]){
		[self removePendingLabel];
    }

    if ([[UIBarButtonItem class] respondsToSelector: @selector(appearance)]) {
        UIButton *button = (UIButton*)[[[toolbar items] objectAtIndex:0] customView];
        if (button != nil) {
            if ([self isApprove]) {
                [button setImage:[UIImage imageNamed:@"toolbar_approve"] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(approveComment) forControlEvents:UIControlEventTouchUpInside];
                
            } else {
                [button setImage:[UIImage imageNamed:@"toolbar_unapprove"] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(unApproveComment) forControlEvents:UIControlEventTouchUpInside];
            }
        }
    } else {
        UIBarButtonItem *approveButton = [[toolbar items] objectAtIndex:0];
        if (approveButton != nil) {
            [approveButton setTarget:self];
            if ([self isApprove]) {
                [approveButton setImage:[UIImage imageNamed:@"toolbar_approve"]];
                [approveButton setAction:@selector(approveComment)];
            } else {
                [approveButton setImage:[UIImage imageNamed:@"toolbar_unapprove"]];
                [approveButton setAction:@selector(unApproveComment)];
            }
        }
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
	}
}

- (void)openInAppWebView:(NSURL*)url {
    Blog *blog = [[self comment] blog];
    
	if (url != nil && [[url description] length] > 0) {
        WPWebViewController *webViewController;
        if (IS_IPAD) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
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
	if (IS_IPAD && (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)){
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
