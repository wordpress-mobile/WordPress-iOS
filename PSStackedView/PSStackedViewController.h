//
//  SVStackRootController.h
//  PSStackedView
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSStackedViewGlobal.h"
#import "PSStackedViewDelegate.h"

/// grid snapping options
enum {
    SVSnapOptionNearest,
    SVSnapOptionLeft,
    SVSnapOptionRight
} typedef PSSVSnapOption;

/// StackController hosing a backside rootViewController and the stacked controllers
@interface PSStackedViewController : UIViewController

/// the root controller gets the whole background view
- (id)initWithRootViewController:(UIViewController *)rootViewController;

/// Uses a horizontal slide transition. Has no effect if the view controller is already in the stack.
/// baseViewController is used to remove subviews if a previous controller invokes a new view. can be nil.
- (void)pushViewController:(UIViewController *)viewController fromViewController:(UIViewController *)baseViewController animated:(BOOL)animated;

/// pushes the view controller, sets the last current vc as parent controller
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// remove top view controller from stack, return it
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;

/// remove specific view controller. returns false if controller is not on top of stack
- (BOOL)popViewController:(UIViewController *)controller animated:(BOOL)animated;

/// remove view controllers until 'viewController' is found
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// removes all view controller
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;

/// return all controllers of certain class
- (NSArray *)controllersForClass:(Class)theClass;

/// can we collapse (= hide) view controllers? Only collapses until screen width is used
- (NSUInteger)canCollapseStack;

/// can the stack be further expanded (are some views stacked?)
- (NSUInteger)canExpandStack;

/// moves view controller stack to the left, potentially hiding older VCs (increases firstVisibleIndex)
- (NSUInteger)collapseStack:(NSInteger)steps animated:(BOOL)animated;

/// move view controller stack to the right, showing older VCs (decreases firstVisibleIndex)
- (NSUInteger)expandStack:(NSInteger)steps animated:(BOOL)animated;

/// align stack to nearest grid
- (void)alignStackAnimated:(BOOL)animated;

/// expands/collapses stack until entered index is topmost right
- (void)displayViewControllerIndexOnRightMost:(NSInteger)index animated:(BOOL)animated;

/// expands/collapses stack until entered controller is topmost right
- (BOOL)displayViewControllerOnRightMost:(UIViewController *)vc animated:(BOOL)animated;

/// return view controllers that follow a certain view controller. Helper function.
- (NSArray *)viewControllersAfterViewController:(UIViewController *)viewController;

/// index of current view controller. Supports search within UINavigationControllers.
- (NSInteger)indexOfViewController:(UIViewController *)viewController;

/// event delegate
@property(nonatomic, unsafe_unretained) id<PSStackedViewDelegate> delegate;

/// root view controller, always displayed behind stack
@property(nonatomic, strong, readonly) UIViewController *rootViewController;

/// The top(last) view controller on the stack.
@property(nonatomic, readonly, strong) UIViewController *topViewController;

/// first view controller
@property(nonatomic, readonly, strong) UIViewController *firstViewController;

/// represents current state via floating point. shows edge attaches, menu docking, etc
@property(nonatomic, readonly, assign) CGFloat floatIndex;

/// view controllers visible. NOT KVO compliant, is calculated on demand.
@property(nonatomic, readonly, strong) NSArray *visibleViewControllers;

@property(nonatomic, readonly, strong) NSArray *fullyVisibleViewControllers;

/// index of first currently visible view controller [calculated]
@property(nonatomic, assign, readonly) NSInteger firstVisibleIndex;

/// index of last currently visible view controller [calculated]
@property(nonatomic, assign, readonly) NSInteger lastVisibleIndex;

/// array of all current view controllers, sorted
@property(nonatomic, strong, readonly) NSArray *viewControllers;

/// pangesture recognizer used
@property(nonatomic, strong) UIPanGestureRecognizer *panRecognizer;

/// enable if you show another object in fullscreen, but stacked view still thinks it's displayed
/// reduces animations to a minimum to get smoother reactions on frontmost view.
@property(nonatomic, assign, getter=isReducingAnimations) BOOL reduceAnimations;

/// left inset thats always visible. Defaults to 60.
@property(nonatomic, assign) NSUInteger leftInset;
/// animate setting of the left inset that is always visible
- (void)setLeftInset:(NSUInteger)leftInset animated:(BOOL)animated;

/// large left inset. is visible to show you the full menu width. Defaults to 200.
@property(nonatomic, assign) NSUInteger largeLeftInset;
/// animate setting of large left inset
- (void)setLargeLeftInset:(NSUInteger)largeLeftInset animated:(BOOL)animated;

// compatibility with UINavigationBar -- returns nil
#ifdef ALLOW_SWIZZLING_NAVIGATIONCONTROLLER
@property(nonatomic, assign) UINavigationBar *navigationBar;
#endif

@end
