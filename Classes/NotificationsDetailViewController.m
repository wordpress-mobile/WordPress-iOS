//
//  NotificationsDetailViewController.m
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressComApi.h"

#define APPROVE_BUTTON_TAG 1
#define SPAM_BUTTON_TAG 2
#define TRASH_BUTTON_TAG 3

@interface NotificationsDetailViewController ()

@property NSUInteger followBlogID;
@property bool isFollowingBlog;
@property NSArray *commentActions;

@end

@implementation NotificationsDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Notification", @"Title for notification detail view");
    }
    return self;
}

- (void)setNote:(Note *)note {
    if (note != _note) {
        _note = note;
    }
    self.title = note.subject;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_note && _note.isComment) {
        
        _authorLabel.text = _note.subject;
        _commentTextView.text = _note.commentText;
        [_noteImageView setImageWithURL:[NSURL URLWithString:_note.icon]
                       placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
        
        // Show Follow button if user has a blog that can or already is being followed
        NSDictionary *followItem = [[[[[_note getNoteData] objectForKey:@"body"] objectForKey:@"items"] objectAtIndex:0] objectForKey:@"action"];
        if (followItem) {
            NSString *noteType = [followItem objectForKey:@"type"];
            if (noteType && [noteType isEqualToString:@"follow"]) {
                [_followButton setHidden:NO];
                NSDictionary *followDetails = [followItem objectForKey:@"params"];
                if ([[followDetails objectForKey:@"is_following"] intValue] == 1)
                    _isFollowingBlog = YES;
                [self setFollowButtonState:_isFollowingBlog];
                
                _followBlogID = [[followDetails objectForKey:@"blog_id"] integerValue];
            }
        }
        
        // Set the status of the comment buttons
        _commentActions = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"actions"];
        for (int i=0; i < [_commentActions count]; i++) {
            NSDictionary *commentAction = [_commentActions objectAtIndex:i];
            
            if ([[commentAction objectForKey:@"type"] isEqualToString:@"replyto-comment"]) {
                [_replyButton setHidden:NO];
            } else if ([[commentAction objectForKey:@"type"] isEqualToString:@"approve-comment"]) {
                [_approveButton setHidden:NO];
                [_approveButton setTitle:NSLocalizedString(@"Approve", @"") forState:UIControlStateNormal];
            } else if ([[commentAction objectForKey:@"type"] isEqualToString:@"unapprove-comment"]) {
                [_approveButton setHidden:NO];
                [_approveButton setTitle:NSLocalizedString(@"Unapprove", @"") forState:UIControlStateNormal];
            } else if ([[commentAction objectForKey:@"type"] isEqualToString:@"spam-comment"]) {
                [_spamButton setHidden:NO];
            } else if ([[commentAction objectForKey:@"type"] isEqualToString:@"trash-comment"]) {
                [_trashButton setHidden:NO];
            }
        }
        
    }
}

- (IBAction)followBlog {
    [self setFollowButtonState:!_isFollowingBlog];
    [[WordPressComApi sharedApi] followBlog:_followBlogID isFollowing:_isFollowingBlog success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _isFollowingBlog = !_isFollowingBlog;
        NSDictionary *followResponse = (NSDictionary *)responseObject;
        if (followResponse && [[followResponse objectForKey:@"success"] intValue] == 1) {
            if ([[followResponse objectForKey:@"is_following"] intValue] == 1)
                _isFollowingBlog = YES;
            else
                _isFollowingBlog = NO;
            [self setFollowButtonState:_isFollowingBlog];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self setFollowButtonState:_isFollowingBlog];
    }];
}

- (IBAction)moderateComment:(id)sender {
    
    if (!_commentActions || [_commentActions count] < 1)
        return;
    
    // Get blog_id and comment_id for api call
    NSDictionary *commentAction = [[_commentActions objectAtIndex:0] objectForKey:@"params"];
    NSUInteger blogID = [[commentAction objectForKey:@"blog_id"] intValue];
    NSUInteger commentID = [[commentAction objectForKey:@"comment_id"] intValue];
    
    if (!blogID || !commentID)
        return;
    
    UIButton *button = (UIButton *)sender;
    NSString *commentStatus = @"approved";
    if (button.tag == APPROVE_BUTTON_TAG) {
        if ([[button titleForState:UIControlStateNormal] isEqualToString:NSLocalizedString(@"Unapprove", @"")]) {
            [_approveButton setTitle:NSLocalizedString(@"Approve", @"") forState:UIControlStateNormal];
            commentStatus = @"unapproved";
        } else {
            [_approveButton setTitle:NSLocalizedString(@"Unapprove", @"") forState:UIControlStateNormal];
            commentStatus = @"approved";
        }
    } else if (button.tag == SPAM_BUTTON_TAG) {
        commentStatus = @"spam";
    } else if (button.tag == TRASH_BUTTON_TAG) {
        commentStatus = @"trash";
    }
    
    [button setEnabled:NO];
    
    [[WordPressComApi sharedApi] moderateComment:blogID forCommentID:commentID withStatus:commentStatus success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [button setEnabled:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [button setEnabled:YES];
    }];
    
}

- (IBAction)replyToComment {
    NSString *replyText = _replyTextView.text;
    
    if ([replyText length] > 0) {
        
        // Get blog_id and comment_id for api call
        NSDictionary *commentAction = [[_commentActions objectAtIndex:0] objectForKey:@"params"];
        NSUInteger blogID = [[commentAction objectForKey:@"blog_id"] intValue];
        NSUInteger commentID = [[commentAction objectForKey:@"comment_id"] intValue];
        
        [_sendReplyButton setEnabled:NO];
        [[WordPressComApi sharedApi] replyToComment:blogID forCommentID:commentID withReply:replyText success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [_sendReplyButton setEnabled:YES];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [_sendReplyButton setEnabled:YES];
        }];
    }
    
}

- (void)setFollowButtonState:(bool)isFollowing {
    [_followButton setTitle:(isFollowing) ? NSLocalizedString(@"Unfollow", @"") : NSLocalizedString(@"Follow", @"") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
