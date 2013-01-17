//
//  WordPressComApiCredentials.h
//  WordPress
//
//  Created by Jorge Bernal on 1/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WordPressComApiCredentials : NSObject
+ (NSString *)client;
+ (NSString *)secret;
@end
