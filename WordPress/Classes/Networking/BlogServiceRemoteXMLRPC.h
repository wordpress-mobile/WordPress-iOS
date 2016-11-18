#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"
#import "ServiceRemoteWordPressXMLRPC.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlogServiceRemoteXMLRPC : ServiceRemoteWordPressXMLRPC<BlogServiceRemote>

- (RemotePostType *)remotePostTypeFromXMLRPCDictionary:(NSDictionary *)json;
- (RemoteBlogSettings *)remoteBlogSettingFromXMLRPCDictionary:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
