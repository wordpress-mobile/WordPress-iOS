#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

extern NSString * const ReaderTopicDidChangeViaUserInteractionNotification;
extern NSString * const ReaderTopicDidChangeNotification;
extern NSString * const ReaderTopicFreshlyPressedPathCommponent;

@class ReaderTopic;
@class ReaderSite;
@class ReaderPost;

@interface ReaderTopicService : NSObject <LocalCoreDataService>

/**
 Sets the currentTopic and dispatches the `ReaderTopicDidChangeNotification` notification.
 Passing `nil` for the topic will not dispatch the notification.
 */
@property (nonatomic) ReaderTopic *currentTopic;

/**
 Fetches the topics for the reader's menu.
 
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchReaderMenuWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Counts the number of ReaderTopics of type `ReaderTopicTypeTag` the user has subscribed to.
 
 @return The number of ReaderTopics whose `isSubscribed` property is set to `YES`
 */
- (NSUInteger)numberOfSubscribedTopics;

/**
 Deletes all topics from core data and saves the context. Call when switching accounts.
 */
- (void)deleteAllTopics;

/**
 Deletes a specific topic from core data and saves the context. Use to clean up previewed topics.
 */
- (void)deleteTopic:(ReaderTopic *)topic;

/**
 Marks the specified topic as being subscribed, and marks it current.
 
 @param topic The ReaderTopic to follow and make current.
 */
- (void)subscribeToAndMakeTopicCurrent:(ReaderTopic *)topic;

/**
 Unfollows the specified topic

 @param topic The ReaderTopic to unfollow.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowTopic:(ReaderTopic *)topic withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Follow the topic with the specified name
 
 @param topicName The name of a tag to follow.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followTopicNamed:(NSString *)topicName withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

/**

 Fetch the topic for 'sites I follow' if it exists.

 @return A `ReaderTopic` instance or nil.
 */
- (ReaderTopic *)topicForFollowedSites;

/**
 Compose the topic for a single followed site.

 @param site The ReaderSite of the topic to return.
 @return A `ReaderTopic` instance.
 */
- (ReaderTopic *)siteTopicForSite:(ReaderSite *)site;

/**
 Compose the topic for a posts site.

 @param post The ReaderPost whose site we want to compose into a topic
 @return A `ReaderTopic` instance.
 */
- (ReaderTopic *)siteTopicForPost:(ReaderPost *)post;

@end
