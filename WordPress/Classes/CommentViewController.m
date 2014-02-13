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
#import "CommentsViewController.h"
#import "Comment.h"
#import "EditCommentViewController.h"
#import "WPWebViewController.h"
#import "InlineComposeView.h"
#import "ContextManager.h"

@interface CommentViewController () <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, InlineComposeViewDelegate> {
    EditCommentViewController *_editCommentViewController;
    BOOL _isShowingActionSheet;
    AMBlockToken *_reachabilityToken;
    NSLayoutConstraint *_authorSiteHeightConstraint;
}

@property (nonatomic, weak) IBOutlet UIImageView *gravatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *authorNameLabel;
@property (nonatomic, weak) IBOutlet UIButton *authorSiteButton;
@property (nonatomic, weak) IBOutlet UIButton *authorEmailButton;
@property (nonatomic, weak) IBOutlet UILabel *postTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UIWebView *commentWebview;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *trashButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *approveButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *spamButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *replyButton;

@property (nonatomic, strong) InlineComposeView *inlineComposeView;

@property (nonatomic, strong) Comment *reply;

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

    self.reply = nil;
    self.inlineComposeView.delegate = nil;
    self.inlineComposeView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.authorNameLabel.font = [WPStyleGuide postTitleFont];
    self.authorSiteButton.titleLabel.font = [WPStyleGuide subtitleFont];
    [self.authorSiteButton setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateNormal];
    self.authorEmailButton.titleLabel.font = [WPStyleGuide subtitleFont];
    [self.authorEmailButton setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateNormal];
    self.postTitleLabel.font = [WPStyleGuide subtitleFont];
    self.dateLabel.font = [WPStyleGuide subtitleFont];

    self.navigationController.toolbar.translucent = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[_trashButton, flexibleSpace, _approveButton, flexibleSpace, _spamButton, flexibleSpace, _editButton, flexibleSpace, _replyButton] animated:NO];
    
    self.navigationController.toolbar.barTintColor = [WPStyleGuide littleEddieGrey];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedPostTitle)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.postTitleLabel addGestureRecognizer:gestureRecognizer];

    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    self.inlineComposeView.delegate = self;

    [self.view addSubview:self.inlineComposeView];
    if (self.comment) {
        [self showComment:self.comment];
        [self reachabilityChanged:self.comment.blog.reachable];
        self.reply = [self.comment restoreReply];
        self.inlineComposeView.text = self.reply.content;
   }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
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
	if (!_editCommentViewController.hasChanges) {
		[self dismissEditViewController];

		return;
	}

	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"")
															 delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
											   destructiveButtonTitle:NSLocalizedString(@"Discard", @"")
													otherButtonTitles:nil];

    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;

	if (_editCommentViewController.hasChanges) {
		actionSheet.tag = CommentViewEditCommentViewControllerHasChangesActionSheetTag;
        [actionSheet showInView:_editCommentViewController.view];
    }

	_isShowingActionSheet = YES;
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
		htmlString = [NSString stringWithFormat:@"<html><head><meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1\"><style type='text/css'>* { margin:0; padding:0 5px 0 0; } p { color:black; font-family:OpenSans; font-size:16px; line-height: 1.4} b { font-family:OpenSans-Bold } i { font-family:OpenSans-Italic } a { color:#21759b; text-decoration:none; }</style></head><body><p>%@</p></body></html>", [[self.comment.content trim] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]];
    }
	self.commentWebview.delegate = self;
	[self.commentWebview loadHTMLString:htmlString baseURL:nil];
    
    if ([self.comment.status isEqualToString:@"approve"]) {
        self.approveButton.image = [UIImage imageNamed:@"icon-comments-unapprove"];
        self.approveButton.tag = CommentViewUnapproveButtonTag;
    } else {
        self.approveButton.image = [UIImage imageNamed:@"icon-comments-approve"];
        self.approveButton.tag = CommentViewApproveButtonTag;
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
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                   destructiveButtonTitle:NSLocalizedString(@"Delete", @"")
                                                        otherButtonTitles:nil];
        actionSheet.tag = CommentViewDeletePromptActionSheetTag;
        actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
        [actionSheet showFromToolbar:self.navigationController.toolbar];
        
        _isShowingActionSheet = YES;
    }
}

#pragma mark - UIActionSheet Delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == CommentViewDeletePromptActionSheetTag) {
        [self processDeletePromptActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
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
    for (int i=0; i < [self.navigationController.toolbar.items count]; i++) {
        if ([self.navigationController.toolbar.items[i] isKindOfClass:[UIBarButtonItem class]]) {
            UIBarButtonItem *button = self.navigationController.toolbar.items[i];
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
        
        [self.navigationController pushViewController:webViewController animated:YES];
	}
}

#pragma mark - Comment Moderation Methods

- (void)deleteComment {
    WPFLogMethod();
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailDelete];
    [self.comment removeObserver:self forKeyPath:@"status"];
    [self moderateCommentWithSelector:@selector(remove)];
    if (IS_IPAD) {
        [self.navigationController popToRootViewControllerAnimated:YES];
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
        [self.navigationController popToRootViewControllerAnimated:YES];
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
        [self.inlineComposeView displayComposer];
	}
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
    [WPError showAlertWithTitle:NSLocalizedString(@"Info", @"Info alert title") message:NSLocalizedString(@"The blog is syncing with the server. Please try later.", @"") withSupportButton:NO];
	//the blog is using the network connection and cannot be stoped, show a message to the user
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

#pragma mark - InlineComposeViewDelegate methods

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text {

    self.reply.content = text;
    // try to save it

    [[ContextManager sharedInstance] saveContext:self.reply.managedObjectContext];

    [self.inlineComposeView clearText];
    [self.inlineComposeView dismissComposer];

    self.reply.status = CommentStatusApproved;

    // upload with success saves the reply with the published status when successfull
    [self.reply uploadWithSuccess:^{
        // the current modal experience shows success by dismissising the editor
        // ideally we switch to an optimistic experience
    } failure:^(NSError *error) {
        // reset to draft status, AppDelegate automatically shows UIAlert when comment fails
        self.reply.status = CommentStatusDraft;

        DDLogError(@"Could not reply to comment: %@", error);
    }];
}

// when the reply changes, save it to the comment
- (void)textViewDidChange:(UITextView *)textView {
    self.reply.content = self.inlineComposeView.text;
    [[ContextManager sharedInstance] saveContext:self.reply.managedObjectContext];
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
