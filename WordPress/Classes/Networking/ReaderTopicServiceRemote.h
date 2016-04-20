#import <Foundation/Foundation.h>
#import "ServiceRemoteREST.h"

extern NSString * const WordPressComReaderEndpointURL;

@class WordPressComApi;
@class RemoteReaderSiteInfo;
@class RemoteReaderTopic;

@interface ReaderTopicServiceRemote : ServiceRemoteREST

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

/**
 Follows the topic with the specified slug.

 @param slug The slug of the topic to follow.
 @param success block called on a successful fetch. An `NSArray` of `NSDictionary`
 objects describing topics is passed as an argument.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)followTopicWithSlug:(NSString *)slug
                withSuccess:(void (^)(NSNumber *topicID))success
                    failure:(void (^)(NSError *error))failure;

/**
 Fetches public information about the tag with the specified slug.

 @param slug The slug of the topic.
 @param success block called on a successful fetch. An instance of RemoteReaderTopic
 is passed to the callback block.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchTagInfoForTagWithSlug:(NSString *)slug
                           success:(void (^)(RemoteReaderTopic *remoteTopic))success
                           failure:(void (^)(NSError *error))failure;

/**
 Fetches public information about the site with the specified ID. 
 
 @param siteID The ID of the site.
 @param isFeed If the site is a feed.
 @param success block called on a successful fetch. An instance of RemoteReaderSiteInfo
 is passed to the callback block.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchSiteInfoForSiteWithID:(NSNumber *)siteID
                            isFeed:(BOOL)isFeed
                           success:(void (^)(RemoteReaderSiteInfo *siteInfo))success
                           failure:(void (^)(NSError *error))failure;

/**
 Takes a topic name and santitizes it, returning what *should* be its slug.
 
 @param topicName The natural language name of a topic. 
 
 @return The sanitized name, as a topic slug.
 */
- (NSString *)slugForTopicName:(NSString *)topicName;

@end
