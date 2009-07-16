//
//  GravatarImageView.m
//  WordPress
//
//  Created by Josh Bassett on 16/07/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//

#import "GravatarImageView.h"
#import <CommonCrypto/CommonDigest.h>

#define GRAVATAR_URL @"http://www.gravatar.com/avatar/%@s=80"


@interface GravatarImageView (Private)

- (NSURL *)gravatarURLForEmail:(NSString *)emailString;
NSString *md5(NSString *str);

@end


@implementation GravatarImageView

@synthesize email;

- (void)dealloc {
    if (email) {
        [email release];
    }

    [super dealloc];
}

- (void)setEmail:(NSString *)value {
    email = [NSString stringWithString:value];
    NSURL *url = [self gravatarURLForEmail:email];
    [self loadImageFromURL:url];
}

#pragma mark Private Methods

- (NSURL *)gravatarURLForEmail:(NSString *)emailString {
    NSString *emailHash = [md5(emailString) lowercaseString];
    NSString *url = [NSString stringWithFormat:GRAVATAR_URL, emailHash];
    return [NSURL URLWithString:url];
}

NSString *md5(NSString *str) {
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cStr, strlen(cStr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}

@end
