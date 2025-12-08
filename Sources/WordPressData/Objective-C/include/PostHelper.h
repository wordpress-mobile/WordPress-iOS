#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AbstractPost, RemotePost, Post, Blog;

typedef NSString * PostServiceType NS_TYPED_ENUM;
extern PostServiceType const PostServiceTypePost;
extern PostServiceType const PostServiceTypePage;
extern PostServiceType const PostServiceTypeAny;

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
