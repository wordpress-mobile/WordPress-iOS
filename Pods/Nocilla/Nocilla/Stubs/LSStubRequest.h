#import <Foundation/Foundation.h>
#import "LSStubResponse.h"
#import "LSHTTPRequest.h"

@class LSStubRequest;
@class LSStubResponse;

@interface LSStubRequest : NSObject<LSHTTPRequest>
@property (nonatomic, assign, readonly) NSString *method;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) NSDictionary *headers;
@property (nonatomic, strong, readwrite) NSData *body;

@property (nonatomic, strong) LSStubResponse *response;

- (id)initWithMethod:(NSString *)method url:(NSString *)url;
- (void)setHeader:(NSString *)header value:(NSString *)value;

- (BOOL)matchesRequest:(id<LSHTTPRequest>)request;
@end
