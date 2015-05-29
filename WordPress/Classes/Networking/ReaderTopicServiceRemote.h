#import <Foundation/Foundation.h>

@class WordPressComApi;

@interface ReaderTopicServiceRemote : NSObject

- (id)initWithRemoteApi:(WordPressComApi *)api;

/**
 Fetches the topics for the reader's menu from the remote service.
 
 @param success block called on a successful fetch. An `NSArray` of `NSDictionary` 
 objects describing topics is passed as an argument.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchReaderMenuWithSuccess:(void (^)(NSArray *topics))success
                         failure:(void (^)(NSError *error))failure;

/**
 Unfollows the topic with the specified slug.

 @param slug The slug of the topic to unfollow.
 @param success block called on a successful fetch. An `NSArray` of `NSDictionary`
 objects describing topics is passed as an argument.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unfollowTopicWithSlug:(NSString *)slug
                  withSuccess:(void (^)(NSNumber *topicID))success
                      failure:(void (^)(NSError *error))failure;

/**
 Follows the topic with the specified name.

 @param topicName The name of the topic to follow.
 @param success block called on a successful fetch. An `NSArray` of `NSDictionary`
 objects describing topics is passed as an argument.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followTopicNamed:(NSString *)topicName
             withSuccess:(void (^)(NSNumber *topicID))success
                 failure:(void (^)(NSError *error))failure;

@end
