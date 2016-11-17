#import <UIKit/UIKit.h>


@interface UIApplication (Helpers)

/// Returns *true* when the app is being executed in the iOS Simulator.
/// Although this check can be just performed inline, we *really* need this in the Swift realm,
/// where preprocessor macros are missing.
///
- (BOOL)isRunningSimulator;

/// Returns *true* when the Unit Test Suite is running the app.
///
- (BOOL)isRunningTestSuite;

@end
