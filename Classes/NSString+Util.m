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

@end
