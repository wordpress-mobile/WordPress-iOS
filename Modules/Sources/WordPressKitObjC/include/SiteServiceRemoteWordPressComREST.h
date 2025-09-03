#import <Foundation/Foundation.h>
#import "ServiceRemoteWordPressComREST.h"

NS_ASSUME_NONNULL_BEGIN

@interface SiteServiceRemoteWordPressComREST : ServiceRemoteWordPressComREST

@property (nonatomic, readonly) NSNumber *siteID;

- (instancetype)initWithWordPressComRestApi:(id<WordPressComRESTAPIInterfacing>)api __unavailable;
- (instancetype)initWithWordPressComRestApi:(id<WordPressComRESTAPIInterfacing>)api siteID:(NSNumber *)siteID;

@end

NS_ASSUME_NONNULL_END
