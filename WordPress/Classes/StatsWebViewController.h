//
//  StatsWebViewController.h
//
//  Created by Eric Johnson on 5/31/12.
//

#import "WPChromelessWebViewController.h"

@class Blog;

#define kSelectedBlogChanged @"kSelectedBlogChanged"

@interface StatsWebViewController : WPChromelessWebViewController <UIAlertViewDelegate> {
    Blog *blog;
    BOOL authed;
}

@property (nonatomic, strong) Blog *blog;

- (void)setBlog:(Blog *)blog;

- (void)initStats;
- (void)promptForCredentials;
- (void)authStats;
- (void)loadStats;

@end
