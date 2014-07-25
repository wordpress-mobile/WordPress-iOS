#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

extern NSString * const ReaderTopicDidChangeViaUserInteractionNotification;
extern NSString * const ReaderTopicDidChangeNotification;
extern NSString * const ReaderTopicServiceErrorDomain;

typedef enum : NSUInteger {
    ReaderTopicServiceErrorNoAccount
} ReaderTopicServiceError;

@class ReaderTopic;

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

@end
