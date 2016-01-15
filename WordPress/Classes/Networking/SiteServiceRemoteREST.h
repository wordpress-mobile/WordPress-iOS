#import "ServiceRemoteREST.h"

NS_ASSUME_NONNULL_BEGIN

@interface SiteServiceRemoteREST : ServiceRemoteREST
@property (nonatomic, readonly) NSNumber *siteID;
- (instancetype)initWithApi:(WordPressComApi *)api __unavailable;
- (instancetype)initWithApi:(WordPressComApi *)api siteID:(NSNumber *)siteID;
@end

NS_ASSUME_NONNULL_END
