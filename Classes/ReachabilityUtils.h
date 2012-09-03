//
//  ReachabilityUtils.h
//  WordPress
//
//  Created by Eric on 8/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReachabilityUtils : NSObject

+ (BOOL)isInternetReachable;
+ (void)showAlertNoInternetConnection;
+ (void)showAlertNoInternetConnectionWithDelegate:(id)delegate;

@end
