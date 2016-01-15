#import <UIKit/UIKit.h>


@interface UIApplication (Helpers)

/**
 *  @details    Returns *true* when the app is being executed in the iOS Simulator.
 *              Although this check can be just performed inline, we *really* need this in the
 *              Swift real, where preprocessor macros are missing.
 */
- (BOOL)isRunningSimulator;


/**
 *  @details    Returns *true* when the target used to build the app, contains the *ALPHA_BUILD* flag.
 *              Same as the *isRunningSimulator*, this helper is meant for Swift consumption, primary.
 */
- (BOOL)isAlphaBuild;

@end
