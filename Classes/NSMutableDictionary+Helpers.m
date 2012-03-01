//
//  NSMutableDictionary+Helpers.m
//  WordPress
//
//  Created by Jorge Bernal on 2/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NSMutableDictionary+Helpers.h"

@implementation NSMutableDictionary (Helpers)
- (void)setValueIfNotNil:(id)value forKey:(NSString *)key {
    if (value != nil) {
        [self setValue:value forKey:key];
    }
}
@end
