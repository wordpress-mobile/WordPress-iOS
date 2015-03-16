//
//  ReachabilityService.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 3/16/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ReachabilityService <NSObject>

- (BOOL)isInternetReachable;
- (void)showAlertNoInternetConnection;
- (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock;

@end

@interface ReachabilityService : NSObject <ReachabilityService>

@end
