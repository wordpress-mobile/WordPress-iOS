#import <Foundation/Foundation.h>
#import "BaseLocalService.h"

@interface ReaderTopicService : NSObject <BaseLocalService>

/**
 Fetches the topics for the reader's menu.
 
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchReaderMenuWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
