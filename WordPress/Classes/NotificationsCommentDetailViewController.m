#import <QuartzCore/QuartzCore.h>
#import <DTCoreText/DTCoreText.h>
#import "ContextManager.h"
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
#import "Note.h"
#import "InlineComposeView.h"
#import "CommentView.h"
#import "WPFixedWidthScrollView.h"
#import "WPTableViewCell.h"
#import "WPTableViewController.h"
#import "NoteBodyItem.h"
#import "AccountService.h"

const CGFloat NotificationsCommentDetailViewControllerReplyTextViewDefaultHeight = 64.f;
NSString *const WPNotificationCommentRestorationKey = @"WPNotificationCommentRestorationKey";

@interface NotificationsCommentDetailViewController () <InlineComposeViewDelegate, WPContentViewDelegate, UIViewControllerRestoration>

@property (nonatomic, assign) NSUInteger		followBlogID;
@property (nonatomic, strong) NSDictionary		*commentActions;
@property (nonatomic, strong) NSDictionary		*followDetails;
@property (nonatomic, strong) NSDictionary		*comment;
@property (nonatomic, strong) NSDictionary		*post;
@property (nonatomic, strong) NSMutableArray	*commentThread;
@property (nonatomic, strong) NSNumber			*siteID;
@property (nonatomic, strong) NSDictionary		*followAction;
@property (nonatomic, strong) NSURL				*headerURL;
@property (nonatomic, assign) BOOL				hasScrollBackView;

@property (nonatomic, strong) UIButton			*approveButton;
@property (nonatomic, strong) UIButton			*trashButton;
@property (nonatomic, strong) UIButton			*spamButton;
@property (nonatomic, strong) UIButton			*replyButton;

@property (nonatomic, weak) IBOutlet NoteCommentPostBanner *postBanner;
@property (nonatomic, strong) CommentView		*commentView;
@property (nonatomic, strong) Note				*note;

@property (nonatomic, strong) InlineComposeView *inlineComposeView;

@end

@implementation NotificationsCommentDetailViewController


+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    NSString *noteID = [coder decodeObjectForKey:WPNotificationCommentRestorationKey];
    if (!noteID)
        return nil;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:noteID]];
    if (!objectID)
        return nil;
    
    NSError *error = nil;
    Note *restoredNote = (Note *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredNote) {
        return nil;
    }
    
    return [[self alloc] initWithNote:restoredNote];
}

- (void)dealloc {
    _inlineComposeView.delegate = nil;
    _inlineComposeView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNote:(Note *)note {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Notification", @"Title for notification detail view");
        _hasScrollBackView = NO;
        _note = note;
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.commentThread = [[NSMutableArray alloc] initWithCapacity:1];
    
    self.commentView = [[CommentView alloc] initWithFrame:self.view.frame];
    self.commentView.contentProvider = self.note;
    self.commentView.delegate = self;
    // If there's one note bodyItem, just use titleForDisplay
    if ([[self.note bodyItems] count] == 1) {
        self.commentView.headerText = [self.note titleForDisplay];
    } else if ([[self.note bodyItems] count] > 1) {
        NoteBodyItem *noteBodyItem = [[self.note bodyItems] firstObject];
        if (noteBodyItem && noteBodyItem.headerHtml && noteBodyItem.bodyHtml) {
            self.commentView.headerText = [NSString stringWithFormat: @"%@:<p>\"%@\"</p>", noteBodyItem.headerHtml, noteBodyItem.bodyHtml];
        }
    }
    
    WPFixedWidthScrollView *scrollView = [[WPFixedWidthScrollView alloc] initWithRootView:self.commentView];
    scrollView.alwaysBounceVertical = YES;
    if (IS_IPAD) {
        scrollView.contentInset = UIEdgeInsetsMake(WPTableViewTopMargin, 0, WPTableViewTopMargin, 0);
        scrollView.contentWidth = WPTableViewFixedWidth;
    };
    self.view = scrollView;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.trashButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-trash"] selectedImage:[UIImage imageNamed:@"icon-comments-trash-active"]];
    self.trashButton.accessibilityLabel = NSLocalizedString(@"Move to trash", @"Spoken accessibility label.");
    [self.trashButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.approveButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-approve"] selectedImage:[UIImage imageNamed:@"icon-comments-approve-active"]];
    self.approveButton.accessibilityLabel = NSLocalizedString(@"Toggle approve or unapprove", @"Spoken accessibility label.");
    [self.approveButton addTarget:self action:@selector(approveOrUnapproveAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.spamButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-flag"] selectedImage:[UIImage imageNamed:@"icon-comments-flag-active"]];
    self.spamButton.accessibilityLabel = NSLocalizedString(@"Mark as spam", @"Spoken accessibility label.");
    [self.spamButton addTarget:self action:@selector(spamAction:) forControlEvents:UIControlEventTouchUpInside];

    self.replyButton = [self.commentView addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
    self.replyButton.accessibilityLabel = NSLocalizedString(@"Reply", @"Spoken accessibility label.");
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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:[[self.note.objectID URIRepresentation] absoluteString] forKey:WPNotificationCommentRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)displayNote {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    // get the note's actions
    NSArray *actions = self.note.bodyActions;
    NSDictionary *action = [actions firstObject];
    self.siteID = [action valueForKeyPath:@"params.site_id"];
    
    NoteComment *comment = [[NoteComment alloc] initWithCommentID:[action valueForKeyPath:@"params.comment_id"]];
    [self.commentThread addObject:comment];
    
    NSString *postPath = [NSString stringWithFormat:@"sites/%@/posts/%@", [action valueForKeyPath:@"params.site_id"], [action valueForKeyPath:@"params.post_id"]];
    
    // if we don't have post information fetch it from the api
    if (self.post == nil) {
        [[defaultAccount restApi] GET:postPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    NSArray *actions = [self.note bodyActions];
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
        self.approveButton.accessibilityLabel = NSLocalizedString(@"Approve", @"Spoken accessibility label.");
    } else {
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-unapprove"] forState:UIControlStateNormal];
        [self.approveButton setImage:[UIImage imageNamed:@"icon-comments-unapprove-active"] forState:UIControlStateSelected];
        self.approveButton.accessibilityLabel = NSLocalizedString(@"Unapprove", @"Spoken accessibility label.");
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
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
        
        [webViewController setUsername:[defaultAccount username]];
        [webViewController setPassword:[defaultAccount password]];
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
        [WPAnalytics track:WPAnalyticsStatNotificationApproved];
        [self performCommentAction:approveAction];
    } else if (unapproveAction) {
        // Pressed unapprove, so flip button optimistically to approve
        [self updateApproveButton:YES];
        [self performCommentAction:unapproveAction];
    }
    
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];
}

- (void)deleteAction:(id)sender {
    NSDictionary *trashAction = [self.commentActions objectForKey:@"trash-comment"];
    NSDictionary *untrashAction = [self.commentActions objectForKey:@"untrash-comment"];
    
    if (trashAction) {
        [WPAnalytics track:WPAnalyticsStatNotificationTrashed];
        [self performCommentAction:trashAction];
    } else if (untrashAction) {
        [self performCommentAction:untrashAction];
    }
    
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];
}

- (void)spamAction:(id)sender {
    NSDictionary *spamAction = [self.commentActions objectForKey:@"spam-comment"];
    NSDictionary *unspamAction = [self.commentActions objectForKey:@"unspam-comment"];
    
    if (spamAction) {
        [WPAnalytics track:WPAnalyticsStatNotificationFlaggedAsSpam];
        [self performCommentAction:spamAction];
    } else if (unspamAction) {
        [self performCommentAction:unspamAction];
    }
    
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];
}

- (void)replyAction:(id)sender {
    [self.inlineComposeView becomeFirstResponder];
}

- (void)performCommentAction:(NSDictionary *)commentAction {
    NSString *path = [NSString stringWithFormat:@"/rest/v1%@", [commentAction valueForKeyPath:@"params.rest_path"]];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    [[defaultAccount restApi] POST:path parameters:[commentAction valueForKeyPath:@"params.rest_body"] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // The Note will be automatically updated by Simperium
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
    }];

}

- (void)publishReply:(NSString *)replyText {
    NSDictionary *action = [self.commentActions objectForKey:@"replyto-comment"];
    
    if (action) {
        self.inlineComposeView.enabled = NO;
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

        NSString *approvePath = [NSString stringWithFormat:@"/rest/v1%@", [action valueForKeyPath:@"params.rest_path"]];
        NSString *replyPath = [NSString stringWithFormat:@"%@/replies/new", approvePath];
        NSDictionary *params = @{@"content" : replyText };
        if ([[action valueForKeyPath:@"params.approve_parent"] isEqualToNumber:@1]) {
            [[defaultAccount restApi] POST:approvePath parameters:@{@"status" : @"approved"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self displayNote];
            } failure:nil];
        }

        void (^success)() = ^{
            [self.inlineComposeView clearText];
            self.inlineComposeView.enabled = YES;
            [self.inlineComposeView dismissComposer];
            [WPToast showToastWithMessage:NSLocalizedString(@"Replied", @"User replied to a comment")
                                 andImage:[UIImage imageNamed:@"action_icon_replied"]];
        };

        void (^failure)() = ^{
            self.inlineComposeView.enabled = YES;
            [self.inlineComposeView displayComposer];
        };

        [[defaultAccount restApi] POST:replyPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogVerbose(@"Response: %@", responseObject);
            [WPAnalytics track:WPAnalyticsStatNotificationRepliedTo];
            [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];
            success();
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogError(@"Failure %@", error);
            if ([error.userInfo[WordPressComApiErrorCodeKey] isEqual:@"comment_duplicate"]) {
                // If it's a duplicate comment, fake success since an identical comment is published
                success();
            } else {
                failure();
            }
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
        
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

        [[defaultAccount restApi] GET:commentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            comment.commentData = responseObject;
            comment.loading = NO;

            NSString *author = [comment.commentData valueForKeyPath:@"author.name"];
            if ([[author trim] length] == 0) {
                author = NSLocalizedString(@"Someone", @"Identifies the author of a comment that chose to be anonymous. Should match the wpcom translation for 'Someone' who left a comment, as opposed to an 'anonymous' author.");
            }
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
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    [[defaultAccount restApi] POST:path parameters:[params objectForKey:@"rest_body"] success:success failure:failure];
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

- (void)contentView:(WPContentView *)contentView didReceiveLinkAction:(id)sender {
    [self pushToURL:((DTLinkButton *)sender).URL];
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
