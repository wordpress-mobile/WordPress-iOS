#import <Foundation/Foundation.h>

@class WPXMLRPCClient;

@interface ServiceRemoteXMLRPC : NSObject

- (id)initWithApi:(WPXMLRPCClient *)api username:(NSString *)username password:(NSString *)password;

@property (nonatomic, readonly) WPXMLRPCClient *api;

- (NSArray *)getXMLRPCArgsForBlogWithID:(NSNumber *)blogID extra:(id)extra;

@end
