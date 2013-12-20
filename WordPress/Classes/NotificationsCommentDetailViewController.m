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
#import "UIImageView+AFNetworking.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "NoteCommentCell.h"
#import "NoteCommentLoadingCell.h"
#import "NoteCommentContentCell.h"
#import "NoteComment.h"
#import "NSString+XMLExtensions.h"
#import "NSString+Helpers.h"
#import "NSURL+Util.h"
#import "WPToast.h"
#import "IOS7CorrectedTextView.h"
#import "WPAccount.h"
#import "NoteCommentPostBanner.h"
#import "FollowButton.h"
#import "Note.h"
#import "InlineComposeView.h"
#import "CommentView.h"

const CGFloat NotificationsCommentDetailViewControllerReplyTextViewDefaultHeight = 64.f;
NSString * const NoteCommentHeaderCellIdentifiter = @"NoteCommentHeaderCell";
NSString * const NoteCommentContentCellIdentifiter = @"NoteCommentContentCell";
NSString * const NoteCommentLoadingCellIdentifiter = @"NoteCommentLoadingCell";

NS_ENUM(NSUInteger, NotifcationCommentCellType) {
    NotificationCommentCellTypeHeader,
    NotificationCommentCellTypeContent
};

@interface NotificationsCommentDetailViewController () <NoteCommentCellDelegate, NoteCommentContentCellDelegate, InlineComposeViewDelegate, WPContentViewDelegate>

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
@property (nonatomic, strong) NSCache *contentCache;

@property (nonatomic, strong) UIButton *approveButton;
@property (nonatomic, strong) UIButton *trashButton;
@property (nonatomic, strong) UIButton *spamButton;
@property (nonatomic, strong) UIButton *replyButton;

@property (nonatomic, strong) CommentView *commentView;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet IOS7CorrectedTextView *replyTextView;
@property (nonatomic, weak) IBOutlet UIImageView *replyBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIView *tableFooterView;
@property (nonatomic, weak) IBOutlet UIView *replyActivityView;
@property (nonatomic, weak) IBOutlet NoteCommentPostBanner *postBanner;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) FollowButton *followButton;
@property (nonatomic, strong) Note *note;
@property (nonatomic, weak) IBOutlet UILabel *replyPlaceholder;
@property (nonatomic, weak) IBOutlet UINavigationBar *replyNavigationBar;
@property (nonatomic, weak) IBOutlet UINavigationItem *replyNavigationItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *replyCancelBarButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *replyPublishBarButton;

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
    self.inlineComposeView.delegate = nil;
    self.inlineComposeView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.commentThread = [[NSMutableArray alloc] initWithCapacity:1];
    
    
    self.view = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];
    self.commentView = [[CommentView alloc] initWithFrame:self.view.frame];
    self.commentView.contentProvider = self.note;
    self.commentView.delegate = self;
    
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

- (NSCache *)contentCache {
    if (!_contentCache) {
        _contentCache = [[NSCache alloc] init];
    }
    return _contentCache;
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

- (UIBarButtonItem *)barButtonItemWithImageNamed:(NSString *)image andAction:(SEL)action {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] style:UIBarButtonItemStylePlain target:self action:action];
    return item;
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
    [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailTrashComment];
    NSDictionary *commentAction = [self.commentActions objectForKey:@"trash-comment"];
    [self performCommentAction:commentAction];
    
    // TODO: undelete
//    [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailUntrashComment];
//    commentAction = [self.commentActions objectForKey:@"untrash-comment"];
}

- (void)spamAction:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailFlagCommentAsSpam];
    NSDictionary *commentAction = [self.commentActions objectForKey:@"spam-comment"];
    [self performCommentAction:commentAction];
    
    // TODO: unspam
//    [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailUnflagCommentAsSpam];
//    commentAction = [self.commentActions objectForKey:@"unspam-comment"];
}

- (void)replyAction:(id)sender {
    [self.inlineComposeView becomeFirstResponder];
}

- (void)performCommentAction:(NSDictionary *)commentAction {
    NSString *path = [NSString stringWithFormat:@"/rest/v1%@", [commentAction valueForKeyPath:@"params.rest_path"]];

    [[[WPAccount defaultWordPressComAccount] restApi] postPath:path parameters:[commentAction valueForKeyPath:@"params.rest_body"] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        if (response) {
            NSArray *noteArray = [NSArray arrayWithObject:_note];
            [[[WPAccount defaultWordPressComAccount] restApi] refreshNotifications:noteArray fields:nil success:^(AFHTTPRequestOperation *operation, id refreshResponseObject) {
                [self displayNote];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
    if (action){

        self.inlineComposeView.enabled = NO;

        self.replyActivityView.hidden = NO;
        NSString *approvePath = [NSString stringWithFormat:@"/rest/v1%@", [action valueForKeyPath:@"params.rest_path"]];
        NSString *replyPath = [NSString stringWithFormat:@"%@/replies/new", approvePath];
        NSDictionary *params = @{@"content" : replyText };
        if ([[action valueForKeyPath:@"params.approve_parent"] isEqualToNumber:@1]) {
            [[[WPAccount defaultWordPressComAccount] restApi] postPath:approvePath parameters:@{@"status" : @"approved"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self displayNote];
            } failure:nil];
        }
        
        [self.replyTextView resignFirstResponder];
        self.replyTextView.editable = NO;
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
            NSUInteger section = [self.commentThread indexOfObject:comment];
            NSIndexPath *commentIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
            CGFloat oldCommentHeight = [self tableView:self.tableView heightForRowAtIndexPath:commentIndexPath];
            comment.commentData = responseObject;
            comment.loading = NO;

            NSString *author = [comment.commentData valueForKeyPath:@"author.name"];
            NSString *authorLink = [comment.commentData valueForKeyPath:@"author.URL"];
            [self.commentView setAuthorDisplayName:author authorLink:authorLink];

            // if we're at the top of the tableview, we'll animate in the new parent
/*            id parent = [responseObject objectForKey:@"parent"];
            NoteComment *parentComment;
            if (![parent isEqual:@0]) {
                [self addScrollBackView];
                parentComment = [[NoteComment alloc] initWithCommentID:[parent valueForKey:@"ID"]];
                parentComment.isParentComment = YES;
            }
            
            CGPoint offset = self.tableView.contentOffset;
            
            // TODO: fix ux for loading parents
            // if it's the main content and no parent, reload return
            // if there's a parent insert the parent item
            // reload the table and fix the offset
            // if it's the main item, scroll down to show the first loader
            
            if (offset.y <= 0.f && section == [self.commentThread count] - 1) {

                if (parentComment) {
                    [self.commentThread insertObject:parentComment atIndex:0];
                    // animate
                    [self.tableView beginUpdates];
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
                    [self.tableView endUpdates];
                }

            } else {
                
                // reload and fix the offset
                NSIndexPath *contentIndexPath = [NSIndexPath indexPathForRow:NotificationCommentCellTypeContent inSection:commentIndexPath.section];
                // combine both row heights of the new section
                CGFloat newCommentHeight = [self tableView:self.tableView heightForRowAtIndexPath:commentIndexPath] + [self tableView:self.tableView heightForRowAtIndexPath:contentIndexPath];
                CGFloat offsetFix = newCommentHeight - oldCommentHeight;
                if (parentComment) {
                    // height for new section
                    NSIndexPath *parentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                    [self.commentThread insertObject:parentComment atIndex:0];
                    offsetFix += [self tableView:self.tableView heightForRowAtIndexPath:parentIndexPath] + [self tableView:self.tableView heightForFooterInSection:0];
                    
                }
                [self.tableView reloadData];
                CGPoint offset = self.tableView.contentOffset;
                offset.y += offsetFix;
                self.tableView.contentOffset = offset;
            }
            
            [self.tableView reloadData];*/
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);

            [self.tableView reloadData];
        }];
        
    }
}

- (void)performNoteAction:(NSDictionary *)action success:(WordPressComApiRestSuccessFailureBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *params = [action objectForKey:@"params"];
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", [params objectForKey:@"site_id"], [params objectForKey:@"comment_id"]];
    [[[WPAccount defaultWordPressComAccount] restApi] postPath:path parameters:[params objectForKey:@"rest_body"] success:success failure:failure];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.commentThread count];
} 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NoteComment *comment = [self.commentThread objectAtIndex:section];
    BOOL mainComment = [self.commentThread lastObject] == comment;
    if (!comment.isLoaded && !mainComment) {
        return 1;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.section];
    BOOL mainComment = (comment == [self.commentThread lastObject]);
    
    UITableViewCell *cell;
    switch (indexPath.row) {
        case NotificationCommentCellTypeHeader:
        {
            if (comment.isLoaded || mainComment) {
                NoteCommentCell *headerCell = [tableView dequeueReusableCellWithIdentifier:NoteCommentHeaderCellIdentifiter];
                if ([comment isParentComment]) {
                    [headerCell displayAsParentComment];
                }
                headerCell.delegate = self;
                [self prepareCommentHeaderCell:headerCell forCommment:comment];
                cell = headerCell;

            } else {
                NoteCommentLoadingCell *loadingCell = [tableView dequeueReusableCellWithIdentifier:NoteCommentLoadingCellIdentifiter];
                cell = loadingCell;
            }
            break;
        }
        case NotificationCommentCellTypeContent:
        {
            NoteCommentContentCell *contentCell = [tableView dequeueReusableCellWithIdentifier:NoteCommentContentCellIdentifiter];
            if ([self.contentCache objectForKey:comment]) {
                contentCell = [self.contentCache objectForKey:comment];
            } else {
                [self.contentCache setObject:contentCell forKey:comment];
            }
            
            contentCell.delegate = self;
            NSString *html = [comment.commentData valueForKey:@"content"];
            if (!html) {
                html = self.note.commentText;
            } else {
                contentCell.attributedString = [self convertHTMLToAttributedString:html];
                contentCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            if ([comment isParentComment]) {
                [contentCell displayAsParentComment];
            }
            cell = contentCell;
            break;
        }
    }
    return cell;
}

- (void)prepareCommentHeaderCell:(NoteCommentCell *)cell forCommment:(NoteComment *)comment {
    BOOL mainComment = comment == [self.commentThread lastObject];
    if (mainComment) {
        cell.avatarURL = [NSURL URLWithString:self.note.icon];
        cell.followButton = self.followButton;
        cell.imageView.hidden = NO;

    } else if (comment.isLoaded){
        cell.avatarURL = [NSURL URLWithString:[comment.commentData valueForKeyPath:@"author.avatar_URL"]];
        cell.followButton = nil;
        cell.imageView.hidden = NO;
    }
    if (comment.isLoaded) {
        cell.textLabel.text = [comment.commentData valueForKeyPath:@"author.name"];
        cell.detailTextLabel.text = [comment.commentData valueForKeyPath:@"author.ID"];
        NSString *authorURL = [comment.commentData valueForKeyPath:@"author.URL"];
        cell.profileURL = [NSURL URLWithString:authorURL];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self.commentThread count]-1) {
        return 0;
    } else {
        return 30.f;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == [self.commentThread count]-1) {
        return nil;
    } else {
        NSString *imageName;
        if (section == [self.commentThread count]-2) {
           // white
            imageName = @"note-comment-parent-footer";
        } else {
            imageName = @"note-comment-grandparent-footer";
        }
        UIEdgeInsets insets = UIEdgeInsetsMake(0.f, 68.f, 19.f, 0.f);
        UIImage *image = [[UIImage imageNamed:imageName] resizableImageWithCapInsets:insets];
        return [[UIImageView alloc] initWithImage:image];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.section];
    if (comment.needsData) {
        [self updateCommentThread];
    }
}

// the height of the comments
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.section];
    BOOL mainComment = [self.commentThread lastObject] == comment;
    CGFloat height = 0.0;
    switch (indexPath.row) {
        case NotificationCommentCellTypeHeader:
            height = (comment.isLoaded || mainComment) ? (comment.isParentComment) ? NoteCommentCellHeight - 36.0f : NoteCommentCellHeight : NoteCommentLoadingCellHeight;
            break;
        case NotificationCommentCellTypeContent:
        {
            CGFloat minHeight = 0.f;
            if (mainComment) {
                minHeight = CGRectGetHeight(tableView.bounds) - CGRectGetHeight(tableView.tableFooterView.bounds) - NoteCommentCellHeight;
            }
            NSString *content = [comment.commentData stringForKey:@"content"];
            if (content) {
                NSAttributedString *attributedContent = [self convertHTMLToAttributedString:content];
                CGFloat textHeight = [self
                                      heightForCellWithTextContent:attributedContent
                                      constrainedToWidth:CGRectGetWidth(tableView.bounds)];
                height = MAX(minHeight, textHeight);
            } else {
                height = minHeight;
            }
            break;
        }
    }
    return height;
}

- (CGFloat)heightForCellWithTextContent:(NSAttributedString *)textContent constrainedToWidth:(CGFloat)width {
    DTAttributedTextContentView *textContentView;
    [DTAttributedTextContentView setLayerClass:[CATiledLayer class]];
    textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.f, 0.f, width, 0.f)];
    textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textContentView.edgeInsets = UIEdgeInsetsMake(10.f, 10.f, 20.f, 10.f);
    textContentView.attributedString = textContent;
    CGSize size = [textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:width];
    return size.height;
}


#pragma mark - NoteCommentCellDelegate

- (void)commentCell:(NoteCommentCell *)cell didTapURL:(NSURL *)url {
    [self pushToURL:url];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Text Formatting

- (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html {
    NSAssert(html != nil, @"Can't convert nil to AttributedString");
    NSDictionary *options = @{
    DTDefaultFontFamily : @"Helvetica",
    NSTextSizeMultiplierDocumentOption : [NSNumber numberWithFloat:1.3]
    };

    html = [html stringByReplacingHTMLEmoticonsWithEmoji];
    NSAttributedString *content = [[NSAttributedString alloc] initWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
    return content;
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
    self.tableView.contentInset = UIEdgeInsetsMake(0.f, 0.f, CGRectGetHeight(keyboardRect), 0.f);
}

- (void)onHideKeyboard:(NSNotification *)notification {
    self.tableView.contentInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
}


@end
