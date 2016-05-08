#import <Foundation/Foundation.h>

@class WPXMLRPCClient;

@interface ServiceRemoteXMLRPC : NSObject

- (id)initWithApi:(WPXMLRPCClient *)api username:(NSString *)username password:(NSString *)password;

@property (nonatomic, readonly) WPXMLRPCClient *api;

- (NSArray *)defaultXMLRPCArguments;
- (NSArray *)XMLRPCArgumentsWithExtra:(id)extra;

@end
