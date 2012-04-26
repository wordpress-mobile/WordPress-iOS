#import <Foundation/Foundation.h>

@interface NSString (NSStringAdditions)

+ (NSString *)stringByGeneratingUUID;

+ (NSString *)base64StringFromData: (NSData *)data length: (int)length;

#pragma mark -

- (NSString *)unescapedString;

- (NSString *)escapedString;

@end
