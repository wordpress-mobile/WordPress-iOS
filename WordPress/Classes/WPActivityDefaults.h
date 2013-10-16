//
//  WPActivityDefaults.h
//  WordPress
//
//  Created by Jorge Bernal on 7/26/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPActivityDefaults : NSObject
+ (NSArray *)defaultActivities;
+ (void)trackActivityType:(NSString *)activityType withPrefix:(NSString *)prefix;
@end
