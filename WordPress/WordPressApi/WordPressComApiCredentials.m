//
//  WordPressComApiCredentials.m
//  WordPress
//
//  Created by Jorge Bernal on 1/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WordPressComApiCredentials.h"

#define WPCOM_API_CLIENT_ID @""
#define WPCOM_API_CLIENT_SECRET @""

@implementation WordPressComApiCredentials
+ (NSString *)client {
    return WPCOM_API_CLIENT_ID;
}

+ (NSString *)secret {
    return WPCOM_API_CLIENT_SECRET;
}

+ (NSString *)pocketConsumerKey {
    return @"";
}
@end
