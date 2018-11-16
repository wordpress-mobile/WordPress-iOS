#import <UIKit/UIKit.h>


@interface UIApplication (Helpers)

/// Returns *true* when the Unit Test Suite is running the app.
///
- (BOOL)isRunningTestSuite;

/// Returns *true* when the Screenshot Generation Suite is running the app.
///
- (BOOL)isCreatingScreenshots;

@end

