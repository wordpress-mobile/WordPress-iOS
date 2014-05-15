#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class ReaderTopic;

@interface ReaderTopicService : NSObject <LocalCoreDataService>

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

@end
