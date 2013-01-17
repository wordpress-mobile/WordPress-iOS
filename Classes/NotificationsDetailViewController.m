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

@interface NotificationsDetailViewController ()

@property NSUInteger followBlogID;
@property bool isFollowingBlog;

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
    
    if (_note) {
        _authorLabel.text = _note.subject;
        _commentTextView.text = _note.commentText;
        [_noteImageView setImageWithURL:[NSURL URLWithString:_note.icon]
                       placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
        
        // sort out the following button
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
        
    }
}

- (IBAction) followBlog {
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

- (void)setFollowButtonState:(bool)isFollowing {
    [_followButton setTitle:(isFollowing) ? NSLocalizedString(@"Unfollow", @"") : NSLocalizedString(@"Follow", @"") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
