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
#import "NoteComment.h"

#define APPROVE_BUTTON_TAG 1
#define UNAPPROVE_BUTTON_TAG 2
#define TRASH_BUTTON_TAG 3
#define UNTRASH_BUTTON_TAG 4
#define SPAM_BUTTON_TAG 5
#define UNSPAM_BUTTON_TAG 6

const CGFloat NotificationsCommentDetailViewControllerReplyTextViewDefaultHeight = 64.f;

@interface NotificationsCommentDetailViewController () <NoteCommentCellDelegate>

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
        [self.tableView registerClass:[NoteCommentCell class] forCellReuseIdentifier:@"NoteCommentCell"];
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
    
    
    // disable the buttons until we can determine which ones can be used
    // with this note
    self.spamBarButton.enabled = NO;
    self.trashBarButton.enabled = NO;
    self.approveBarButton.enabled = NO;
    
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

- (void)addScrollBackView {
    if (self.hasScrollBackView) return;
    self.hasScrollBackView = YES;
    CGRect frame = self.view.bounds;
    frame.size.height += 1200.f;
    UIView *scrollBackView = [[UIView alloc] initWithFrame:CGRectOffset(frame, 0.f, -CGRectGetHeight(frame))];
    scrollBackView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    scrollBackView.backgroundColor = [NoteCommentCell darkBackgroundColor];
    [self.tableView addSubview:scrollBackView];
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
    NSString *replyText = _replyTextView.text;
    
    if ([replyText length] > 0) {
        // Get blog_id and comment_id for api call
        NSDictionary *replyAction = [[self.commentActions objectForKey:@"replyto-comment"] objectForKey:@"params"];
        if (replyAction) {
            NSUInteger blogID = [[replyAction objectForKey:@"blog_id"] intValue];
            NSUInteger commentID = [[replyAction objectForKey:@"comment_id"] intValue];
            [self.replyPublishBarButton setEnabled:NO];
            [[WordPressComApi sharedApi] replyToComment:blogID forCommentID:commentID withReply:replyText success:^(AFHTTPRequestOperation *operation, id responseObject) {
                self.writingReply = NO;
                [_replyTextView resignFirstResponder];
                [self.panelNavigationController showToastWithMessage:NSLocalizedString(@"Replied", @"User replied to a comment") andImage:[UIImage imageNamed:@"action_icon_replied"]];
                [self.replyPublishBarButton setEnabled:YES];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self.replyPublishBarButton setEnabled:YES];
            }];
        }
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
            NSUInteger row = [self.commentThread indexOfObject:comment];
            NSIndexPath *commentIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
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
            
            if (offset.y <= 0.f && row == [self.commentThread count] - 1) {
                
                // animate
                [self.tableView beginUpdates];
                                
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];

                if (parentComment) {
                    [self.commentThread insertObject:parentComment atIndex:0];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
                }
         
                [self.tableView endUpdates];
            } else {
                
                // reload and fix the offset
                CGFloat newCommentHeight = [self tableView:self.tableView heightForRowAtIndexPath:commentIndexPath];
                CGFloat offsetFix = newCommentHeight - oldCommentHeight;
                if (parentComment) {
                    // height for new section
                    NSIndexPath *parentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                    [self.commentThread insertObject:parentComment atIndex:0];
                    offsetFix += [self tableView:self.tableView heightForRowAtIndexPath:parentIndexPath];
                    
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



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.commentThread count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"NoteCommentCell";
    NoteCommentCell *cell = (NoteCommentCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil){
        cell = [[NoteCommentCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:cellIdentifier];
    }
    cell.delegate = self;
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.row];
    if (indexPath.row == [self.commentThread count]-1) {
        // it's the main comment
        cell.imageView.hidden = NO;
        cell.avatarURL = [NSURL URLWithString:[self increaseGravatarSizeForURL: self.note.icon]];
        cell.followButton = self.followButton;
        if (!comment.isLoaded) {
            return cell;
        }
        
    } else {
        // it's a parent comment
        if (indexPath.row == [self.commentThread count]-2) {
            [cell displayAsParentComment];
        } else {
            [cell displayAsGrandparentComment];
        }
        if (!comment.isLoaded) {
            cell.imageView.hidden = YES;
            [cell showLoadingIndicator];
            return cell;
        } else {
            cell.imageView.hidden = NO;
            cell.avatarURL = [NSURL URLWithString:[self increaseGravatarSizeForURL:[comment.commentData valueForKeyPath:@"author.avatar_URL"]]];
        }
        
        // set the content
    }
    
    
    // otherwise let's set the contents here
    cell.textLabel.text = [comment.commentData valueForKeyPath:@"author.name"];
    cell.detailTextLabel.text = [comment.commentData valueForKeyPath:@"author.ID"];
    NSString *authorURL = [comment.commentData valueForKeyPath:@"author.URL"];
    cell.profileURL = [NSURL URLWithString:authorURL];
    NSAttributedString *content = [self convertHTMLToAttributedString:[comment.commentData valueForKeyPath:@"content"]];
    
    cell.textContentView.attributedString = content;
    
    return cell;
}

- (NSString *)increaseGravatarSizeForURL:(NSString *)originalURL {
    // REST API returns 96 by default, let's make it bigger
    return [originalURL stringByReplacingOccurrencesOfString:@"s=96" withString:@"s=184"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.row];
    if (comment.needsData) {
        [self updateCommentThread];
    }
}

// the height of the comments
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.row];
    if (indexPath.row == [self.commentThread count]-1) {
        // it's the main comment
        CGFloat minHeight = 112.f; //tableView.frame.size.height - tableView.tableFooterView.frame.size.height;
        if (!comment.isLoaded) {
            // it's loading, so enough height for the footer to show
            return minHeight;
        } else {
            NSAttributedString *content = [self convertHTMLToAttributedString:[comment.commentData valueForKeyPath:@"content"]];
            CGFloat width = self.tableView.bounds.size.width;
            CGFloat heightWithText = [NoteCommentCell heightForCellWithTextContent:content
                                                                 constrainedToWidth:width];
            return MAX(heightWithText, minHeight);
        }
    } else {
        // it's a parent comment
        if (!comment.isLoaded) {
            // it's loading, we have no content for it
            return 42.f;
        } else {
            NSAttributedString *content = [self convertHTMLToAttributedString:[comment.commentData valueForKeyPath:@"content"]];
            return [NoteCommentCell heightForCellWithTextContent:content constrainedToWidth:self.tableView.bounds.size.width];
        }
    }
    
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
        footerFrame.size.height = tableFrame.size.height;
    
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
