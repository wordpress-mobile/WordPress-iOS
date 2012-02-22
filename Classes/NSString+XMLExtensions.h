//
//  NSString+XMLExtensions.h
//  WordPress
//
//  Created by Janakiram on 26/08/08.
//

#import <UIKit/UIKit.h>

@interface NSString (XMLExtensions)

+ (NSString *)encodeXMLCharactersIn : (NSString *)source;
+ (NSString *)decodeXMLCharactersIn : (NSString *)source;
- (NSString *)stringByDecodingXMLCharacters;
- (NSString *)stringByEncodingXMLCharacters;

@end
