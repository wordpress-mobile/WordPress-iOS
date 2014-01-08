//
//  NotificationsDetailViewController.m
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <DTCoreText/DTCoreText.h>
#import "NotificationsCommentDetailViewController.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "NoteComment.h"
#import "NSString+XMLExtensions.h"
#import "NSString+Helpers.h"
#import "NSURL+Util.h"
#import "WPToast.h"
#import "WPAccount.h"
#import "NoteCommentPostBanner.h"
#import "FollowButton.h"
#import "Note.h"
#import "InlineComposeView.h"
#import "CommentView.h"
#import "WPFixedWidthScrollView.h"
#import "WPTableViewCell.h"
#import "WPTableViewController.h"

const CGFloat NotificationsCommentDetailViewControllerReplyTextViewDefaultHeight = 64.f;

@interface NotificationsCommentDetailViewController () <InlineComposeViewDelegate, WPContentViewDelegate>

@property NSUInteger followBlogID;
@property NSDictionary *commentActions;
@property NSDictionary *followDetails;
@property NSDictionary *comment;
@property NSDictionary *post;
@property NSMutableArray *commentThread;
@property NSNumber *siteID;
@property NSDictionary *followAction;
@property NSURL *headerURL;
@property BOOL hasScrollBackView;

@property (nonatomic, strong) UIButton *approveButton;
@property (nonatomic, strong) UIButton *trashButton;
@property (nonatomic, strong) UIButton *spamButton;
@property (nonatomic, strong) UIButton *replyButton;

@property (nonatomic, strong) CommentView *commentView;
@property (nonatomic, weak) IBOutlet NoteCommentPostBanner *postBanner;
@property (nonatomic, strong) FollowButton *followButton;
@property (nonatomic, strong) Note *note;

@property (nonatomic, strong) InlineComposeView *inlineComposeView;

@end

@implementation NotificationsCommentDetailViewController

- (id)initWithNote:(Note *)note {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Notification", @"Title for notification detail view");
        _hasScrollBackView = NO;
        _note = note;
    }
    return self;
}

- (void)dealloc {
    _inlineComposeView.delegate = nil;
    _inlineComposeView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.commentThread = [[NSMutableArray alloc] initWithCapacity:1];
    
    
    self.commentView = [[CommentView alloc] initWithFrame:self.view.frame];
    self.commentView.contentProvider = self.note;
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

    self.replyButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
    [self.replyButton addTarget:self action:@selector(replyAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.commentView];
    
    self.title = NSLocalizedString(@"Comment", @"Title for detail view of a comment notification");

    [self displayNote];
    
    // start fetching the thread
    [self updateCommentThread];


    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    self.inlineComposeView.delegate = self;
    [self.view addSubview:self.inlineComposeView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onShowKeyboard:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onHideKeyboard:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

- (void)displayNote {
    // get the note's actions
    NSArray *actions = [self.note.noteData valueForKeyPath:@"body.actions"];
    NSDictionary *action = [actions objectAtIndex:0];
    NSArray *items = [self.note.noteData valueForKeyPath:@"body.items"];
    self.siteID = [action valueForKeyPath:@"params.site_id"];
    
    NoteComment *comment = [[NoteComment alloc] initWithCommentID:[action valueForKeyPath:@"params.comment_id"]];
    [self.commentThread addObject:comment];
    
    // pull out the follow action and set up the follow button
    self.followAction = [[items lastObject] valueForKeyPath:@"action"];
    if (self.followAction && ![self.followAction isEqual:@0]) {
        self.followButton = [FollowButton buttonFromAction:self.followAction withApi:[[WPAccount defaultWordPressComAccount] restApi]];
    }
    
    NSString *postPath = [NSString stringWithFormat:@"sites/%@/posts/%@", [action valueForKeyPath:@"params.site_id"], [action valueForKeyPath:@"params.post_id"]];
    
    // if we don't have post information fetch it from the api
    if (self.post == nil) {
        [[[WPAccount defaultWordPressComAccount] restApi] getPath:postPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            self.post = responseObject;
            NSString *postTitle = [[self.post valueForKeyPath:@"title"] stringByDecodingXMLCharacters];
            if (!postTitle || [postTitle isEqualToString:@""])
                postTitle = NSLocalizedString(@"Untitled Post", @"Used when a post has no title");
            self.postBanner.titleLabel.text = postTitle;
            id authorAvatarURL = [self.post valueForKeyPath:@"author.avatar_URL"];
            if ([authorAvatarURL isKindOfClass:[NSString class]]) {
                [self.postBanner setAvatarURL:[NSURL URLWithString:authorAvatarURL]];
            }
            
            NSString *headerUrl = [self.post objectForKey:@"URL"];
            if (headerUrl != nil) {
                self.headerURL = [NSURL URLWithString:headerUrl];
            }
            
            self.postBanner.userInteractionEnabled = YES;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
        }];
    }

    // disable the buttons until we can determine which ones can be used
    // with this note
    self.spamButton.enabled = NO;
    self.trashButton.enabled = NO;
    self.approveButton.enabled = NO;
    self.replyButton.enabled = NO;

    // figure out the actions available for the note
    NSMutableDictionary *indexedActions = [[NSMutableDictionary alloc] initWithCapacity:[actions count]];
    [actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *actionType = [obj valueForKey:@"type"];
        [indexedActions setObject:obj forKey:actionType];
        if ([actionType isEqualToString:@"approve-comment"]) {
            self.approveButton.enabled = YES;
            [self updateApproveButton:YES];
        } else if ([actionType isEqualToString:@"unapprove-comment"]) {
            self.approveButton.enabled = YES;
            [self updateApproveButton:NO];
        } else if ([actionType isEqualToString:@"spam-comment"]) {
            self.spamButton.enabled = YES;
        } else if ([actionType isEqualToString:@"unspam-comment"]) {
            self.spamButton.enabled = YES;
        } else if ([actionType isEqualToString:@"trash-comment"]) {
            self.trashButton.enabled = YES;
        } else if ([actionType isEqualToString:@"untrash-comment"]) {
            self.trashButton.enabled = YES;
        } else if ([actionType isEqualToString:@"replyto-comment"]) {
            self.replyButton.enabled = YES;
        }
    }];

    self.commentActions = indexedActions;
}

- (NSDictionary *)getActionByType:(NSString *)type {
    NSArray *actions = [self.note.noteData valueForKeyPath:@"body.actions"];
    for (NSDictionary *action in actions) {
        if ([[action valueForKey:@"type"] isEqualToString:type]) {
            return action;
        }
    }
    return nil;
}

- (void)updateApproveButton:(BOOL)canBeApproved {
    if (canBeApproved) {
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-approve"] forState:UIControlStateNormal];
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-approve-active"] forState:UIControlStateSelected];
    } else {
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-unapprove"] forState:UIControlStateNormal];
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-unapprove-active"] forState:UIControlStateSelected];
    }
}


#pragma mark - Actions

- (void)visitPostURL:(id)sender {
    [self pushToURL:self.headerURL];
}

- (void)pushToURL:(NSURL *)url {
    if (IS_IPHONE) {
        [self.inlineComposeView resignFirstResponder];
    }
    WPWebViewController *webViewController = [[WPWebViewController alloc] initWithNibName:nil bundle:nil];
    if ([url isWordPressDotComUrl]) {
        [webViewController setUsername:[[WPAccount defaultWordPressComAccount] username]];
        [webViewController setPassword:[[WPAccount defaultWordPressComAccount] password]];
        [webViewController setUrl:[url ensureSecureURL]];
    } else {
        [webViewController setUrl:url];        
    }
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)approveOrUnapproveAction:(id)sender {
    NSDictionary *approveAction = [self.commentActions objectForKey:@"approve-comment"];
    NSDictionary *unapproveAction = [self.commentActions objectForKey:@"unapprove-comment"];

    if (approveAction) {
        // Pressed approve, so flip button optimistically to unapprove
        [self updateApproveButton:NO];
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailApproveComment];
        [self performCommentAction:approveAction];
    } else if (unapproveAction) {
        // Pressed unapprove, so flip button optimistically to approve
        [self updateApproveButton:YES];
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailUnapproveComment];
        [self performCommentAction:unapproveAction];
    }
}

- (void)deleteAction:(id)sender {
    NSDictionary *trashAction = [self.commentActions objectForKey:@"trash-comment"];
    NSDictionary *untrashAction = [self.commentActions objectForKey:@"untrash-comment"];
    
    if (trashAction) {
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailTrashComment];
        [self performCommentAction:trashAction];
    } else if (untrashAction) {
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailUntrashComment];
        [self performCommentAction:untrashAction];
    }
}

- (void)spamAction:(id)sender {
    NSDictionary *spamAction = [self.commentActions objectForKey:@"spam-comment"];
    NSDictionary *unspamAction = [self.commentActions objectForKey:@"unspam-comment"];
    
    if (spamAction) {
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailFlagCommentAsSpam];
        [self performCommentAction:spamAction];
    } else if (unspamAction) {
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailUnflagCommentAsSpam];
        [self performCommentAction:unspamAction];
    }
}

- (void)replyAction:(id)sender {
    [self.inlineComposeView becomeFirstResponder];
}

- (void)performCommentAction:(NSDictionary *)commentAction {
    NSString *path = [NSString stringWithFormat:@"/rest/v1%@", [commentAction valueForKeyPath:@"params.rest_path"]];
    
    [[[WPAccount defaultWordPressComAccount] restApi] postPath:path parameters:[commentAction valueForKeyPath:@"params.rest_body"] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        if (response) {
            [_note refreshNoteDataWithSuccess:^{
                // Buttons are adjusted optimistically, so no need to update UI
            } failure:^(NSError *error) {
                // Fail silently but force a refresh to revert any optimistic changes
                [self displayNote];
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
    }];

}

- (void)publishReply:(NSString *)replyText {
    [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailRepliedToComment];

    NSDictionary *action = [self.commentActions objectForKey:@"replyto-comment"];
    
    if (action) {
        self.inlineComposeView.enabled = NO;

        NSString *approvePath = [NSString stringWithFormat:@"/rest/v1%@", [action valueForKeyPath:@"params.rest_path"]];
        NSString *replyPath = [NSString stringWithFormat:@"%@/replies/new", approvePath];
        NSDictionary *params = @{@"content" : replyText };
        if ([[action valueForKeyPath:@"params.approve_parent"] isEqualToNumber:@1]) {
            [[[WPAccount defaultWordPressComAccount] restApi] postPath:approvePath parameters:@{@"status" : @"approved"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self displayNote];
            } failure:nil];
        }
        
        [[[WPAccount defaultWordPressComAccount] restApi] postPath:replyPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogVerbose(@"Response: %@", responseObject);
            [self.inlineComposeView clearText];
            self.inlineComposeView.enabled = YES;
            [self.inlineComposeView dismissComposer];
            [WPToast showToastWithMessage:NSLocalizedString(@"Replied", @"User replied to a comment")
                                 andImage:[UIImage imageNamed:@"action_icon_replied"]];

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogError(@"Failure %@", error);
            self.inlineComposeView.enabled = YES;
            [self.inlineComposeView displayComposer];
            DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
        }];
    }

}

- (IBAction)highlightHeader:(id)sender {
    [_postBanner setBackgroundColor:[UIColor UIColorFromHex:0xE3E3E3]];
}

- (IBAction)resetHeader:(id)sender {
    [_postBanner setBackgroundColor:[UIColor UIColorFromHex:0xF2F2F2]];
}


#pragma mark - REST API

- (void)updateCommentThread {
    // take the comment off the top of the thread
    NoteComment *comment = [self.commentThread objectAtIndex:0];
    // did we fetch the comment off the API yet?
    if (comment.needsData) {
        NSString *commentPath = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, comment.commentID];
        comment.loading = YES;
        [[[WPAccount defaultWordPressComAccount] restApi] getPath:commentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            comment.commentData = responseObject;
            comment.loading = NO;

            NSString *author = [comment.commentData valueForKeyPath:@"author.name"];
            NSString *authorLink = [comment.commentData valueForKeyPath:@"author.URL"];
            [self.commentView setAuthorDisplayName:author authorLink:authorLink];

        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
        }];
        
    }
}

- (void)performNoteAction:(NSDictionary *)action success:(WordPressComApiRestSuccessFailureBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *params = [action objectForKey:@"params"];
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", [params objectForKey:@"site_id"], [params objectForKey:@"comment_id"]];
    [[[WPAccount defaultWordPressComAccount] restApi] postPath:path parameters:[params objectForKey:@"rest_body"] success:success failure:failure];
}


#pragma mark - InlineComposeViewDelegate

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text {
    [self publishReply:text];
}


#pragma mark - WPContentViewDelegate

- (void)contentView:(WPContentView *)contentView didReceiveAuthorLinkAction:(id)sender {
    NoteComment *comment = [self.commentThread objectAtIndex:0];
    NSURL *url = [[NSURL alloc] initWithString:[comment.commentData valueForKeyPath:@"author.URL"]];
    [self pushToURL:url];
}


#pragma mark - UIKeyboard notifications

- (void)onShowKeyboard:(NSNotification *)notification {
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIScrollView *scrollView = (UIScrollView *)self.view;
    scrollView.contentInset = UIEdgeInsetsMake(0.f, 0.f, CGRectGetHeight(keyboardRect), 0.f);
}

- (void)onHideKeyboard:(NSNotification *)notification {
    UIScrollView *scrollView = (UIScrollView *)self.view;
    scrollView.contentInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
}


@end
