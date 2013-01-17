//
//  NSString+Helpers.h
//  WordPress
//
//  Created by John Bickerstaff on 9/9/09.
// //

#import <UIKit/UIKit.h>

@interface NSString (Helpers)

// helper functions
- (NSString *) stringByUrlEncoding;
- (NSString *) base64Encoding;
- (NSString *) md5;
- (NSMutableDictionary *)dictionaryFromQueryString;
- (NSString *)stringByStrippingHTML;
@end
