#import <Foundation/Foundation.h>

@class WPXMLRPCClient;

NS_ASSUME_NONNULL_BEGIN

@interface ServiceRemoteXMLRPC : NSObject

- (id)initWithApi:(WPXMLRPCClient *)api username:(NSString *)username password:(NSString *)password;

@property (nonatomic, readonly) WPXMLRPCClient *api;

- (NSArray *)defaultXMLRPCArguments;
- (NSArray *)XMLRPCArgumentsWithExtra:(_Nullable id)extra;

@end

NS_ASSUME_NONNULL_END
