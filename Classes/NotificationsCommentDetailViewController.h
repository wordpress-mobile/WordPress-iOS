//
//  NotificationsDetailViewController.h
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Note.h"
#import "WordPressComApi.h"
#import "NoteCommentPostBanner.h"
#import "FollowButton.h"

@interface NotificationsCommentDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) WordPressComApi *user;

@property (nonatomic, strong) IBOutlet UILabel *authorLabel;

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) IBOutlet UIButton *sendReplyButton;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *approveBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *trashBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *spamBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *replyBarButton;

@property (nonatomic, strong) IBOutlet UITextView *replyTextView;

@property (nonatomic, strong) IBOutlet UIImageView *noteImageView;

@property (nonatomic, strong) IBOutlet NoteCommentPostBanner *postBanner;

@property (nonatomic, strong) IBOutlet UITextView *replyField;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) FollowButton *followButton;

@property (nonatomic, strong) Note *note;

- (IBAction)toggleApproval:(id)sender;
- (IBAction)deleteComment:(id)sender;
- (IBAction)markAsSpam:(id)sender;
- (IBAction)replyToComment:(id)sender;
- (IBAction)moderateComment:(id)sender;

- (IBAction)visitPostURL:(id)sender;
- (void)displayNote;

@end
