#import <Foundation/Foundation.h>

@interface WPRSDParser : NSObject<NSXMLParserDelegate>
- (id)initWithXmlString:(NSString *)string;
- (NSString *)parsedEndpointWithError:(NSError **)error;
@end
