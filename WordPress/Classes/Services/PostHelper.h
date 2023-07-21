#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AbstractPost, RemotePost;

NS_ASSUME_NONNULL_BEGIN

@interface PostHelper : NSObject

+ (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost inContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
