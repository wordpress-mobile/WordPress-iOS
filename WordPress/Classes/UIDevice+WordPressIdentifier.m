//
//  UIDevice+WordPressIdentifier.m
//  WordPress
//
//  Created by Jorge Bernal on 10/17/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIDevice+WordPressIdentifier.h"

@implementation UIDevice (WordPressIdentifier)

- (NSString *)wordpressIdentifier {
    NSString *uuid;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        uuid = [[UIDevice currentDevice] uniqueIdentifier];
#pragma clang diagnostic pop
    }
    return uuid;
}

@end
