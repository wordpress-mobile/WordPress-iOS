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
#import "CommentView.h"

CGFloat const CommentViewDeletePromptActionSheetTag = 501;
CGFloat const CommentViewReplyToCommentViewControllerHasChangesActionSheetTag = 401;
CGFloat const CommentViewEditCommentViewControllerHasChangesActionSheetTag = 601;
CGFloat const CommentViewApproveButtonTag = 700;
CGFloat const CommentViewUnapproveButtonTag = 701;

@interface CommentViewController () <UIWebViewDelegate, ReplyToCommentViewControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    ReplyToCommentViewController *_replyToCommentViewController;
    EditCommentViewController *_editCommentViewController;
    BOOL _isShowingActionSheet;
    NSLayoutConstraint *_authorSiteHeightConstraint;
}

@property (nonatomic, strong) CommentView *commentView;
@property (nonatomic, strong) UIButton *trashButton;
@property (nonatomic, strong) UIButton *approveButton;
@property (nonatomic, strong) UIButton *spamButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *replyButton;

@end

@implementation CommentViewController

- (void)dealloc {
    WPFLogMethod();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];
    self.commentView = [[CommentView alloc] initWithFrame:self.view.frame];
    self.commentView.contentProvider = self.comment;
    
    self.trashButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-trash"] selectedImage:[UIImage imageNamed:@"icon-comments-trash-active"]];
    [self.trashButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.approveButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-approve"] selectedImage:[UIImage imageNamed:@"icon-comments-approve-active"]];
    [self.approveButton addTarget:self action:@selector(approveOrUnapproveAction:) forControlEvents:UIControlEventTouchUpInside];

    self.spamButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-flag"] selectedImage:[UIImage imageNamed:@"icon-comments-flag-active"]];
    [self.spamButton addTarget:self action:@selector(spamAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.editButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-edit"] selectedImage:[UIImage imageNamed:@"icon-comments-edit-active"]];
    [self.editButton addTarget:self action:@selector(editAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.commentView];

    if (self.comment) {
        [self showComment:self.comment];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    UIScrollView *scrollView = (UIScrollView *)self.view;
    scrollView.contentSize = self.commentView.frame.size;
}

- (void)cancelView:(id)sender {
	//there are no changes
	if (!_replyToCommentViewController.hasChanges && !_editCommentViewController.hasChanges) {
		[self dismissEditViewController];
		
		if(sender == _replyToCommentViewController) {
			[_replyToCommentViewController.comment remove]; //delete the empty comment
			_replyToCommentViewController.comment = nil;
			
			if (IS_IPAD) { //an half-patch for #790: sometimes the modal view is not disposed when click on cancel.
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


#pragma mark - Private Methods

- (void)dismissEditViewController; {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showComment:(Comment *)comment {
    self.comment = comment;

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
    _replyToCommentViewController.navigationItem.rightBarButtonItem = nil;
	[self dismissEditViewController];
}


#pragma mark - Actions

- (IBAction)viewURL {
	NSURL *url = [NSURL URLWithString: [self.comment.author_url trim]];
    [self openInAppWebView:url];
}

- (void)approveOrUnapproveAction:(id)sender {
    UIBarButtonItem *barButton = sender;
    if (barButton.tag == CommentViewApproveButtonTag) {
        [self approveComment];
    } else {
        [self unApproveComment];
    }
}

- (void)handlePostTitleButtonTapped:(id)sender {
    [self openInAppWebView:[NSURL URLWithString:self.comment.link]];
}

- (void)deleteAction:(id)sender {
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
        
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate setAlertRunning:YES];
    }
}

- (void)spamAction:(id)sender {
    WPFLogMethodParam(NSStringFromSelector(_cmd));
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailFlagAsSpam];
    [self.comment removeObserver:self forKeyPath:@"status"];
    [self moderateCommentWithSelector:@selector(spam)];
    if (IS_IPAD) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)editAction:(id)sender {
    WPFLogMethod();
    [WPMobileStats trackEventForWPCom:StatsEventCommentDetailEditComment];
	[self showEditCommentViewWithAnimation:YES];
}

- (void)replyAction:(id)sender {
	if(self.commentsViewController.blog.isSyncingComments) {
		[self showSyncInProgressAlert];
	} else {
        [WPMobileStats trackEventForWPCom:StatsEventCommentDetailClickedReplyToComment];
		[self showReplyToCommentViewWithAnimation:YES];
	}
}


#pragma mark - UIActionSheet Delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == CommentViewDeletePromptActionSheetTag) {
        [self processDeletePromptActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    } else if (actionSheet.tag == CommentViewReplyToCommentViewControllerHasChangesActionSheetTag) {
        [self processReplyToCommentViewHasChangesActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    } else if (actionSheet.tag == CommentViewEditCommentViewControllerHasChangesActionSheetTag) {
        [self processEditCommentHasChangesActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    
    _isShowingActionSheet = NO;
}

- (void)processDeletePromptActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self deleteComment];
    }
}

- (void)processReplyToCommentViewHasChangesActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if (_replyToCommentViewController.hasChanges) {
            _replyToCommentViewController.hasChanges = NO;
            [_replyToCommentViewController.comment remove];
        }
        [self discard];
    }
}

- (void)processEditCommentHasChangesActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        _editCommentViewController.hasChanges = NO;
        [self discard];
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

@end
