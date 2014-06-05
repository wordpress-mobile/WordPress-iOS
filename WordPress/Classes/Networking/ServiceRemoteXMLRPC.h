#import <Foundation/Foundation.h>

@class WPXMLRPCClient;

@protocol ServiceRemoteXMLRPC <NSObject>
- (id)initWithApi:(WPXMLRPCClient *)api;
@end
