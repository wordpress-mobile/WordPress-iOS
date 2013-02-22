#import <Foundation/Foundation.h>
#import "LSHTTPResponse.h"

@interface LSStubResponse : NSObject<LSHTTPResponse>

@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, strong) NSData *body;
@property (nonatomic, strong, readonly) NSDictionary *headers;

- (id)initWithStatusCode:(NSInteger)statusCode;
- (id)initWithRawResponse:(NSData *)rawResponseData;
- (id)initDefaultResponse;
- (void)setHeader:(NSString *)header value:(NSString *)value;
@end
