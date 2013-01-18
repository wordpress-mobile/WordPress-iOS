//
//  NSString+Util.m
//  WordPress
//
//  Created by Joshua Bassett on 18/06/09.
//

#import "NSString+Util.h"


@implementation NSString (Util)

- (bool)isEmpty {
    return self.length == 0;
}

- (NSString *)trim {
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    return [self stringByTrimmingCharactersInSet:set];
}

- (NSNumber *)numericValue {
    return [NSNumber numberWithUnsignedLongLong:[self longLongValue]];
}

@end

@implementation NSObject (NumericValueHack)
- (NSNumber *)numericValue {
    if ([self isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)self;
    }
	return nil;
}
@end