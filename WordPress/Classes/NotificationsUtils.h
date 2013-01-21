//
//  NotificationsUtils.h
//  WordPress
//
//  Created by Danilo Ercoli on 21/01/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationsUtils : NSObject


+ (void)pingStats:(NSString*)statsGroup statsName:(NSString *)statsName;

+ (void)pingStats:(NSString*)statsGroup statsNames:(NSArray *)statsNames;

@end
