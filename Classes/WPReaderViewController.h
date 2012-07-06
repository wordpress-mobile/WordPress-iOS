//
//  WPReaderViewController.h
//  WordPress
//
//  Created by Danilo Ercoli on 10/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "EGORefreshTableHeaderView.h"
#import "WPReaderTopicsViewController.h"
#import "WPReaderDetailViewController.h"
#import "WPFriendFinderNudgeView.h"

@interface WPReaderViewController : WPWebAppViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, WPReaderTopicsViewControllerDelegate, WPReaderDetailViewControllerDelegate> {
    BOOL needsLogin;
    NSTimer *statusTimer;   // This timer checks the nav buttons every 0.75 seconds, and updates them
    NSTimer *refreshTimer; 
}
@property (nonatomic,retain) NSURL *url;
@property (nonatomic,retain) NSString *username;
@property (nonatomic,retain) NSString *password;
@property (nonatomic,retain) NSString *detailContentHTML;
@property (nonatomic, retain) IBOutlet UINavigationBar *iPadNavBar;
@property (retain, nonatomic) NSTimer *refreshTimer;
@property (nonatomic, retain) WPReaderTopicsViewController *topicsViewController;
@property (nonatomic, retain) WPFriendFinderNudgeView *friendFinderNudgeView;
@property (nonatomic, retain) UILabel *titleLabel;

- (void)setSelectedTopic:(NSString *)topicId;
- (void)setupTopics;
- (void)showArticleDetails:(id)article;

- (void)showFriendFinderNudgeView:(id)sender;
- (void)hideFriendFinderNudgeView:(id)sender;
- (void)openFriendFinder:(id)sender;



@end
