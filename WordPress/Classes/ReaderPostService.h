#import <Foundation/Foundation.h>
#import "LocalService.h"

@class ReaderTopic;

@interface ReaderPostService : NSObject<LocalService>

/**
 Fetches the posts for the specified topic

 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderTopic *)topic success:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Fetches the posts for the specified topic

 @param date The date to get posts earlier than.
 @param keepExisting YES if existing posts should kept, otherwise they are deleted in favor of the newest content.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderTopic *)topic earlierThan:(NSDate *)date keepExisting:(BOOL)keepExisting success:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
