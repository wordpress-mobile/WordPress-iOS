#import <Foundation/Foundation.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

/**
 *  @class      WPCrashlytics
 *  @brief      This module contains the crashlytics logic for WPiOS.
 */
@interface WPCrashlytics : NSObject

#pragma mark - Init

- (instancetype)initWithAPIKey:(NSString *)apiKey;

#pragma mark - User Opt Out

/**
 *  @brief      Call this method to know if the user has opted out of Crashlytics tracking.
 *
 *  @returns    YES if the user has opted out, NO otherwise.
 */
+ (BOOL)userHasOptedOut;

/**
 *  @brief      Sets user opt out ON or OFF
 *
 *  @param      optedOut   The new status for user opt out.
 */
- (void)setUserHasOptedOut:(BOOL)optedOut;

@end
