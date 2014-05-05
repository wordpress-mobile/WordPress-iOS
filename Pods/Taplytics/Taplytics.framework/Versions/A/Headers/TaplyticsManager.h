//
//  TaplyticsManager.h
//  Taplytics
//
//  Copyright (c) 2014 Syrp Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    TLDev,
    TLProduction,
    TLLocalHost,
    TLLocalTest
} TLServer;

__deprecated
/**
 DEPRECATED please use same methods in Taplytics.h
 */
@interface TaplyticsManager : NSObject

// Start Taplytics With API Key Methods
+ (void)startTaplyticsAPIKey:(NSString*)apiKey;

+ (void)startTaplyticsAPIKey:(NSString*)apiKey liveUpdate:(BOOL)liveUpdate;

+ (void)startTaplyticsAPIKey:(NSString*)apiKey server:(TLServer)server;

+ (void)startTaplyticsAPIKey:(NSString*)apiKey server:(TLServer)server liveUpdate:(BOOL)liveUpdate;



#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000

// Update Taplytics Properties in Background, only iOS7 and later
+ (void)performBackgroundFetch:(void(^)(UIBackgroundFetchResult))completionBlock;

#endif

@end
