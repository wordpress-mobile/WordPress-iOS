#import "SiteServiceRemoteWordPressComREST.h"

@interface SiteServiceRemoteWordPressComREST ()
@property (nonatomic, strong) NSNumber *siteID;
@end

@implementation SiteServiceRemoteWordPressComREST

- (instancetype)initWithWordPressComRestApi:(id<WordPressComRESTAPIInterfacing>)api siteID:(NSNumber *)siteID {
    self = [super initWithWordPressComRestApi:api];
    if (self) {
        _siteID = siteID;
    }
    return self;
}

@end
