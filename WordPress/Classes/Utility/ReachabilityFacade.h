#import <Foundation/Foundation.h>

/**
 *  This protocol represents a class that handles a few things related to whether the internet is available or not.
 */
@protocol ReachabilityFacade <NSObject>

/**
 *  Indicates whether we have an internet connection
 *
 *  @return whether the internet is available or not.
 */
- (BOOL)isInternetReachable;

/**
 *  Displays an error message when there is no internet connection
 */
- (void)showAlertNoInternetConnection;

/**
 *  Displays an error message when there is no internet connection but also allows for a retry attempt.
 *
 *  @param retryBlock a block that will get called if the user indicates they want to retry the network request.
 */
- (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock;

@end

/**
 *  This class handles a few things related to whether the internet is available or not.
 */
@interface ReachabilityFacade : NSObject <ReachabilityFacade>

@end
