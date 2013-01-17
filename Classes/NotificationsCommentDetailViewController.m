//
//  NotificationsDetailViewController.m
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NotificationsCommentDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressAppDelegate.h"
#import "DTCoreText.h"
#import "WPWebViewController.h"
#import "NoteCommentCell.h"
#import "NoteCommentLoadingCell.h"
#import "NoteCommentContentCell.h"
#import "NoteComment.h"

#define APPROVE_BUTTON_TAG 1
#define UNAPPROVE_BUTTON_TAG 2
#define TRASH_BUTTON_TAG 3
#define UNTRASH_BUTTON_TAG 4
#define SPAM_BUTTON_TAG 5
#define UNSPAM_BUTTON_TAG 6

const CGFloat NotificationsCommentDetailViewControllerReplyTextViewDefaultHeight = 64.f;
NSString * const NotificationsCommentHeaderCellIdentifiter = @"NoteCommentHeaderCell";
NSString * const NotificationsCommentContentCellIdentifiter = @"NoteCommentContentCell";
NSString * const NotificationsCommentLoadingCellIdentifiter = @"NoteCommentLoadingCell";
NS_ENUM(NSUInteger, NotifcationCommentCellType){
    NotificationCommentCellTypeHeader,
    NotificationCommentCellTypeContent
};

@interface NotificationsCommentDetailViewController () <NoteCommentCellDelegate, NoteCommentContentCellDelegate>

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
@property (getter = isWritingReply) BOOL writingReply;
@property NSCache *contentCache;

@end

@implementation NotificationsCommentDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Notification", @"Title for notification detail view");
        self.writingReply = NO;
        self.hasScrollBackView = NO;
        self.contentCache = [[NSCache alloc] init];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    self.commentThread = [[NSMutableArray alloc] initWithCapacity:1];
    
    [super viewDidLoad];
    
    self.approveBarButton = [self barButtonItemWithImageNamed:@"toolbar_approve"
                                                          andAction:@selector(moderateComment:)];

    self.trashBarButton = [self barButtonItemWithImageNamed:@"toolbar_delete"
                                                   andAction:@selector(moderateComment:)];
    self.spamBarButton = [self barButtonItemWithImageNamed:@"toolbar_flag"
                                                 andAction:@selector(moderateComment:)];
    self.replyBarButton = [self barButtonItemWithImageNamed:@"toolbar_reply"
                                                  andAction:@selector(startReply:)];
    

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                               target:nil
                               action:nil];
    self.toolbar.items = @[self.approveBarButton, spacer, self.trashBarButton, spacer, self.spamBarButton, spacer, self.replyBarButton];


    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)]) {
        [self.tableView registerClass:[NoteCommentCell class]
               forCellReuseIdentifier:NotificationsCommentHeaderCellIdentifiter];
        [self.tableView registerClass:[DTAttributedTextCell class]
               forCellReuseIdentifier:NotificationsCommentContentCellIdentifiter];
    }
    
    // create the reply field
    CGRect replyFrame = self.tableView.bounds;
    replyFrame.size.height = 48.f;
    
    self.replyBackgroundImageView.image = [[UIImage imageNamed:@"note-reply-field"]
                                           resizableImageWithCapInsets:UIEdgeInsetsMake(6.f, 6.f, 6.f, 6.f)];
    
    self.tableView.tableFooterView = self.tableFooterView;
    
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(onShowKeyboard:)
               name:UIKeyboardWillShowNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(onHideKeyboard:)
               name:UIKeyboardWillHideNotification
             object:nil];
    
    self.title = NSLocalizedString(@"Comment", @"Title for detail view of a comment notification");

    [self displayNote];
    
    // start fetching the thread
    [self updateCommentThread];
    
}

- (void)displayNote {
        
    // get the note's actions
    NSArray *actions = [self.note.noteData valueForKeyPath:@"body.actions"];
    NSDictionary *action = [actions objectAtIndex:0];
    NSArray *items = [self.note.noteData valueForKeyPath:@"body.items"];
    self.siteID = [action valueForKeyPath:@"params.blog_id"];
    
    NoteComment *comment = [[NoteComment alloc] initWithCommentID:[action valueForKeyPath:@"params.comment_id"]];
    [self.commentThread addObject:comment];
    
    // pull out the follow action and set up the follow button
    self.followAction = [[items lastObject] valueForKeyPath:@"action"];
    if (![self.followAction isEqual:@0]) {
        self.followButton = [FollowButton buttonFromAction:self.followAction withApi:self.user];
    }
    
    NSString *postPath = [NSString stringWithFormat:@"sites/%@/posts/%@", [action valueForKeyPath:@"params.blog_id"], [action valueForKeyPath:@"params.post_id"]];
    
    // if we don't have post information fetch it from the api
    if (self.post == nil) {
        [self.user getPath:postPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            self.post = responseObject;
            self.postBanner.titleLabel.text = [self.post valueForKeyPath:@"title"];
            id authorAvatarURL = [self.post valueForKeyPath:@"author.avatar_URL"];
            if ([authorAvatarURL isKindOfClass:[NSString class]]) {
                [self.postBanner.avatarImageView setImageWithURL:[NSURL URLWithString:authorAvatarURL]];
            }
            
            self.postBanner.userInteractionEnabled = YES;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        }];
    }

    // disable the buttons until we can determine which ones can be used
    // with this note
    self.spamBarButton.enabled = NO;
    self.trashBarButton.enabled = NO;
    self.approveBarButton.enabled = NO;
    self.replyBarButton.enabled = NO;

    // figure out the actions available for the note
    NSMutableDictionary *indexedActions = [[NSMutableDictionary alloc] initWithCapacity:[actions count]];
    [actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *actionType = [obj valueForKey:@"type"];
        [indexedActions setObject:obj forKey:actionType];
        if ([actionType isEqualToString:@"approve-comment"]) {
            self.approveBarButton.enabled = YES;
            self.approveBarButton.customView.tag = APPROVE_BUTTON_TAG;
        } else if ([actionType isEqualToString:@"unapprove-comment"]){
            self.approveBarButton.enabled = YES;
            self.approveBarButton.customView.tag = UNAPPROVE_BUTTON_TAG;
        } else if ([actionType isEqualToString:@"spam-comment"]){
            self.spamBarButton.enabled = YES;
            self.spamBarButton.customView.tag = SPAM_BUTTON_TAG;
        } else if ([actionType isEqualToString:@"unspam-comment"]){
            self.spamBarButton.enabled = YES;
            self.spamBarButton.customView.tag = UNSPAM_BUTTON_TAG;
        } else if ([actionType isEqualToString:@"trash-comment"]){
            self.trashBarButton.enabled = YES;
            self.trashBarButton.customView.tag = TRASH_BUTTON_TAG;
        } else if ([actionType isEqualToString:@"untrash-comment"]){
            self.trashBarButton.enabled = YES;
            self.trashBarButton.customView.tag = UNTRASH_BUTTON_TAG;
        } else if ([actionType isEqualToString:@"replyto-comment"]){
            self.replyBarButton.enabled = YES;
        }
    }];
    
    self.commentActions = indexedActions;
    
    NSLog(@"available actions: %@", indexedActions);
    
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

- (void)addScrollBackView {
    return;
    if (self.hasScrollBackView) return;
    self.hasScrollBackView = YES;
    CGRect frame = self.view.bounds;
    frame.size.height += 1200.f;
    frame.origin.y = self.tableView.contentSize.height;
    UIView *scrollBackView = [[UIView alloc] initWithFrame:frame];
    scrollBackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    scrollBackView.backgroundColor = [UIColor greenColor];
    //[self.tableView addSubview:scrollBackView];
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    self.tableView.backgroundView.backgroundColor = [NoteCommentCell darkBackgroundColor];
}


#pragma mark - IBAction


- (void)visitPostURL:(id)sender {
    [self pushToURL:self.headerURL];
}

- (void)pushToURL:(NSURL *)url {
    WPWebViewController *webViewController = [[WPWebViewController alloc] initWithNibName:nil bundle:nil];
    [webViewController setUsername:[WordPressComApi sharedApi].username];
    [webViewController setPassword:[WordPressComApi sharedApi].password];
    [webViewController setUrl:url];
    [self.panelNavigationController pushViewController:webViewController fromViewController:self animated:YES];
}

- (IBAction)moderateComment:(id)sender {
    if (self.commentActions == nil || [self.commentActions count] == 0)
        return;
            
    NSDictionary *commentAction;
    UIButton *button = (UIButton *)sender;
    
    if (button.tag == APPROVE_BUTTON_TAG) {
        commentAction = [self.commentActions objectForKey:@"approve-comment"];
    } else if (button.tag == UNAPPROVE_BUTTON_TAG) {
        commentAction = [self.commentActions objectForKey:@"unapprove-comment"];
    } else if (button.tag == TRASH_BUTTON_TAG){
        commentAction = [self.commentActions objectForKey:@"trash-comment"];
    } else if (button.tag == UNTRASH_BUTTON_TAG){
        commentAction = [self.commentActions objectForKey:@"untrash-comment"];
    } else if (button.tag == SPAM_BUTTON_TAG){
        commentAction = [self.commentActions objectForKey:@"spam-comment"];
    } else if (button.tag == UNSPAM_BUTTON_TAG){
        commentAction = [self.commentActions objectForKey:@"unspam-comment"];
    }
    
    button.enabled = NO;
    
    NSString *path = [NSString stringWithFormat:@"/rest/v1%@", [commentAction valueForKeyPath:@"params.rest_path"]];
    [self.user postPath:path parameters:[commentAction valueForKeyPath:@"params.rest_body"] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        if (response) {
            NSArray *noteArray = [NSArray arrayWithObject:_note];
            [[WordPressComApi sharedApi] refreshNotifications:noteArray success:^(AFHTTPRequestOperation *operation, id refreshResponseObject) {
                [self displayNote];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self displayNote];
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        button.enabled = YES;
    }];
    
}

- (void)startReply:(id)sender {
    [self.replyTextView becomeFirstResponder];
}

- (void)cancelReply:(id)sender {
    self.writingReply = NO;
    [self.replyTextView resignFirstResponder];
}

- (void)publishReply:(id)sender {
    
    NSDictionary *action = [self.commentActions objectForKey:@"replyto-comment"];
    if (action){
        NSString *approvePath = [NSString stringWithFormat:@"/rest/v1%@", [action valueForKeyPath:@"params.rest_path"]];
        NSString *replyPath = [NSString stringWithFormat:@"%@/replies/new", approvePath];
        NSDictionary *params = @{@"content" : self.replyTextView.text };
        if (@1 == [action valueForKeyPath:@"params.approve_parent"]) {
            [self.user postPath:approvePath parameters:@{@"status" : @"approved"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self displayNote];
            } failure:nil];
        }
        
        
        [self.user postPath:replyPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Response: %@", responseObject);
            self.replyTextView.editable = YES;
            self.replyTextView.text = nil;
            self.writingReply = NO;
            [self.replyTextView resignFirstResponder];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure %@", error);
            self.replyTextView.editable = YES;
        }];
    }

}

#pragma mark - REST API

- (void)updateCommentThread {
    // take the comment off the top of the thread
    NoteComment *comment = [self.commentThread objectAtIndex:0];
    // did we fetch the comment off the API yet?
    if (comment.needsData) {
        NSString *commentPath = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, comment.commentID];
        comment.loading = YES;
        [self.user getPath:commentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSUInteger section = [self.commentThread indexOfObject:comment];
            NSIndexPath *commentIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
            CGFloat oldCommentHeight = [self tableView:self.tableView heightForRowAtIndexPath:commentIndexPath];
            comment.commentData = responseObject;
            comment.loading = NO;
            
            // if we're at the top of the tableview, we'll animate in the new parent
            id parent = [responseObject objectForKey:@"parent"];
            NoteComment *parentComment;
            if (![parent isEqual:@0]) {
                [self addScrollBackView];
                parentComment = [[NoteComment alloc] initWithCommentID:[parent valueForKey:@"ID"]];
            }
            
            CGPoint offset = self.tableView.contentOffset;
            
            // TODO: fix ux for loading parents
            // if it's the main content and no parent, reload return
            // if there's a parent insert the parent item
            // reload the table and fix the offset
            // if it's the main item, scroll down to show the first loader
            
            if (offset.y <= 0.f && section == [self.commentThread count] - 1) {
                
                // animate
                [self.tableView beginUpdates];
                                
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:commentIndexPath.section] withRowAnimation:UITableViewRowAnimationNone];

                if (parentComment) {
                    [self.commentThread insertObject:parentComment atIndex:0];
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
                }
         
                [self.tableView endUpdates];
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
        } failure:nil];
        
    }
}

- (void)performNoteAction:(NSDictionary *)action success:(WordPressComApiRestSuccessFailureBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *params = [action objectForKey:@"params"];
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", [params objectForKey:@"blog_id"], [params objectForKey:@"comment_id"]];
    [self.user postPath:path parameters:[params objectForKey:@"rest_body"] success:success failure:failure];
    
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
    BOOL mainComment = comment == [self.commentThread lastObject];
    UITableViewCell *cell;
    switch (indexPath.row) {
        case NotificationCommentCellTypeHeader:
        {
            if (comment.isLoaded || mainComment) {
                NoteCommentCell *headerCell;
                headerCell = [tableView dequeueReusableCellWithIdentifier:NotificationsCommentHeaderCellIdentifiter];
                if (headerCell == nil) {
                    headerCell = [[NoteCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NotificationsCommentHeaderCellIdentifiter];
                }
                headerCell.delegate = self;
                [self prepareCommentHeaderCell:headerCell forCommment:comment];
                cell = headerCell;

            } else {
                NoteCommentLoadingCell *loadingCell;
                loadingCell = [tableView dequeueReusableCellWithIdentifier:NotificationsCommentLoadingCellIdentifiter];
                if (loadingCell == nil) {
                    loadingCell = [[NoteCommentLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NotificationsCommentLoadingCellIdentifiter];
                }
                cell = loadingCell;
            }
            break;
        }
        case NotificationCommentCellTypeContent:
        {
            NoteCommentContentCell *contentCell;

            contentCell = [self.contentCache objectForKey:comment];
            contentCell.delegate = self;
            if (contentCell == nil) {
                contentCell = [[NoteCommentContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NotificationsCommentContentCellIdentifiter];
            }
            [self.contentCache setObject:contentCell forKey:comment];
            NSString *html = [comment.commentData valueForKey:@"content"];
            if (html != nil) {
                contentCell.attributedString = [self convertHTMLToAttributedString:html];
                contentCell.selectionStyle = UITableViewCellSelectionStyleNone;
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
        cell.avatarURL = [NSURL URLWithString:[self increaseGravatarSizeForURL: self.note.icon]];
        cell.followButton = self.followButton;
        cell.imageView.hidden = NO;

    } else if (comment.isLoaded){
        cell.avatarURL = [NSURL URLWithString:[self increaseGravatarSizeForURL:[comment.commentData valueForKeyPath:@"author.avatar_URL"]]];
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

- (NSString *)increaseGravatarSizeForURL:(NSString *)originalURL {
    // REST API returns 96 by default, let's make it bigger
    return [originalURL stringByReplacingOccurrencesOfString:@"s=96" withString:@"s=184"];
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
//        if (section == [self.commentThread count]-2) {
//           // white
//            imageName = @"note-comment-parent-footer";
//        } else {
//            imageName = @"note-comment-grandparent-footer";
//        }
        imageName = @"note-comment-parent-footer";
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
    CGFloat height;
    switch (indexPath.row) {
        case NotificationCommentCellTypeHeader:
            height = (comment.isLoaded || mainComment) ? NoteCommentCellHeight : NoteCommentLoadingCellHeight;
            break;
        case NotificationCommentCellTypeContent:
        {
            CGFloat minHeight = 0.f;
            if (mainComment) {
                minHeight = CGRectGetHeight(tableView.bounds) - CGRectGetHeight(tableView.tableFooterView.bounds) - NoteCommentCellHeight;
            }
            NSAttributedString *content = [self convertHTMLToAttributedString:[comment.commentData valueForKeyPath:@"content"]];
            CGFloat textHeight = [self
                                  heightForCellWithTextContent:content
                                  constrainedToWidth:CGRectGetWidth(tableView.bounds)];
            height = MAX(minHeight, textHeight);
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
    
    NSDictionary *options = @{
    DTDefaultFontFamily : @"Helvetica",
    NSTextSizeMultiplierDocumentOption : [NSNumber numberWithFloat:1.3]
    };
    
    NSAttributedString *content = [[NSAttributedString alloc] initWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL];
    return content;
}

- (BOOL)replyTextViewHasText {
    NSString *text = self.replyTextView.text;
    return text != nil && ![text isEqualToString:@""];
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.writingReply = YES;
    self.replyPlaceholder.hidden = YES;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.replyPublishBarButton.enabled = [self replyTextViewHasText];
}

#pragma mark - UIKeyboard notifications

- (void)onShowKeyboard:(NSNotification *)notification {
    
    
    if (self.isWritingReply) {
        self.panelNavigationController.navigationController.navigationBarHidden = YES;
        
        CGFloat verticalDelta = [self keyboardVerticalOverlapChangeFromNotification:notification];
        CGFloat maxVerticalSpace = self.view.frame.size.height + verticalDelta;
        CGRect bannerFrame = self.postBanner.frame;
        CGRect toolbarFrame = self.toolbar.frame;
        CGRect tableFrame = self.tableView.frame;
        CGRect footerFrame = self.tableFooterView.frame;
        CGRect replyBarFrame = self.replyNavigationBar.frame;
        
        [self.view addSubview:self.replyNavigationBar];
        
        replyBarFrame.origin.y = 0;
        replyBarFrame.size.width = self.view.frame.size.width;
        self.replyNavigationBar.frame = replyBarFrame;

        bannerFrame.origin.y = -bannerFrame.size.height;
        toolbarFrame.origin.y = self.view.bounds.size.height;
        tableFrame.origin.y = CGRectGetMaxY(replyBarFrame);
        tableFrame.size.height = maxVerticalSpace - tableFrame.origin.y;
        footerFrame.size.height = MAX(CGRectGetHeight(tableFrame) * 0.75f, 88.f);
    
        [UIView animateWithDuration:0.2f animations:^{
            self.tableFooterView.frame = footerFrame;
            self.tableView.tableFooterView = self.tableFooterView;
            self.tableView.frame = tableFrame;
            self.postBanner.frame = bannerFrame;
            self.toolbar.frame = toolbarFrame;
            [self.tableView scrollRectToVisible:self.tableFooterView.frame animated:NO];
        }];

    }
}

- (void)onHideKeyboard:(NSNotification *)notification {
    
    if (!self.isWritingReply) {
        
        self.panelNavigationController.navigationController.navigationBarHidden = NO;
        
        // remove the reply bar
        [self.replyNavigationBar removeFromSuperview];
        
        CGRect bannerFrame = self.postBanner.frame;
        CGRect toolbarFrame = self.toolbar.frame;
        CGRect tableFrame = self.tableView.frame;
        
        bannerFrame.origin.y = 0;
        toolbarFrame.origin.y = self.view.bounds.size.height - toolbarFrame.size.height;
        tableFrame.origin.y = CGRectGetMaxY(bannerFrame);
        tableFrame.size.height = toolbarFrame.origin.y - tableFrame.origin.y;
        
        
        
        [UIView animateWithDuration:0.2f animations:^{
            if (![self replyTextViewHasText]) {
                self.replyPlaceholder.hidden = NO;
                CGRect tableFooterFrame = self.tableFooterView.frame;
                tableFooterFrame.size.height = NotificationsCommentDetailViewControllerReplyTextViewDefaultHeight;
                self.tableFooterView.frame = tableFooterFrame;
                self.tableView.tableFooterView = self.tableFooterView;
            }
            self.tableView.frame = tableFrame;
            self.postBanner.frame = bannerFrame;
            self.toolbar.frame = toolbarFrame;
        }];
        
        
    }

}

- (CGFloat)keyboardVerticalOverlapChangeFromNotification:(NSNotification *)notification {
    CGRect startFrame = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // adjust for any kind of rotation the view has
    startFrame = [self.view.superview convertRect:startFrame fromView:nil];
    endFrame = [self.view.superview convertRect:endFrame fromView:nil];
    
    // is the current view obscured at all by the start frame
    CGRect startOverlapRect = CGRectIntersection(self.view.superview.bounds, startFrame);
    CGRect endOverlapRect = CGRectIntersection(self.view.superview.bounds, endFrame);
    
    
    // is there a change in x?, keyboard is sliding off due to push/pop animation, don't do anything
    
    // starting Y overlap
    CGFloat startVerticalOverlap = startOverlapRect.size.height;
    CGFloat endVerticalOverlap = endOverlapRect.size.height;
    return startVerticalOverlap - endVerticalOverlap;
}


@end
