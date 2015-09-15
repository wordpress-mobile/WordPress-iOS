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

@end
