#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

typedef NS_ENUM(NSUInteger, ReaderSiteServiceError) {
    ReaderSiteServiceErrorNotLoggedIn,
    ReaderSiteServiceErrorAlreadyFollowingSite
};

extern NSString * const ReaderSiteServiceErrorDomain;

@class ReaderSite;

@interface ReaderSiteService : NSObject<LocalCoreDataService>

/**
 Get a list of the sites the user follows.
 
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchFollowedSitesWithSuccess:(void(^)())success
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

/**
 Unfollows the specified `ReaderSite`.

 @param site The `ReaderSite` to unfollow.
 @param success block called on a successful unfollow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowSite:(ReaderSite *)site
             success:(void(^)())success
             failure:(void(^)(NSError *error))failure;

/**
 Sync posts for the 'sites I follow endpoint if it exists. Maybe called whenever
 a site/feed is followed or unfollowed.
 */
- (void)syncPostsForFollowedSites;

/**
 Block/unblock the specified site from appearing in the user's reader
 
 @param siteID The ID of the site.
 @param blocked Boolean value. YES to block a site. NO to unblock a site.
 @param success block called on a successful block.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)flagSiteWithID:(NSNumber *)siteID
             asBlocked:(BOOL)blocked
               success:(void(^)())success
               failure:(void(^)(NSError *error))failure;

@end
