//
//  NotificationsDetailViewController.h
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Note.h"

@interface NotificationsDetailViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *authorLabel;

@property (nonatomic, strong) IBOutlet UIButton *followButton;
@property (nonatomic, strong) IBOutlet UIButton *approveButton;
@property (nonatomic, strong) IBOutlet UIButton *trashButton;
@property (nonatomic, strong) IBOutlet UIButton *spamButton;
@property (nonatomic, strong) IBOutlet UIButton *replyButton;
@property (nonatomic, strong) IBOutlet UIButton *sendReplyButton;

@property (nonatomic, strong) IBOutlet UITextView *commentTextView;
@property (nonatomic, strong) IBOutlet UITextView *replyTextView;

@property (nonatomic, strong) IBOutlet UIImageView *noteImageView;

@property (nonatomic, strong) Note *note;

- (IBAction) followBlog;
- (IBAction) moderateComment: (id)sender;
- (IBAction) replyToComment;
- (void)setFollowButtonState:(bool)isFollowing;

@end
