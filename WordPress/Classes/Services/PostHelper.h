#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PostService.h"

@class AbstractPost, RemotePost;

NS_ASSUME_NONNULL_BEGIN

@interface PostPublicizeInfo: NSObject
@property (nonatomic, nullable) NSString *publicID;
@property (nonatomic, nullable) NSString *publicizeMessage;
@property (nonatomic, nullable) NSString *publicizeMessageID;
@property (nonatomic, nullable) NSDictionary<NSNumber *, NSDictionary<NSString *, NSString *> *> *disabledPublicizeConnections;
@end

@interface PostHelper: NSObject

/**
 Creates a RemotePost from an AbstractPost to be used for API calls.

 @param post The AbstractPost used to create the RemotePost
 */
+ (RemotePost *)remotePostWithPost:(AbstractPost *)post;

+ (NSArray *)mergePosts:(NSArray <RemotePost *> *)remotePosts
                 ofType:(NSString *)syncPostType
           withStatuses:(nullable NSArray *)statuses
               byAuthor:(nullable NSNumber *)authorID
                forBlog:(Blog *)blog
          purgeExisting:(BOOL)purge
              inContext:(NSManagedObjectContext *)context;

// For internal use (needs rewrite to Swift)
+ (void)updateCommentsForPost:(AbstractPost *)post;
+ (void)updatePost:(Post *)post withRemoteCategories:(NSArray *)remoteCategories inContext:(NSManagedObjectContext *)managedObjectContext;
+ (PostPublicizeInfo *)makePublicizeInfoWithPost:(AbstractPost *)post remotePost:(RemotePost *)remotePost;

@end



NS_ASSUME_NONNULL_END
