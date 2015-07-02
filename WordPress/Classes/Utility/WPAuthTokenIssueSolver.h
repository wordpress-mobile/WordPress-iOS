#import <Foundation/Foundation.h>

typedef void(^WPAuthTokenissueSolverCompletionBlock)();

/**
 *  @class      WPAuthTokenIssueSolver
 *  @brief      This class exists for the sole purpose of fixing the missing-auth-token issue in
 *              WPiOS 5.3.
 *  @details    Read this: https://github.com/wordpress-mobile/WordPress-iOS/issues/3964
 */
@interface WPAuthTokenIssueSolver : NSObject

/**
 *  @brief      Fixes the authToken issue.
 *
 *  @param      onComplete      The block to execute once the issues are solved.  Will be executed
 *                              also if there's no issue to solve at all.
 *
 *  @returns    YES if the authToken issue is being fixed.  NO otherwise.  Useful to inhibit the
 *              app's state restoration.
 */
- (BOOL)fixAuthTokenIssueAndDo:(WPAuthTokenissueSolverCompletionBlock)onComplete;

@end
