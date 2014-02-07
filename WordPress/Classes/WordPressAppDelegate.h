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
@class AbstractPost;
@class Simperium;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) ReaderPostsViewController *readerPostsViewController;
@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) Reachability *wpcomReachability;
@property (nonatomic, assign) BOOL isWPcomAuthenticated;
@property (nonatomic, assign) BOOL connectionAvailable;
@property (nonatomic, assign) BOOL wpcomAvailable;
@property (nonatomic, strong, readonly) DDFileLogger *fileLogger;
@property (nonatomic, strong, readonly) Simperium *simperium;

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

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
- (void)showBlogListTab;
- (void)showReaderTab;
- (void)showMeTab;
- (void)showPostTab;
- (void)switchTabToPostsListForPost:(AbstractPost *)post;
- (void)clearBadgeAndSyncItemsIfNotificationsScreenActive;

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;

@end
