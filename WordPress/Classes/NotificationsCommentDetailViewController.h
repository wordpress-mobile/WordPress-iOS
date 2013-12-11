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

@class IOS7CorrectedTextView;

@interface NotificationsCommentDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) WordPressComApi *user;

@property (nonatomic, weak) IBOutlet UILabel *authorLabel;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *approveBarButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *unapproveBarButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *trashBarButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *spamBarButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *replyBarButton;

@property (nonatomic, weak) IBOutlet IOS7CorrectedTextView *replyTextView;
@property (nonatomic, weak) IBOutlet UIImageView *replyBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIView *tableFooterView;
@property (nonatomic, weak) IBOutlet UIView *replyActivityView;
@property (nonatomic, weak) IBOutlet UIImageView *noteImageView;

@property (nonatomic, weak) IBOutlet NoteCommentPostBanner *postBanner;
@property (nonatomic, weak) IBOutlet UITableViewCell *disclosureIndicator;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) FollowButton *followButton;

@property (nonatomic, strong) Note *note;

@property (nonatomic, weak) IBOutlet UILabel *replyPlaceholder;
@property (nonatomic, weak) IBOutlet UINavigationBar *replyNavigationBar;
@property (nonatomic, weak) IBOutlet UINavigationItem *replyNavigationItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *replyCancelBarButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *replyPublishBarButton;


@end
