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

@interface NotificationsCommentDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) WordPressComApi *user;

@property (nonatomic, strong) IBOutlet UILabel *authorLabel;

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *approveBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *unapproveBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *trashBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *spamBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *replyBarButton;

@property (nonatomic, strong) IBOutlet UITextView *replyTextView;
@property (nonatomic, strong) IBOutlet UIImageView *replyBackgroundImageView;
@property (nonatomic, strong) IBOutlet UIView *tableFooterView;
@property (nonatomic, strong) IBOutlet UIView *replyActivityView;
@property (nonatomic, strong) IBOutlet UIImageView *noteImageView;

@property (nonatomic, strong) IBOutlet NoteCommentPostBanner *postBanner;

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) FollowButton *followButton;

@property (nonatomic, strong) Note *note;

@property (nonatomic, strong) IBOutlet UILabel *replyPlaceholder;
@property (nonatomic, strong) IBOutlet UINavigationBar *replyNavigationBar;
@property (nonatomic, strong) IBOutlet UINavigationItem *replyNavigationItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *replyCancelBarButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *replyPublishBarButton;

- (IBAction)moderateComment:(id)sender;
- (IBAction)cancelReply:(id)sender;
- (IBAction)publishReply:(id)sender;
- (IBAction)startReply:(id)sender;

- (IBAction)visitPostURL:(id)sender;
- (void)displayNote;
- (NSString *)increaseGravatarSizeForURL:(NSString *)originalURL;

@end
