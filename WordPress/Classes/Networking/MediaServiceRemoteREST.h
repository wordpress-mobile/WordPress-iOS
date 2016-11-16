#import <Foundation/Foundation.h>
#import "MediaServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"

NS_ASSUME_NONNULL_BEGIN

@interface MediaServiceRemoteREST : SiteServiceRemoteWordPressComREST <MediaServiceRemote>

- (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia;

@end

NS_ASSUME_NONNULL_END
