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

@interface WPReaderViewController : WPWebAppViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, WPReaderTopicsViewControllerDelegate> {
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

- (void)setSelectedTopic:(NSString *)topicId;
- (void)setupTopics;

@end
