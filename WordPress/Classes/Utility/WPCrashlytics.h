#import <Foundation/Foundation.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

/**
 *  @class      WPCrashlytics
 *  @brief      This module contains the crashlytics logic for WPiOS.
 */
@interface WPCrashlytics : NSObject

- (instancetype)initWithAPIKey:(NSString *)apiKey;

@end
