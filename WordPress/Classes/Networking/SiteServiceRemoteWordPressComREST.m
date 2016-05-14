#import "SiteServiceRemoteWordPressComREST.h"
#import "WordPress-Swift.h"

@interface SiteServiceRemoteWordPressComREST ()
@property (nonatomic, strong) NSNumber *siteID;
@end

@implementation SiteServiceRemoteWordPressComREST

- (instancetype)initWithWordPressComRestApi:(WordPressComRestApi *)api siteID:(NSNumber *)siteID {
    self = [super initWithWordPressComRestApi:api];
    if (self) {
        _siteID = siteID;
    }
    return self;
}

@end
