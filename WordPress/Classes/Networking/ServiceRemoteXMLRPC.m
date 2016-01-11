#import "ServiceRemoteXMLRPC.h"
#import "WPXMLRPCClient.h"

@interface ServiceRemoteXMLRPC()

@property (nonatomic, strong, readwrite) WPXMLRPCClient *api;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@end

@implementation ServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api username:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (self) {
        _api = api;
        _username = username;
        _password = password;
    }    
    return self;
}

- (NSArray *)defaultXMLRPCArguments {
    return @[@0, self.username, self.password];
}

- (NSArray *)XMLRPCArgumentsWithExtra:(id)extra {
    NSMutableArray *result = [[self defaultXMLRPCArguments] mutableCopy];
    if ([extra isKindOfClass:[NSArray class]]) {
        [result addObjectsFromArray:extra];
    } else if (extra != nil) {
        [result addObject:extra];
    }
    
    return [NSArray arrayWithArray:result];
}

@end
