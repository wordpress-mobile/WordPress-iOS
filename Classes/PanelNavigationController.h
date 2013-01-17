//
//  PanelNavigationController.h
//  WordPress
//
//  Created by Jorge Bernal on 5/21/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - Protocol setup
@protocol DetailViewDelegate <NSObject>
- (void) resetView;
@end

@interface PanelNavigationController : UIViewController {
    id <DetailViewDelegate> __weak delegate;
}

@property (nonatomic, weak) id <DetailViewDelegate> delegate;

#pragma mark - Initialization

- (id)initWithDetailController:(UIViewController *)detailController masterViewController:(UIViewController *)masterController;

#pragma mark - Navigation methods
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated; // Uses a horizontal slide transition. Has no effect if the view controller is already in the stack.
- (void)pushViewController:(UIViewController *)viewController fromViewController:(UIViewController *)fromViewController animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated; // Returns the popped controller.
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated; // Pops view controllers until the one specified is on top. Returns the popped controllers.
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated; // Pops until there's only a single view controller left on the stack. Returns the popped controllers.

- (void)closeSidebar;
- (void)showSidebar;
- (void)toggleSidebar;
- (void)teaseSidebar;
- (void)clearDetailViewController;

// Notifications
- (void)didReceiveNotesNotification: (NSNotification *)notification;
- (void)showNotificationForNoteType: (NSString *)noteType;
- (void)showNotificationButton;
- (void)resetMenuButton: (id)sender;
- (void)highlightMenuButton: (id)sender;
- (void)completeButtonAnimation;
- (void)showNotificationForNoteType: (NSString *)noteType;
- (void)showNotificationsView;
- (bool)isShowingNotificationButton;

- (UIToolbar *)toolbarForViewController:(UIViewController *)controller;
- (BOOL)isToolbarHiddenForViewController:(UIViewController *)controller;
- (void)setToolbarHidden:(BOOL)hidden forViewController:(UIViewController *)controller;
- (void)setToolbarHidden:(BOOL)hidden forViewController:(UIViewController *)controller animated:(BOOL)animated;
- (void)viewControllerWantsToBeFullyVisible:(UIViewController *)controller;

#pragma mark - Controllers
@property(nonatomic,strong) UIViewController *detailViewController; // The first detail controller
- (void)setDetailViewController:(UIViewController *)detailViewController closingSidebar:(BOOL)closingSidebar;
@property(nonatomic,strong) UIViewController *masterViewController; // The sidebar (left) controller
@property(nonatomic,readonly,strong) UINavigationController *navigationController; // The navigation controller on iPhone.
@property(nonatomic,readonly,strong) UIViewController *rootViewController; // The navigation controller on iPhone, masterViewController on iPad
@property(nonatomic,readonly,strong) UIViewController *topViewController; // The top view controller on the stack.
@property(nonatomic,readonly,strong) UIViewController *visibleViewController; // Return modal view controller if it exists. Otherwise the top view controller.

@property(nonatomic,readonly,copy) NSArray *viewControllers; // The current view controller stack.

@end

#pragma mark - UIViewController extensions

@interface UIViewController (PanelNavigationController)
@property(nonatomic,readonly,retain) PanelNavigationController* panelNavigationController;
@end