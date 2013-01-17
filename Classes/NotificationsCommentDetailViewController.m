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
#define TRASH_BUTTON_TAG 2
#define SPAM_BUTTON_TAG 3

const CGFloat NotificationsCommentDetailViewControllerReplyTextViewDefaultHeight = 64.f;

@interface NotificationsCommentDetailViewController () <NoteCommentCellDelegate>

@property NSUInteger followBlogID;
@property BOOL canApprove, canTrash, canSpam;
@property NSArray *commentActions;
@property NSDictionary *followDetails;
@property NSDictionary *comment;
@property NSDictionary *post;
@property NSMutableArray *commentThread;
@property NSNumber *siteID;
@property NSDictionary *followAction;
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
    
    self.approveBarButton.tag = APPROVE_BUTTON_TAG;
    self.trashBarButton.tag = TRASH_BUTTON_TAG;
    self.spamBarButton.tag = SPAM_BUTTON_TAG;

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
    
    
    self.postBanner.userInteractionEnabled = NO;
    
    
    [self displayNote];
    
    // start fetching the thread
    [self updateCommentThread];
    
}

- (void)displayNote {
    
    
    self.title = self.note.subject;

    
    // let's get the real comment off of the api
    NSArray *actions = [self.note.noteData valueForKeyPath:@"body.actions"];
    self.commentActions = actions;
    NSDictionary *action = [actions objectAtIndex:0];
    NSArray *items = [self.note.noteData valueForKeyPath:@"body.items"];
    self.siteID = [action valueForKeyPath:@"params.blog_id"];
    
    NoteComment *comment = [[NoteComment alloc] initWithCommentID:[action valueForKeyPath:@"params.comment_id"]];
    [self.commentThread addObject:comment];
    
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
    
    self.canApprove = NO;
    self.canTrash = NO;
    self.canSpam = NO;
    [actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *action = obj;
        NSString *type = [action valueForKeyPath:@"type"];
        if ([type isEqualToString:@"unapprove-comment"]) {
            self.canApprove = YES;
        } else if ([type isEqualToString:@"spam-comment"]){
            self.canSpam = YES;
        } else if ([type isEqualToString:@"trash-comment"]){
            self.canTrash = YES;
        }
    }];
    
    self.spamBarButton.enabled = self.canSpam;
    self.trashBarButton.enabled = self.canTrash;
    self.approveBarButton.enabled = self.canApprove;
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


#pragma mark - IBAction

-(void)toggleApproval:(id)sender {
    NSDictionary *approveAction = [self getActionByType:@"approve-comment"];
    NSDictionary *unapproveAction = [self getActionByType:@"unapprove-comment"];
    if (approveAction != nil) {
        NSLog(@"Approve: %@", approveAction);
    } else if(unapproveAction != nil){
        NSLog(@"Unapprove: %@", unapproveAction);
    }
}

- (void)visitPostURL:(id)sender {
    [self pushToURL:[NSURL URLWithString:[self.post valueForKeyPath:@"URL"]]];
}

- (void)pushToURL:(NSURL *)url {
    WPWebViewController *webViewController = [[WPWebViewController alloc] initWithNibName:nil bundle:nil];
    [webViewController setUrl:url];
    [self.panelNavigationController pushViewController:webViewController animated:YES];
}

- (IBAction)moderateComment:(id)sender {
    
    if (self.commentActions == nil || [self.commentActions count] == 0)
        return;
    
    // Get blog_id and comment_id for api call
    NSDictionary *commentAction = [[self.commentActions objectAtIndex:0] objectForKey:@"params"];
    NSUInteger blogID = [[commentAction objectForKey:@"blog_id"] intValue];
    NSUInteger commentID = [[commentAction objectForKey:@"comment_id"] intValue];
    
    if (!blogID || !commentID)
        return;
    
    UIButton *button = (UIButton *)sender;
    NSString *commentStatus = @"approved";
    if (button.tag == APPROVE_BUTTON_TAG) {
        if (self.canApprove)
            commentStatus = @"approved";
        else
            commentStatus = @"unapproved";
    } else if (button.tag == SPAM_BUTTON_TAG) {
        if (self.canSpam)
            commentStatus = @"spam";
        else
            commentStatus = @"unspam";
    } else if (button.tag == TRASH_BUTTON_TAG) {
        if (self.canTrash)
            commentStatus = @"trash";
        else
            commentStatus = @"untrash";
    }
    
    [button setEnabled:NO];
    
    [[WordPressComApi sharedApi] moderateComment:blogID forCommentID:commentID withStatus:commentStatus success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Update note to have new status
        NSDictionary *response = (NSDictionary *)responseObject;
        if (response) {
            NSArray *noteArray = [NSArray arrayWithObject:_note];
            [[WordPressComApi sharedApi] refreshNotifications:noteArray success:^(AFHTTPRequestOperation *operation, id refreshResponseObject) {
                [self displayNote];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self displayNote];
            }];
        }
        [button setEnabled:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [button setEnabled:YES];
    }];
    
    
    
}

- (IBAction)replyToComment:(id)sender {
    NSString *replyText = _replyTextView.text;
    
    if ([replyText length] > 0) {
        
        // Get blog_id and comment_id for api call
        NSDictionary *commentAction = [[_commentActions objectAtIndex:0] objectForKey:@"params"];
        NSUInteger blogID = [[commentAction objectForKey:@"blog_id"] intValue];
        NSUInteger commentID = [[commentAction objectForKey:@"comment_id"] intValue];
        
        [self.sendReplyButton setEnabled:NO];
        [[WordPressComApi sharedApi] replyToComment:blogID forCommentID:commentID withReply:replyText success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.sendReplyButton setEnabled:YES];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.sendReplyButton setEnabled:YES];
        }];
    }
    
}

- (void)startReply:(id)sender {
    [self.replyTextView becomeFirstResponder];
}

- (void)cancelReply:(id)sender {
    self.writingReply = NO;
    [self.replyTextView resignFirstResponder];
}

- (void)publishReply:(id)sender {

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
            NSIndexPath *commentIndexPath = [NSIndexPath indexPathForRow:0  inSection:section];
            CGFloat oldCommentHeight = [self tableView:self.tableView heightForRowAtIndexPath:commentIndexPath];
            comment.commentData = responseObject;
            comment.loading = NO;
            
            
            // if we're at the top of the tableview, we'll animate in the new parent
            id parent = [responseObject objectForKey:@"parent"];
            NoteComment *parentComment;
            if (![parent isEqual:@0]) {
                parentComment = [[NoteComment alloc] initWithCommentID:[parent valueForKey:@"ID"]];
                self.tableView.backgroundColor = [NoteCommentCell darkBackgroundColor];
            }
            
            CGPoint offset = self.tableView.contentOffset;
            
            if (offset.y <= 0.f && section == [self.commentThread count] - 1) {
                
                // animate
                [self.tableView beginUpdates];
                
//                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
                
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:section]] withRowAnimation:UITableViewRowAnimationAutomatic];

                if (parentComment) {
                    [self.commentThread insertObject:parentComment atIndex:0];
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
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
                    offsetFix += [self tableView:self.tableView heightForFooterInSection:0] + [self tableView:self.tableView heightForRowAtIndexPath:parentIndexPath];
                    
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"NoteCommentCell";
    NoteCommentCell *cell = (NoteCommentCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil){
        cell = [[NoteCommentCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:cellIdentifier];
    }
    cell.delegate = self;
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.section];
    if (indexPath.section == [self.commentThread count]-1) {
        // it's the main comment
        cell.imageView.hidden = NO;
        cell.avatarURL = [NSURL URLWithString:self.note.icon];
        cell.followButton = self.followButton;
        if (!comment.isLoaded) {
            return cell;
        }
        
    } else {
        // it's a parent comment
        [cell displayAsParentComment];
        if (!comment.isLoaded) {
            cell.imageView.hidden = YES;
            [cell showLoadingIndicator];
            return cell;
        } else {
            cell.imageView.hidden = NO;
            cell.avatarURL = [NSURL URLWithString:[comment.commentData valueForKeyPath:@"author.avatar_URL"]];
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.section];
    if (comment.needsData) {
        [self updateCommentThread];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self.commentThread count]-1) {
        // last comment, no reply indicator
        return 0.f;
    } else {
        return 18.f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == [self.commentThread count]-1) {
        return nil;
    } else {
        UIImage *footerImage;
        if (section < [self.commentThread count]-2) {
            footerImage = [UIImage imageNamed:@"note-comment-grandparent-footer"];
        } else {
            footerImage = [UIImage imageNamed:@"note-comment-parent-footer"];
        }
        UIImage *image = [footerImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 68.f, 5.f, 0.f)];
        UIImageView *indicator = [[UIImageView alloc] initWithImage:image];
        indicator.backgroundColor = [UIColor clearColor];
        return indicator;
    }

}

// the height of the comments
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteComment *comment = [self.commentThread objectAtIndex:indexPath.section];
    if (indexPath.section == [self.commentThread count]-1) {
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
            return 30.f;
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
