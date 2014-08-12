#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ReaderSiteServiceRemoteError) {
    ReaderSiteServiceRemoteInvalidHost,
    ReaderSiteServiceRemoteUnsuccessfulFollowSite,
    ReaderSiteServiceRemoteUnsuccessfulUnfollowSite,
    ReaderSiteSErviceRemoteUnsuccessfulBlockSite
};

extern NSString * const ReaderSiteServiceRemoteErrorDomain;

@class WordPressComApi;

@interface ReaderSiteServiceRemote : NSObject

- (id)initWithRemoteApi:(WordPressComApi *)api;

/**
 Get a list of the sites the user follows.

 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchFollowedSitesWithSuccess:(void(^)(NSArray *sites))success
                              failure:(void(^)(NSError *error))failure;


/**
 Follow a wpcom site.

 @param siteID The ID of the site.
 @param success block called on a successful follow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followSiteWithID:(NSUInteger)siteID
                 success:(void(^)())success
                 failure:(void(^)(NSError *error))failure;

/**
 Unfollow a wpcom site

 @param siteID The ID of the site.
 @param success block called on a successful unfollow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowSiteWithID:(NSUInteger)siteID
                   success:(void(^)())success
                   failure:(void(^)(NSError *error))failure;

/**
 Follow a wporg site.

 @param siteURL The URL of the site as a string.
 @param success block called on a successful follow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followSiteAtURL:(NSString *)siteURL
                success:(void(^)())success
                failure:(void(^)(NSError *error))failure;

/**
 Unfollow a wporg site

 @param siteURL The URL of the site as a string.
 @param success block called on a successful unfollow.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowSiteAtURL:(NSString *)siteURL
                  success:(void(^)())success
                  failure:(void(^)(NSError *error))failure;

/**
 Find the WordPress.com site ID for the site at the specified URL.
 
 @param siteURL the URL of the site.
 @param success block called on a successful fetch. The found siteID is passed to the success block.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)findSiteIDForURL:(NSURL *)siteURL
                 success:(void(^)(NSUInteger siteID))success
                 failure:(void(^)(NSError *error))failure;

/**
 Test a URL to see if a site exists.
 
 @param siteURL the URL of the site.
 @param success block called on a successful request.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)checkSiteExistsAtURL:(NSURL *)siteURL
                     success:(void (^)())success
                     failure:(void(^)(NSError *error))failure;

/**
 Check whether a site is already subscribed

 @param siteID The ID of the site.
 @param success block called on a successful check. A boolean is returned indicating if the site is followed or not.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)checkSubscribedToSiteByID:(NSUInteger)siteID
                          success:(void (^)(BOOL follows))success
                          failure:(void(^)(NSError *error))failure;

/**
 Check whether a feed is already subscribed

 @param siteURL the URL of the site.
 @param success block called on a successful check. A boolean is returned indicating if the feed is followed or not.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)checkSubscribedToFeedByURL:(NSURL *)siteURL
                           success:(void (^)(BOOL follows))success
                           failure:(void(^)(NSError *error))failure;

/**
 Block/unblock a site from showing its posts in the reader

 @param siteID The ID of the site (not feed).
 @param blocked Boolean value. Yes if the site should be blocked. NO if the site should be unblocked. 
 @param success block called on a successful check.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)flagSiteWithID:(NSUInteger)siteID
             asBlocked:(BOOL)blocked
               success:(void(^)())success
               failure:(void(^)(NSError *error))failure;

@end
