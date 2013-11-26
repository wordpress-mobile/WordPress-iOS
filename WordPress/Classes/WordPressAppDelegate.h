/*
 * WordPressAppDelegate.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


@class Reachability;
@class DDFileLogger;
@class ReaderPostsViewController;
@class BlogListViewController;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;
@property (nonatomic, assign) BOOL isWPcomAuthenticated;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) ReaderPostsViewController *readerPostsViewController;
@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (strong, nonatomic) DDFileLogger *fileLogger;
@property (nonatomic, strong) Reachability *internetReachability, *wpcomReachability;
@property (nonatomic, assign) BOOL connectionAvailable, wpcomAvailable;

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

///--------------------
/// @name Global Alerts
///--------------------
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showNotificationErrorAlert:(NSNotification *)notification;


///---------------------------
/// @name User agent switching
///---------------------------
- (void)useDefaultUserAgent;
- (void)useAppUserAgent;
- (NSString *)applicationUserAgent;

///-----------------------
/// @name Tab bar controls
///-----------------------
- (void)showNotificationsTab;

- (void)showNotificationsTab;
- (void)showBlogListTab;
- (void)showReaderTab;

@end
