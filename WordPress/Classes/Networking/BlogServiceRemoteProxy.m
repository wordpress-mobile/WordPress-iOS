#import "BlogServiceRemoteProxy.h"
#import "BlogServiceRemoteREST.h"
#import "BlogServiceRemoteXMLRPC.h"

@implementation BlogServiceRemoteProxy

- (id)initWithXMLRPCRemote:(BlogServiceRemoteXMLRPC *)xmlrpcRemote RESTRemote:(BlogServiceRemoteREST *)restRemote {
    NSParameterAssert(xmlrpcRemote != nil);
    self = [super init];
    if (self) {
        _xmlrpcRemote = xmlrpcRemote;
        _restRemote = restRemote;
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    if (self.restRemote && [self.restRemote respondsToSelector:selector]) {
        [anInvocation invokeWithTarget:self.restRemote];
    } else {
        [anInvocation invokeWithTarget:self.xmlrpcRemote];
    }
}

@end
