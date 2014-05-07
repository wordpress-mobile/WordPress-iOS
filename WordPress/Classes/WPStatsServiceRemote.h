#import <Foundation/Foundation.h>
#import "WordPressComApi.h"
#import "WPStatsService.h"

@interface WPStatsServiceRemote : NSObject

- (instancetype)initWithRemoteApi:(WordPressComApi *)api andSiteId:(NSNumber *)siteId;

- (void)fetchStatsForSiteId:(NSNumber *)siteId withCompletionHandler:(StatsCompletion)completionHandler failureHandler:(void (^)(NSError *error))failureHandler;

@end