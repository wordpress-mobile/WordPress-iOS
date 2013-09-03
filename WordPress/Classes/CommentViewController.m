//
//  CommentViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/22/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CommentViewController.h"
#import "UIImageView+Gravatar.h"
#import "NSString+XMLExtensions.h"
#import "Comment.h"
#import "CommentsViewController.h"
#import "ReplyToCommentViewController.h"
#import "EditCommentViewController.h"
#import "WPWebViewController.h"

@interface CommentViewController () <UIWebViewDelegate, ReplyToCommentViewControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    ReplyToCommentViewController *_replyToCommentViewController;
    EditCommentViewController *_editCommentViewController;
    BOOL _isShowingActionSheet;
    AMBlockToken *_reachabilityToken;
    NSLayoutConstraint *_authorSiteHeightConstraint;
}

@property (nonatomic, strong) IBOutlet UIImageView *gravatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *authorNameLabel;
@property (nonatomic, strong) IBOutlet UIButton *authorSiteButton;
@property (nonatomic, strong) IBOutlet UIButton *authorEmailButton;
@property (nonatomic, strong) IBOutlet UILabel *postTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIWebView *commentWebview;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *approveButtonPlaceholder;

@end

@implementation CommentViewController

CGFloat const CommentViewDeletePromptActionSheetTag = 501;
CGFloat const CommentViewReplyToCommentViewControllerHasChangesActionSheetTag = 401;
CGFloat const CommentViewEditCommentViewControllerHasChangesActionSheetTag = 601;
CGFloat const CommentViewApproveButtonTag = 700;
CGFloat const CommentViewUnapproveButtonTag = 701;

- (void)dealloc {
    WPFLogMethod();
    
    [self.comment removeObserver:self forKeyPath:@"status"];
    if (_reachabilityToken) {
        [_comment.blog removeObserverWithBlockToken:_reachabilityToken];
        _reachabilityToken = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	self.commentWebview.delegate = nil;
    [self.commentWebview stopLoading];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [WPStyleGuide readGrey];
    self.authorNameLabel.font = [WPStyleGuide postTitleFont];
    self.authorSiteButton.titleLabel.font = [WPStyleGuide subtitleFont];
    [self.authorSiteButton setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateNormal];
    self.authorEmailButton.titleLabel.font = [WPStyleGuide subtitleFont];
    [self.authorEmailButton setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateNormal];
    self.postTitleLabel.font = [WPStyleGuide subtitleFont];
    self.dateLabel.font = [WPStyleGuide subtitleFont];
    self.commentWebview.backgroundColor = [WPStyleGuide readGrey];
    
    [self.toolbar setBarTintColor:[WPStyleGuide littleEddieGrey]];
    self.toolbar.translucent = NO;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedPostTitle)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.postTitleLabel addGestureRecognizer:gestureRecognizer];
    
    if (self.comment) {
        [self showComment:self.comment];
        [self reachabilityChanged:self.comment.blog.reachable];
    }
}


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

- (void)cancelView:(id)sender {
	//there are no changes
	if (!_replyToCommentViewController.hasChanges && !_editCommentViewController.hasChanges) {
		[self dismissEditViewController];
		
		if(sender == _replyToCommentViewController) {
			[_replyToCommentViewController.comment remove]; //delete the empty comment
			_replyToCommentViewController.comment = nil;
			
			if (IS_IPAD == YES) { //an half-patch for #790: sometimes the modal view is not disposed when click on cancel.
                [self dismissViewControllerAnimated:YES completion:nil];
            }
			
		}
        
		return;
	}
	
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"")
															 delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
											   destructiveButtonTitle:NSLocalizedString(@"Discard", @"")
													otherButtonTitles:nil];

    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;

	if (_replyToCommentViewController.hasChanges) {
		actionSheet.tag = CommentViewReplyToCommentViewControllerHasChangesActionSheetTag;
        [actionSheet showInView:_replyToCommentViewController.view];
    } else if (_editCommentViewController.hasChanges) {
		actionSheet.tag = CommentViewEditCommentViewControllerHasChangesActionSheetTag;
        [actionSheet showInView:_editCommentViewController.view];
    }
    
	_isShowingActionSheet = YES;
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    [self.view removeConstraint:_authorSiteHeightConstraint];
    if ([[self.authorSiteButton titleForState:UIControlStateNormal] length] == 0) {
        _authorSiteHeightConstraint = [NSLayoutConstraint constraintWithItem:self.authorSiteButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0.0 constant:8];
        [self.view addConstraint:_authorSiteHeightConstraint];
    }
}

#pragma mark - Private Methods

- (void)dismissEditViewController;
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showComment:(Comment *)comment
{
    self.comment = comment;
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
    
    [self.gravatarImageView setImageWithGravatarEmail:[self.comment.author_email trim] fallbackImage:[UIImage imageNamed:@"comment-default-gravatar-image"]];
    
    self.authorNameLabel.text = [[self.comment.author stringByDecodingXMLCharacters] trim];

    [self.authorSiteButton setTitle:[self.comment.author_url trim] forState:UIControlStateNormal];

    [self.authorEmailButton setTitle:[self.comment.author_email trim] forState:UIControlStateNormal];
    UIColor *textColor;
    if (![MFMailComposeViewController canSendMail]) {
        textColor = [UIColor blackColor];
    } else {
        textColor = [WPStyleGuide newKidOnTheBlockBlue];
    }
    [self.authorEmailButton setTitleColor:textColor forState:UIControlStateNormal];

    self.postTitleLabel.attributedText = [self postTitleString];
    
    if(self.comment.dateCreated != nil) {
        self.dateLabel.text = [@"" stringByAppendingString:[dateFormatter stringFromDate:self.comment.dateCreated]];
    }
    else {
        self.dateLabel.text = @"";
    }
    
    NSString *htmlString;
	if (self.comment.content == nil) {
		htmlString = [NSString stringWithFormat:@"<html><head></head><body><p>%@</p></body></html>", @"<br />"];
    }
	else {
		htmlString = [NSString stringWithFormat:@"<html><head><meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1\"><style type='text/css'>* { margin:0; padding:0 5px 0 0; } p { color:black; font-family:OpenSans; font-size:16px; line-height: 1.4} b { font-family:OpenSans-Bold } i { font-family:OpenSans-Italic } a { color:#21759b; text-decoration:none; } body { background-color: #dddddd }</style></head><body><p>%@</p></body></html>", [[self.comment.content trim] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]];
    }
	self.commentWebview.delegate = self;
	[self.commentWebview loadHTMLString:htmlString baseURL:nil];
    
    if ([self.comment.status isEqualToString:@"approve"]) {
        self.approveButtonPlaceholder.image = [UIImage imageNamed:@"icon-comments-unapprove"];
        self.approveButtonPlaceholder.tag = CommentViewUnapproveButtonTag;
    } else {
        self.approveButtonPlaceholder.image = [UIImage imageNamed:@"icon-comments-approve"];
        self.approveButtonPlaceholder.tag = CommentViewApproveButtonTag;
    }
}

- (NSAttributedString *)postTitleString
{
    NSString *postTitle;
    if (self.comment.postTitle != nil) {
        postTitle = [[self.comment.postTitle stringByDecodingXMLCharacters] trim];
    } else {
        postTitle = NSLocalizedString(@"(No Title)", nil);
    }
    NSString *postTitleOn = NSLocalizedString(@"on ", @"(Comment) on (Post Title)");
    NSString *combinedString = [postTitleOn stringByAppendingString:postTitle];
    NSRange titleRange = [combinedString rangeOfString:postTitle];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:combinedString];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide newKidOnTheBlockBlue] range:titleRange];
    return attributedString;
}

- (void)discard {
    _replyToCommentViewController.navigationItem.rightBarButtonItem = nil;
	[self dismissEditViewController];
}


#pragma mark - IBAction Methods

- (IBAction)viewURL{
	NSURL *url = [NSURL URLWithString: [self.comment.author_url trim]];
    [self openInAppWebView:url];
}

- (IBAction)handleApproveOrUnapproveComment:(id)sender
{
    UIBarButtonItem *barButton = sender;
    if (barButton.tag == CommentViewApproveButtonTag) {
        [self approveComment];
    } else {
        [self unApproveComment];
    }
}

- (IBAction)sendEmail{
	if (self.comment.author_email && [MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
		controller.mailComposeDelegate = self;
		NSArray *recipient = [[NSArray alloc] initWithObjects:[self.comment.author_email trim], nil];
		[controller setToRecipients: recipient];
		[controller setSubject:[NSString stringWithFormat:NSLocalizedString(@"Re: %@", @""), self.comment.postTitle]];
		[controller setMessageBody:[NSString stringWithFormat:NSLocalizedString(@"Hi %@,", @""), self.comment.author] isHTML:NO];
        [self presentViewController:controller animated:YES completion:nil];
	}
}

- (void)handlePostTitleButtonTapped:(id)sender {
    [self openInAppWebView:[NSURL URLWithString:self.comment.link]];
}

- (IBAction)launchDeleteCommentActionSheet {
    if (!_isShowingActionSheet) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this comment?", @"")
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:NSLocalizedString(@"Delete", @"")
                                                        otherButtonTitles:NSLocalizedString(@"Cancel", @""), nil];
        actionSheet.tag = CommentViewDeletePromptActionSheetTag;
        actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
        [actionSheet showInView:self.view];
        
        _isShowingActionSheet = YES;
        
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate setAlertRunning:YES];
    }
}

#pragma mark - UIActionSheet Delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == CommentViewDeletePromptActionSheetTag) {
        [self processDeletePromptActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    } else if (actionSheet.tag == CommentViewReplyToCommentViewControllerHasChangesActionSheetTag) {
        [self processReplyToCommentViewHasChangesActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    } else if (actionSheet.tag == CommentViewEditCommentViewControllerHasChangesActionSheetTag) {
        [self processEditCommentHasChangesActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    
    _isShowingActionSheet = NO;
}

- (void)processDeletePromptActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self deleteComment];
    }
}

- (void)processReplyToCommentViewHasChangesActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if (_replyToCommentViewController.hasChanges) {
            _replyToCommentViewController.hasChanges = NO;
            [_replyToCommentViewController.comment remove];
        }
        [self discard];
    }
}

- (void)processEditCommentHasChangesActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        _editCommentViewController.hasChanges = NO;
        [self discard];
    }
}

#pragma mark MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Reachability

- (void)reachabilityChanged:(BOOL)reachable {
    for (int i=0; i < [[self.toolbar items] count]; i++) {
        if ([[[self.toolbar items] objectAtIndex:i] isKindOfClass:[UIBarButtonItem class]]) {
            UIBarButtonItem *button = [[self.toolbar items] objectAtIndex:i];
            button.enabled = reachable;
        }
    }
    if (reachable) {
        // Load gravatar if it wasn't loaded yet
        [self.gravatarImageView setImageWithGravatarEmail:[self.comment.author_email trim] fallbackImage:[UIImage imageNamed:@"comment-default-gravatar-image"]];
    }
}


#pragma mark UIWebView Delegate Methods

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
	if (inType == UIWebViewNavigationTypeLinkClicked) {
        [self openInAppWebView:[inRequest URL]];
		return NO;
	}
	return YES;
}

- (void)openInAppWebView:(NSURL*)url {
    Blog *blog = [[self comment] blog];
    
	if ([[url description] length] > 0) {
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        webViewController.url = url;
        
        if (blog.isPrivate && [blog isWPcom]) {
            webViewController.username = blog.username;
            webViewController.password = blog.password;
        }
        
        if (self.panelNavigationController) {
            [self.panelNavigationController pushViewController:webViewController fromViewController:self animated:YES];
        }
	}
}

#pragma mark - Comment Moderation Methods

- (void)deleteComment {
    WPFLogMethod();
    [self.comment removeObserver:self forKeyPath:@"status"];
    [self moderateCommentWithSelector:@selector(remove)];
    if (IS_IPAD) {
        [self.panelNavigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)approveComment {
    WPFLogMethod();
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailApprove];
    [self moderateCommentWithSelector:@selector(approve)];
}

- (void)unApproveComment {
    WPFLogMethod();
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailUnapprove];
    [self moderateCommentWithSelector:@selector(unapprove)];
}

- (IBAction)spamComment {
    WPFLogMethodParam(NSStringFromSelector(_cmd));
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailFlagAsSpam];
    [self.comment removeObserver:self forKeyPath:@"status"];
    [self moderateCommentWithSelector:@selector(spam)];
    if (IS_IPAD) {
        [self.panelNavigationController popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)launchEditComment {
    WPFLogMethod();
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailEditComment];
	[self showEditCommentViewWithAnimation:YES];
}

- (IBAction)launchReplyToComments {
	if(self.commentsViewController.blog.isSyncingComments) {
		[self showSyncInProgressAlert];
	} else {
        [WPMobileStats trackEventForWPCom:StatsEventCommentDetailClickedReplyToComment];
		[self showReplyToCommentViewWithAnimation:YES];
	}
}

- (void)showReplyToCommentViewWithAnimation:(BOOL)animate {
	if (_replyToCommentViewController) {
		_replyToCommentViewController.delegate = nil;
	}
	
	_replyToCommentViewController = [[ReplyToCommentViewController alloc]
                                         initWithNibName:@"ReplyToCommentViewController"
                                         bundle:nil];
	_replyToCommentViewController.delegate = self;
	_replyToCommentViewController.comment = [self.comment newReply];
	_replyToCommentViewController.title = NSLocalizedString(@"Comment Reply", @"Comment Reply view title");
	
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_replyToCommentViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showEditCommentViewWithAnimation:(BOOL)animate {
	_editCommentViewController = [[EditCommentViewController alloc]
                                      initWithNibName:@"EditCommentViewController"
                                      bundle:nil];
	_editCommentViewController.commentViewController = self;
	_editCommentViewController.comment = self.comment;
	_editCommentViewController.title = NSLocalizedString(@"Edit Comment", @"");
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_editCommentViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:animate completion:nil];
}


- (void)moderateCommentWithSelector:(SEL)selector {
    Blog *currentBlog = self.comment.blog;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.comment performSelector:selector];
#pragma clang diagnostic pop
    if (!IS_IPAD) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommentsChangedNotificationName object:currentBlog];
}

- (void)showSyncInProgressAlert {
	//the blog is using the network connection and cannot be stoped, show a message to the user
	UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
																  message:NSLocalizedString(@"The blog is syncing with the server. Please try later.", @"")
																 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
	[blogIsCurrentlyBusy show];
}

#pragma mark -
#pragma mark ReplyToCommentViewControllerDelegate Methods

- (void)cancelReplyToCommentViewController:(id)sender {
	[self cancelView:sender];
}

- (void)closeReplyViewAndSelectTheNewComment {
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailRepliedToComment];
	[self dismissEditViewController];
}

#pragma mark - Gesture Recognizers

- (void)tappedPostTitle
{
    [self handlePostTitleButtonTapped:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([self isViewLoaded]) {
        [self showComment:self.comment];
    }
}

@end
