#import "SiteServiceRemoteREST.h"

@interface SiteServiceRemoteREST ()
@property (nonatomic, strong) NSNumber *siteID;
@end

@implementation SiteServiceRemoteREST

- (instancetype)initWithApi:(WordPressComApi *)api siteID:(NSNumber *)siteID {
    self = [super initWithApi:api];
    if (self) {
        _siteID = siteID;
    }
    return self;
}

@end
