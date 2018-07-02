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
 Counts the number of `ReaderTagTopics` the user has subscribed to.
 
 @return The number of ReaderTagTopics whose `followed` property is set to `YES`
 */
- (NSUInteger)numberOfSubscribedTopics;

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
 Marks the specified topic as being subscribed, and marks it current.
 
 @param topic The ReaderAbstractTopic to follow and make current.
 */
- (void)subscribeToAndMakeTopicCurrent:(ReaderAbstractTopic *)topic;

/**
 Creates a ReaderSearchTopic from the specified search phrase.
 
 @param phrase: The search phrase.
 
 @return A ReaderSearchTopic instance.
 */
- (ReaderSearchTopic *)searchTopicForSearchPhrase:(NSString *)phrase;


/**
 Unfollows the specified topic. If the specified topic was the current topic the 
 current topic is updated to a default.

 @param topic The ReaderAbstractTopic to unfollow.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */

- (void)unfollowAndRefreshCurrentTopicForTag:(ReaderTagTopic *)topic withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;

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
- (void)followTagNamed:(NSString *)tagName withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;

/**
 Follow the tag with the specified slug

 @param tagName The name of a tag to follow.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followTagWithSlug:(NSString *)slug withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;

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
- (void)toggleFollowingForSite:(ReaderSiteTopic *)topic success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

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
 Fetch the topic for 'Discover' if it exists.

 @return A `ReaderAbstractTopic` instance or nil.
 */
- (ReaderAbstractTopic *)topicForDiscover;

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


/**
 Fetch all saved Site topics

 @return A list of site topic
 */
- (NSArray <ReaderSiteTopic *>*)allSiteTopics;

/**
 Find a topic by its path.
 
 @param path The path of the topic
 
 @returns A matching abstract topic or nil.
 */
- (ReaderAbstractTopic *)findWithPath:(NSString *)path;

/**
 Find a site topic by its site id

 @param siteID The site id of the topic
 @return A matched site topic
 */
- (ReaderSiteTopic *)findSiteTopicWithSiteID:(NSNumber *)siteID;

/**
 Find a site topic by its feed id

 @param feedID The feed id of the topic
 @return A matched site topic
 */
- (ReaderSiteTopic *)findSiteTopicWithFeedID:(NSNumber *)feedID;

@end

@interface ReaderTopicService (Tests)
- (void)mergeMenuTopics:(NSArray *)topics withSuccess:(void (^)(void))success;
- (NSString *)formatTitle:(NSString *)str;
@end
