#import "LSStubRequestDSL.h"
#import "LSStubResponseDSL.h"
#import "LSStubRequest.h"
#import "LSNocilla.h"

@interface LSStubRequestDSL ()
@property (nonatomic, strong) LSStubRequest *request;
@end

@implementation LSStubRequestDSL

- (id)initWithRequest:(LSStubRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}
- (WithHeadersMethod)withHeaders {
    return ^(NSDictionary *headers) {
        for (NSString *header in headers) {
            NSString *value = [headers objectForKey:header];
            [self.request setHeader:header value:value];
        }
        return self;
    };
}

- (WithHeaderMethod)withHeader {
    return ^(NSString * header, NSString * value) {
        [self.request setHeader:header value:value];
        return self;
    };
}

- (AndBodyMethod)withBody {
    return ^(NSString *body) {
        self.request.body = [body dataUsingEncoding:NSUTF8StringEncoding];
        return self;
    };
}

- (AndReturnMethod)andReturn {
    return ^(NSInteger statusCode) {
        self.request.response = [[LSStubResponse alloc] initWithStatusCode:statusCode];
        LSStubResponseDSL *responseDSL = [[LSStubResponseDSL alloc] initWithResponse:self.request.response];
        return responseDSL;
    };
}

- (AndReturnRawResponseMethod)andReturnRawResponse {
    return ^(NSData *rawResponseData) {
        self.request.response = [[LSStubResponse alloc] initWithRawResponse:rawResponseData];
        LSStubResponseDSL *responseDSL = [[LSStubResponseDSL alloc] initWithResponse:self.request.response];
        return responseDSL;
    };
}
@end

LSStubRequestDSL * stubRequest(NSString *method, NSString *url) {
    LSStubRequest *request = [[LSStubRequest alloc] initWithMethod:method url:url];
    LSStubRequestDSL *dsl = [[LSStubRequestDSL alloc] initWithRequest:request];
    [[LSNocilla sharedInstance] addStubbedRequest:request];
    return dsl;
}
