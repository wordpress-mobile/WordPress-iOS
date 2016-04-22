#import "WPXMLRPCRequest.h"

@implementation WPXMLRPCRequest

- (id)initWithMethod:(NSString *)method andParameters:(NSArray *)parameters {
    self = [super init];
    if (self) {
        _method = method;
        _parameters = parameters;
    }
    return self;
}

@end
