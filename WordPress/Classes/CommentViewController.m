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
#import "CommentView.h"
#import "InlineComposeView.h"
#import "ContextManager.h"
#import "WPFixedWidthScrollView.h"
#import "WPTableViewCell.h"

CGFloat const CommentViewDeletePromptActionSheetTag = 501;
CGFloat const CommentViewReplyToCommentViewControllerHasChangesActionSheetTag = 401;
CGFloat const CommentViewEditCommentViewControllerHasChangesActionSheetTag = 601;
CGFloat const CommentViewApproveButtonTag = 700;
CGFloat const CommentViewUnapproveButtonTag = 701;

@interface CommentViewController () <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, InlineComposeViewDelegate, WPContentViewDelegate> {
}

@property (nonatomic, strong) CommentView *commentView;
@property (nonatomic, strong) UIButton *trashButton;
@property (nonatomic, strong) UIButton *approveButton;
@property (nonatomic, strong) UIButton *spamButton;
@property (nonatomic, strong) UIBarButtonItem *editButton;
@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) Comment *reply;
@property (nonatomic, strong) EditCommentViewController *editCommentViewController;
@property (nonatomic, assign) BOOL isShowingActionSheet;
@property (nonatomic, assign) BOOL transientReply;

@end

@implementation CommentViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _reply = nil;
    _inlineComposeView.delegate = nil;
    _inlineComposeView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.commentView = [[CommentView alloc] initWithFrame:self.view.frame];
    self.commentView.contentProvider = self.comment;
    self.commentView.delegate = self;
    
    WPFixedWidthScrollView *scrollView = [[WPFixedWidthScrollView alloc] initWithRootView:self.commentView];
    scrollView.alwaysBounceVertical = YES;
    if (IS_IPAD) {
        scrollView.contentInset = UIEdgeInsetsMake(WPTableViewTopMargin, 0, WPTableViewTopMargin, 0);
        scrollView.contentWidth = WPTableViewFixedWidth;
    };
    self.view = scrollView;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.trashButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-trash"] selectedImage:[UIImage imageNamed:@"icon-comments-trash-active"]];
    [self.trashButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.approveButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-approve"] selectedImage:[UIImage imageNamed:@"icon-comments-approve-active"]];
    [self.approveButton addTarget:self action:@selector(approveOrUnapproveAction:) forControlEvents:UIControlEventTouchUpInside];

    self.spamButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-flag"] selectedImage:[UIImage imageNamed:@"icon-comments-flag-active"]];
    [self.spamButton addTarget:self action:@selector(spamAction:) forControlEvents:UIControlEventTouchUpInside];

    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
    self.navigationItem.rightBarButtonItem = self.editButton;
    
    self.replyButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
    [self.replyButton addTarget:self action:@selector(replyAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.commentView];

    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    self.inlineComposeView.delegate = self;
    [self.view addSubview:self.inlineComposeView];

    if (self.comment) {
        [self showComment:self.comment];
   }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Get rid of any transient reply if popping the view
    // (ideally transient replies should be handled more cleanly)
    if ([self isMovingFromParentViewController] && self.transientReply) {
        [self.reply remove];
        self.reply = nil;
    }
}

- (void)cancelView:(id)sender {
	//there are no changes
	if (!self.editCommentViewController.hasChanges) {
		[self dismissEditViewController];

		return;
	}

	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"")
															 delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
											   destructiveButtonTitle:NSLocalizedString(@"Discard", @"")
													otherButtonTitles:nil];

    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;

	if (self.editCommentViewController.hasChanges) {
		actionSheet.tag = CommentViewEditCommentViewControllerHasChangesActionSheetTag;
        [actionSheet showInView:self.editCommentViewController.view];
    }

	self.isShowingActionSheet = YES;
}


#pragma mark - Instance methods

- (void)dismissEditViewController; {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateApproveButton {
    if ([self.comment.status isEqualToString:@"approve"]) {
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-unapprove"] forState:UIControlStateNormal];
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-unapprove-active"] forState:UIControlStateSelected];
        self.approveButton.tag = CommentViewUnapproveButtonTag;
    } else {
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-approve"] forState:UIControlStateNormal];
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-approve-active"] forState:UIControlStateSelected];
        self.approveButton.tag = CommentViewApproveButtonTag;
    }
}

- (void)showComment:(Comment *)comment {
    self.comment = comment;
    [self updateApproveButton];
}

- (NSAttributedString *)postTitleString {
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


#pragma mark - Comment moderation

- (void)deleteComment {
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailDelete];
    [self.comment remove];
    
    // Note: the parent class of CommentsViewController will pop this as a result of NSFetchedResultsChangeDelete
}

- (void)showEditCommentViewWithAnimation:(BOOL)animate {
	self.editCommentViewController = [[EditCommentViewController alloc]
                                  initWithNibName:@"EditCommentViewController"
                                  bundle:nil];
	self.editCommentViewController.commentViewController = self;
	self.editCommentViewController.comment = self.comment;
	self.editCommentViewController.title = NSLocalizedString(@"Edit Comment", @"");
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.editCommentViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:animate completion:nil];
}


#pragma mark - Actions

- (void)approveOrUnapproveAction:(id)sender {
    UIBarButtonItem *barButton = sender;
    if (barButton.tag == CommentViewApproveButtonTag) {
        [WPMobileStats trackEventForWPCom:StatsEventCommentDetailApprove];
        [self.comment approve];
    } else {
        [WPMobileStats trackEventForWPCom:StatsEventCommentDetailUnapprove];
        [self.comment unapprove];
    }
    [self updateApproveButton];
}

- (void)postTitleAction:(id)sender {
    [self openInAppWebView:[NSURL URLWithString:self.comment.link]];
}

- (void)deleteAction:(id)sender {
    if (!self.isShowingActionSheet) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this comment?", @"")
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                   destructiveButtonTitle:NSLocalizedString(@"Delete", @"")
                                                        otherButtonTitles:nil];
        actionSheet.tag = CommentViewDeletePromptActionSheetTag;
        actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
        [actionSheet showFromToolbar:self.navigationController.toolbar];
        
        self.isShowingActionSheet = YES;
    }
}

- (void)spamAction:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailFlagAsSpam];
    [self.comment spam];
}

- (void)editAction:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailEditComment];
	[self showEditCommentViewWithAnimation:YES];
}

- (void)replyAction:(id)sender {
	if (self.commentsViewController.blog.isSyncingComments) {
		[self showSyncInProgressAlert];
	} else {
        [WPMobileStats trackEventForWPCom:StatsEventCommentDetailClickedReplyToComment];
        self.reply = [self.comment restoreReply];
        self.transientReply = YES;
        self.inlineComposeView.text = self.reply.content;
        [self.inlineComposeView displayComposer];
	}
}


#pragma mark - UIActionSheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == CommentViewDeletePromptActionSheetTag) {
        [self processDeletePromptActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    } else if (actionSheet.tag == CommentViewEditCommentViewControllerHasChangesActionSheetTag) {
        [self processEditCommentHasChangesActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    
    self.isShowingActionSheet = NO;
}

- (void)processDeletePromptActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self deleteComment];
    }
}

- (void)processEditCommentHasChangesActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        self.editCommentViewController.hasChanges = NO;
        [self discard];
    }
}


#pragma mark UIWebView delegate methods

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

- (void)showSyncInProgressAlert {
    [WPError showAlertWithTitle:NSLocalizedString(@"Info", @"Info alert title") message:NSLocalizedString(@"The blog is syncing with the server. Please try later.", @"") withSupportButton:NO];
	//the blog is using the network connection and cannot be stoped, show a message to the user
}


#pragma mark - InlineComposeViewDelegate methods

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text {

    self.reply.content = text;
    // try to save it

    [[ContextManager sharedInstance] saveContext:self.reply.managedObjectContext];

    [self.inlineComposeView clearText];
    [self.inlineComposeView dismissComposer];

    self.reply.status = CommentStatusApproved;
    self.transientReply = NO;

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


#pragma mark - WPContentViewDelegate

- (void)contentView:(WPContentView *)contentView didReceiveAuthorLinkAction:(id)sender {
    NSURL *url = [NSURL URLWithString:self.comment.author_url];
    [self openInAppWebView:url];
}

@end
