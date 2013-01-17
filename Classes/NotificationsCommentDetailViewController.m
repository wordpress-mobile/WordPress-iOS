//
//  NotificationsDetailViewController.m
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsCommentDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h"
#import "UIBarButtonItem+Styled.h"
#import <QuartzCore/QuartzCore.h>

#define APPROVE_BUTTON_TAG 1
#define TRASH_BUTTON_TAG 2
#define SPAM_BUTTON_TAG 3

@interface NotificationsCommentDetailViewController ()

@property NSUInteger followBlogID;
@property BOOL isFollowingBlog, canApprove, canTrash, canSpam;
@property NSArray *commentActions;
@property NSDictionary *followDetails;

@end

@implementation NotificationsCommentDetailViewController

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
    
    _replyTextView.layer.borderColor = [[UIColor UIColorFromHex:0x464646] CGColor];
    _replyTextView.layer.borderWidth = 1.0f;
    _replyTextView.layer.cornerRadius = 5;
    _replyTextView.clipsToBounds = YES;
    
    //set toolbar items
    UIBarButtonItem *approveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_approve"] style:UIBarButtonItemStylePlain target:self action:@selector(moderateComment:)];
    [approveButton.customView setTag:APPROVE_BUTTON_TAG];
    [approveButton setEnabled:NO];
    UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_delete"] style:UIBarButtonItemStylePlain target:self action:@selector(moderateComment:)];
    [trashButton.customView setTag:TRASH_BUTTON_TAG];
    [trashButton setEnabled:NO];
    UIBarButtonItem *spamButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_flag"] style:UIBarButtonItemStylePlain target:self action:@selector(moderateComment:)];
    [spamButton.customView setTag:SPAM_BUTTON_TAG];
    [spamButton setEnabled:NO];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [_toolbar setItems: [NSArray arrayWithObjects:approveButton, spacer, trashButton, spacer, spamButton, nil]];
    
    [self displayNote];
}

- (void)displayNote {
    if (_note && _note.isComment) {
        self.title = _note.subject;
        [_authorLabel setHidden:NO];
        [_commentTextView setHidden:NO];
        [_noteImageView setHidden:NO];
        
        _authorLabel.text = _note.subject;
        _commentTextView.text = _note.commentText;
        [_noteImageView setImageWithURL:[NSURL URLWithString:_note.icon]
                       placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
        
        // Set the status of the comment buttons
        _commentActions = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"actions"];
        for (int i=0; i < [_commentActions count]; i++) {
            NSDictionary *commentAction = [_commentActions objectAtIndex:i];
            NSString *commentType = [commentAction objectForKey:@"type"];
            
            UIButton *approveButton = (UIButton*)[[[_toolbar items] objectAtIndex:0] customView];
            UIButton *trashButton = (UIButton*)[[[_toolbar items] objectAtIndex:2] customView];
            UIButton *spamButton = (UIButton*)[[[_toolbar items] objectAtIndex:4] customView];
            
            if ([commentType isEqualToString:@"replyto-comment"]) {
                //[_replyButton setHidden:NO];
            } else if ([commentType isEqualToString:@"approve-comment"]) {
                [approveButton setEnabled:YES];
                [approveButton setImage:[UIImage imageNamed:@"toolbar_approve"] forState:UIControlStateNormal];
                _canApprove = YES;
            } else if ([commentType isEqualToString:@"unapprove-comment"]) {
                [approveButton setEnabled:YES];
                [approveButton setImage:[UIImage imageNamed:@"toolbar_unapprove"] forState:UIControlStateNormal];
                _canApprove = NO;
            } else if ([commentType isEqualToString:@"spam-comment"]) {
                [spamButton setEnabled:YES];
                _canSpam = YES;
            } else if ([commentType isEqualToString:@"unspam-comment"]) {
                [spamButton setEnabled:YES];
                _canSpam = NO;
            } else if ([commentType isEqualToString:@"trash-comment"]) {
                [trashButton setEnabled:YES];
                _canTrash = YES;
            } else if ([commentType isEqualToString:@"untrash-comment"]) {
                [trashButton setEnabled:YES];
                _canTrash = NO;
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
            if ([[followResponse objectForKey:@"is_following"] intValue] == 1) {
                _isFollowingBlog = YES;
                [self setFollowButtonState:_isFollowingBlog];
                if (self.panelNavigationController)
                    [self.panelNavigationController showToastWithMessage:NSLocalizedString(@"Followed", @"User followed a blog") andImage:[UIImage imageNamed:@"action_icon_followed"]];
            } else {
                _isFollowingBlog = NO;
                [self setFollowButtonState:_isFollowingBlog];
                if (self.panelNavigationController)
                    [self.panelNavigationController showToastWithMessage:NSLocalizedString(@"Unfollowed", @"User unfollowed a blog") andImage:[UIImage imageNamed:@"action_icon_unfollowed"]];
            }
            if (_followDetails)
                [_followDetails setValue:[NSNumber numberWithBool:_isFollowingBlog] forKey:@"is_following"];
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
        if (_canApprove)
            commentStatus = @"approved";
        else
            commentStatus = @"unapproved";
    } else if (button.tag == SPAM_BUTTON_TAG) {
        if (_canSpam) 
            commentStatus = @"spam";
        else 
            commentStatus = @"unspam";
    } else if (button.tag == TRASH_BUTTON_TAG) {
        if (_canTrash)
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
    if (isFollowing) {
        [_followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_followButton setImage:[UIImage imageNamed:@"note_button_icon_following"] forState:UIControlStateNormal];
        [_followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [_followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
    } else {
        [_followButton setTitleColor:[UIColor UIColorFromHex:0x1A1A1A] forState:UIControlStateNormal];
        [_followButton setImage:[UIImage imageNamed:@"note_button_icon_follow"] forState:UIControlStateNormal];
        [_followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [_followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
    }
    CGSize textSize = [[_followButton.titleLabel text] sizeWithFont:[_followButton.titleLabel font]];
    CGFloat buttonWidth = textSize.width + 40.0f;
    if (buttonWidth > 180.0f)
        buttonWidth = 180.0f;
    [_followButton setFrame:CGRectMake(_followButton.frame.origin.x, _followButton.frame.origin.y, buttonWidth, 30.0f)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
