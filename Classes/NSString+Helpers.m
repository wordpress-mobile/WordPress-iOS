//
//  NSString+Helpers.m
//  WordPress
//
//  Created by John Bickerstaff on 9/9/09.
//  
//

#import "NSString+Helpers.h"
#import "NSData+Base64.h"

@implementation NSString (Helpers)

#pragma mark Helpers
- (NSString *) stringByUrlEncoding
{
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,  (CFStringRef)self,  NULL,  (CFStringRef)@"!*'();:@&=+$,/?%#[]",  kCFStringEncodingUTF8);
}

- (NSString *)base64Encoding
{
	NSData *stringData = [self dataUsingEncoding:NSUTF8StringEncoding];
	NSString *encodedString = [stringData base64EncodedString];

	return encodedString;
}

@end