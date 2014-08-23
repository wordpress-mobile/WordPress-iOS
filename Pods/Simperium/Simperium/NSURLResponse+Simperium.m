//
//  NSURLResponse+Simperium.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/21/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "NSURLResponse+Simperium.h"

@implementation NSURLResponse (Simperium)

- (NSStringEncoding)encoding {
	NSStringEncoding encoding = NSUTF8StringEncoding;
	
	if (self.textEncodingName) {
		CFStringEncoding cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)self.textEncodingName);
		if (cfStringEncoding != kCFStringEncodingInvalidId) {
			encoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding);
		}
	}
	
	return encoding;
}

@end
