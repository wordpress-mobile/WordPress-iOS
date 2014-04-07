#import <UIKit/UIKit.h>

@interface NSString (XMLExtensions)

+ (NSString *)encodeXMLCharactersIn : (NSString *)source;
+ (NSString *)decodeXMLCharactersIn : (NSString *)source;
- (NSString *)stringByDecodingXMLCharacters;
- (NSString *)stringByEncodingXMLCharacters;

@end
