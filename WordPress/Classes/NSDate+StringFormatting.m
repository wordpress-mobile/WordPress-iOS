//
//  NSDate+StringFormatting.m
//  WordPress
//
//  Created by Michael Johnston on 11/17/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NSDate+StringFormatting.h"

@implementation NSDate (StringFormatting)

- (NSString *)shortString {
    NSString *shortString;
	NSTimeInterval diff = [[NSDate date] timeIntervalSince1970] - [self timeIntervalSince1970];
    
	if(diff < 60) {
		shortString = [NSString stringWithFormat:@"%is", (int)diff];
	} else if(diff < 3600) {
		shortString = [NSString stringWithFormat:@"%im", (int)floor(diff / 60)];
	} else if (diff < 86400) {
		shortString = [NSString stringWithFormat:@"%ih", (int)floor(diff / 3600)];
	} else {
		shortString = [NSString stringWithFormat:@"%id", (int)floor(diff / 86400)];
	}
    
	return shortString;
}

@end
