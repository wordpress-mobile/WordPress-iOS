#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AbstractPost, RemotePost, Post, Blog, ReaderPost, ReaderAbstractTopic, RemoteReaderPost;

NS_ASSUME_NONNULL_BEGIN

typedef NSString * PostServiceType NS_TYPED_ENUM;
extern PostServiceType const PostServiceTypePost;
extern PostServiceType const PostServiceTypePage;
extern PostServiceType const PostServiceTypeAny;

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

+ (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(nullable ReaderAbstractTopic *)topic context:(NSManagedObjectContext *) managedObjectContext;

/// Finds an existing `ReaderPost` matching the given `globalID` and `topic`, or creates a new one.
+ (ReaderPost *)findOrCreateReaderPostWithGlobalID:(NSString *)globalID forTopic:(nullable ReaderAbstractTopic *)topic existing:(BOOL *)existing inContext:(NSManagedObjectContext *)context;

/// Updates a `ReaderPost` with values from a `RemoteReaderPost`.
+ (void)updateReaderPost:(ReaderPost *)post withRemotePost:(RemoteReaderPost *)remotePost isExisting:(BOOL)existing forTopic:(nullable ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
