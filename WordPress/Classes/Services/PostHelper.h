#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PostService.h"

@class AbstractPost, RemotePost;

NS_ASSUME_NONNULL_BEGIN

@interface PostHelper: NSObject

+ (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost inContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost inContext:(NSManagedObjectContext *)managedObjectContext overwrite:(BOOL)overwrite;

+ (NSArray *)remoteMetadataForPost:(Post *)post;

+ (NSArray *)mergePosts:(NSArray <RemotePost *> *)remotePosts
                 ofType:(NSString *)syncPostType
           withStatuses:(nullable NSArray *)statuses
               byAuthor:(nullable NSNumber *)authorID
                forBlog:(Blog *)blog
          purgeExisting:(BOOL)purge
              inContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
