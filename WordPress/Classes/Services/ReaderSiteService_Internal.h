#import "ReaderSiteService.h"

@interface ReaderSiteService ()

- (nonnull NSError *)errorForNotLoggedIn;
- (void)flagPostsFromSite:(NSNumber * _Nonnull)siteID asBlocked:(BOOL)blocked;

@end
