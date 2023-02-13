#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

extern NSString * const ReaderTopicDidChangeViaUserInteractionNotification;
extern NSString * const ReaderTopicDidChangeNotification;
extern NSString * const ReaderTopicFreshlyPressedPathCommponent;

@class ReaderAbstractTopic;
@class ReaderTagTopic;
@class ReaderSiteTopic;
@class ReaderSearchTopic;

@interface ReaderTopicService : LocalCoreDataService

/**
 Sets the currentTopic and dispatches the `ReaderTopicDidChangeNotification` notification.
 Passing `nil` for the topic will not dispatch the notification.
 */
@property (nonatomic) ReaderAbstractTopic *currentTopic;

/**
 Fetches the topics for the reader's menu.
 
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchReaderMenuWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;

/**
 Get a list of ReaderSiteTopics of the sites the user follows.

 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchFollowedSitesWithSuccess:(void(^)(void))success
                              failure:(void(^)(NSError *error))failure;

/**
 Deletes all search topics from core data and saves the context.
 Use to clean-up searches when they are finished.
 */
- (void)deleteAllSearchTopics;

/**
 Deletes all topics that do not appear in the menu from core data and saves the context.
 Use to clean-up previewed topics that are lingering in core data.
 */
- (void)deleteNonMenuTopics;

/**
 Globally sets the `inUse` flag to fall for all posts.
 */
- (void)clearInUseFlags;

/**
 Deletes all topics from core data and saves the context. Call when switching accounts.
 */
- (void)deleteAllTopics;

/**
 Deletes a specific topic from core data and saves the context. Use to clean up previewed topics.
 */
- (void)deleteTopic:(ReaderAbstractTopic *)topic;

/**
 Creates a ReaderSearchTopic from the specified search phrase.
 
 @param phrase: The search phrase.
 
 @return A ReaderSearchTopic instance.
 */
- (ReaderSearchTopic *)searchTopicForSearchPhrase:(NSString *)phrase;

/**
 Unfollows the specified topic

 @param topic The ReaderAbstractTopic to unfollow.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowTag:(ReaderTagTopic *)topic withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;

/**
 Follow the tag with the specified name
 
 @param tagName The name of a tag to follow.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followTagNamed:(NSString *)tagName
           withSuccess:(void (^)(void))success
               failure:(void (^)(NSError *error))failure
                source:(NSString *)source;

/**
 Toggle the following status of the tag for the specified tag topic

 @param topic The tag topic to toggle following status
 @param success block called on a successful change.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleFollowingForTag:(ReaderTagTopic *)topic success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

/**
 Toggle the following status of the site for the specified site topic

 @param topic The site topic to toggle following status
 @param success block called on a successful change.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleFollowingForSite:(ReaderSiteTopic *)topic
                       success:(void (^)(BOOL follow))success
                       failure:(void (^)(BOOL follow, NSError *error))failure;

/**
 Mark a site topic as unfollowed in core data only. Should be called after unfollowing
 a post to ensure that any existing site topics reflect the correct following status.

 @param feedURL The feedURL of the site topic.
 */
- (void)markUnfollowedSiteTopicWithFeedURL:(NSString *)feedURL;

/**
 Mark a site topic as unfollowed in core data only. Should be called after unfollowing
 a post to ensure that any existing site topics reflect the correct following status.

 @param siteID the siteID of the site topic.
 */
- (void)markUnfollowedSiteTopicWithSiteID:(NSNumber *)siteID;

/**
 Fetch the topic for 'sites I follow' if it exists.

 @return A `ReaderAbstractTopic` instance or nil.
 */
- (ReaderAbstractTopic *)topicForFollowedSites;

/**
 Fetch a tag topic for a tag with the specified slug.

 @param slug The slug for the tag.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)tagTopicForTagWithSlug:(NSString *)slug
                       success:(void(^)(NSManagedObjectID *objectID))success
                       failure:(void (^)(NSError *error))failure;

/**
 Fetch a site topic for a site with the specified ID.

 @param siteID The ID of the site .
 @param isFeed True if the site is a feed.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)siteTopicForSiteWithID:(NSNumber *)siteID
                        isFeed:(BOOL)isFeed
                       success:(void (^)(NSManagedObjectID *objectID, BOOL isFollowing))success
                       failure:(void (^)(NSError *error))failure;

@end

@interface ReaderTopicService (Tests)
- (void)mergeFollowedSites:(NSArray *)sites withSuccess:(void (^)(void))success;
- (void)mergeMenuTopics:(NSArray *)topics withSuccess:(void (^)(void))success;
- (void)mergeMenuTopics:(NSArray *)topics isLoggedIn:(BOOL)isLoggedIn withSuccess:(void (^)(void))success;
- (NSString *)formatTitle:(NSString *)str;
@end
