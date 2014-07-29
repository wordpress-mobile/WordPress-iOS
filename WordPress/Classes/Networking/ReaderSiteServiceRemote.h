#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    ReaderSiteServiceRemoteInvalidHost
} ReaderSiteServiceRemoteError;

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

@end
