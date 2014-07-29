#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

typedef enum : NSUInteger {
    ReaderSiteServiceNotLoggedInError
} ReaderSiteServiceError;

extern NSString * const ReaderSiteServiceErrorDomain;

@interface ReaderSiteService : NSObject<LocalCoreDataService>

/**
 Get a list of the sites the user follows.
 
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchFollowedSitesWithSuccess:(void(^)(NSArray *sites))success
                              failure:(void(^)(NSError *error))failure;

/**
 Follow a site by its URL.
 Attempts to determine if the site is self-hosted or a WordPress.com site, then
 calls the appropriate follow method.

 @param siteURL The URL of the site.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followSiteByURL:(NSURL *)siteURL
                success:(void (^)())success
                failure:(void(^)(NSError *error))failure;

/**
 Follow a wpcom site by ID.

 @param siteID The ID of the site.
 @param success block called on a successful follow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followSiteWithID:(NSUInteger)siteID
                 success:(void(^)())success
                 failure:(void(^)(NSError *error))failure;

/**
 Unfollow a wpcom site by ID

 @param siteID The ID of the site.
 @param success block called on a successful unfollow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowSiteWithID:(NSUInteger)siteID
                   success:(void(^)())success
                   failure:(void(^)(NSError *error))failure;

/**
 Follow a wpcom or wporg site by URL.

 @param siteURL The URL of the site as a string.
 @param success block called on a successful follow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followSiteAtURL:(NSString *)siteURL
                success:(void(^)())success
                failure:(void(^)(NSError *error))failure;

/**
 Unfollow a wpcom or wporg site by URL.

 @param siteURL The URL of the site as a string.
 @param success block called on a successful unfollow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowSiteAtURL:(NSString *)siteURL
                  success:(void(^)())success
                  failure:(void(^)(NSError *error))failure;

@end
