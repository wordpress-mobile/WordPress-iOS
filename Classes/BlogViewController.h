//
//  BlogViewController.h
//  WordPress
//
//  Created by Josh Bassett on 8/07/09.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "PostsViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"
#import "StatsTableViewController.h"

@interface BlogViewController : UIViewController <UITabBarControllerDelegate, UIAccelerometerDelegate> {
    IBOutlet UITabBarController *tabBarController;
    IBOutlet PostsViewController *postsViewController;
    IBOutlet PagesViewController *pagesViewController;
    IBOutlet CommentsViewController *commentsViewController;
	IBOutlet StatsTableViewController *statsTableViewController;
    IBOutlet UISplitViewController *splitViewController;
	BOOL stateRestored;
    Blog *blog;
}

@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) Blog *blog;
@property (nonatomic, retain) UIViewController *selectedViewController;

- (void)reselect;
- (void)saveState;
- (void)restoreState;
- (void)refreshBlogs:(NSNotification *)notification;
- (void)configureCommentsTab;

@end
