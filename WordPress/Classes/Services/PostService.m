#import "PostService.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "CoreDataStack.h"
#import "CommentService.h"
#import "MediaService.h"
#import "Media.h"
#import "WordPress-Swift.h"
#import "PostHelper.h"
@import WordPressKit;
@import WordPressShared;

PostServiceType const PostServiceTypePost = @"post";
PostServiceType const PostServiceTypePage = @"page";
PostServiceType const PostServiceTypeAny = @"any";
NSString * const PostServiceErrorDomain = @"PostServiceErrorDomain";

const NSUInteger PostServiceDefaultNumberToSync = 40;

@interface PostService ()

@end

@implementation PostService

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    return [self initWithManagedObjectContext:context
                     postServiceRemoteFactory:[PostServiceRemoteFactory.alloc init]];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                    postServiceRemoteFactory:(PostServiceRemoteFactory *)postServiceRemoteFactory {
    if (self = [super initWithManagedObjectContext:context]) {
        self.postServiceRemoteFactory = postServiceRemoteFactory;
    }
    return self;
}

- (void)syncPostsOfType:(PostServiceType)postType
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure
{
    [self syncPostsOfType:postType
              withOptions:nil
                  forBlog:blog
                  success:success
                  failure:failure];
}

- (void)syncPostsOfType:(PostServiceType)postType
            withOptions:(PostServiceSyncOptions *)options
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure
{
    [self syncPostsOfType:postType
              withOptions:options
                  forBlog:blog
              loadedPosts:[NSMutableArray new]
                  syncAll:(postType == PostServiceTypePage)
                  success:success
                  failure:failure];
}

- (void)syncPostsOfType:(PostServiceType)postType
            withOptions:(PostServiceSyncOptions *)options
                forBlog:(Blog *)blog
            loadedPosts:(NSMutableArray <RemotePost *>*)loadedPosts
                syncAll:(BOOL)syncAll
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    id<PostServiceRemote> remote = [self.postServiceRemoteFactory forBlog:blog];

    if (loadedPosts.count > 0) {
        options.offset = @(loadedPosts.count);
    }

    NSDictionary *remoteOptions = options ? [self remoteSyncParametersDictionaryForRemote:remote withOptions:options] : nil;
    [remote getPostsOfType:postType
                   options:remoteOptions
                   success:^(NSArray <RemotePost *> *remotePosts) {
        [loadedPosts addObjectsFromArray:remotePosts];

        if (syncAll && remotePosts.count >= options.number.integerValue) {
            [self syncPostsOfType:postType
                      withOptions:options
                          forBlog:blog
                      loadedPosts:loadedPosts
                          syncAll:syncAll
                          success:success
                          failure:failure];
        } else {
            [self.managedObjectContext performBlock:^{
                NSError *error;
                Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
                if (!blogInContext || error) {
                    DDLogError(@"Could not retrieve blog in context %@", (error ? [NSString stringWithFormat:@"with error: %@", error] : @""));
                    return;
                }
                NSArray *posts = [PostHelper mergePosts:[loadedPosts copy]
                                                 ofType:postType
                                           withStatuses:options.statuses
                                               byAuthor:options.authorID
                                                forBlog:blogInContext
                                          purgeExisting:options.purgesLocalSync
                                              inContext:self.managedObjectContext];

                [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                    // Call the completion block after context is saved. The callback is called on the context queue because `posts`
                    // contains models that are bound to the `self.managedObjectContext` object.
                    if (success) {
                        [self.managedObjectContext performBlock:^{
                            success(posts);
                        }];
                    }
                } onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
            }];
        }
    } failure:^(NSError *error) {
        if (failure) {
            [self.managedObjectContext performBlock:^{
                failure(error);
            }];
        }
    }];
}

#pragma mark - Helpers

- (NSDictionary *)remoteSyncParametersDictionaryForRemote:(nonnull id <PostServiceRemote>)remote
                                              withOptions:(nonnull PostServiceSyncOptions *)options
{
    return [remote dictionaryWithRemoteOptions:options];
}

@end
