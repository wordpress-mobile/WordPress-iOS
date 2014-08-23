#import <Foundation/Foundation.h>



@interface XMLParserCollecter : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableString *result;
@end
