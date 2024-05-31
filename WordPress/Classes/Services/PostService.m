#import "PostService.h"
#import "Coordinate.h"
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

- (void)getPostWithID:(NSNumber *)postID
              forBlog:(Blog *)blog
              success:(void (^)(AbstractPost *post))success
              failure:(void (^)(NSError *))failure
{
    id<PostServiceRemote> remote = [self.postServiceRemoteFactory forBlog:blog];
    NSManagedObjectID *blogID = blog.objectID;
    [remote getPostWithID:postID
                  success:^(RemotePost *remotePost){
                      [self.managedObjectContext performBlock:^{
                          Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
                          if (!blog) {
                              return;
                          }
                          if (remotePost) {
                              AbstractPost *post = [blog lookupPostWithID:postID inContext:self.managedObjectContext];
                              
                              if (!post) {
                                  if ([remotePost.type isEqualToString:PostServiceTypePage]) {
                                      post = [blog createPage];
                                  } else {
                                      post = [blog createPost];
                                  }
                              }
                              
                              [PostHelper updatePost:post withRemotePost:remotePost inContext:self.managedObjectContext];
                              [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

                              if (success) {
                                  success(post);
                              }
                          }
                          else if (failure) {
                              NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Retrieved remote post is nil" };
                              failure([NSError errorWithDomain:PostServiceErrorDomain code:0 userInfo:userInfo]);
                          }
                      }];
                  }
                  failure:^(NSError *error) {
                      if (failure) {
                          [self.managedObjectContext performBlock:^{
                              failure(error);
                          }];
                      }
                  }];
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

- (void)uploadPost:(AbstractPost *)post
           success:(void (^)(AbstractPost *post))success
           failure:(void (^)(NSError *error))failure
{
    [self uploadPost:post
forceDraftIfCreating:NO
             success:success
             failure:failure];
}

- (PostServiceUploadingList *)uploadingList
{
    return [PostServiceUploadingList sharedInstance];
}

- (void)uploadPost:(AbstractPost *)post
forceDraftIfCreating:(BOOL)forceDraftIfCreating
           success:(nullable void (^)(AbstractPost * _Nullable post))success
           failure:(nullable void (^)(NSError * _Nullable error))failure
{
    id<PostServiceRemote> remote = [self.postServiceRemoteFactory forBlog:post.blog];
    [self uploadPost:post forceDraftIfCreating:forceDraftIfCreating usingRemote:remote success:success failure:failure];
}

- (void)uploadPost:(AbstractPost *)post
forceDraftIfCreating:(BOOL)forceDraftIfCreating
        usingRemote:(id<PostServiceRemote>)remote
           success:(nullable void (^)(AbstractPost * _Nullable post))success
           failure:(nullable void (^)(NSError * _Nullable error))failure
{
    RemotePost *remotePost = [PostHelper remotePostWithPost:post];

    post.remoteStatus = AbstractPostRemoteStatusPushing;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    NSManagedObjectID *postObjectID = post.objectID;

    // Add the post to the uploading queue list
    [self.uploadingList uploading:postObjectID];
    
    BOOL isFirstTimePublish = post.isFirstTimePublish;

    void (^successBlock)(RemotePost *post) = ^(RemotePost *post) {
        [self.managedObjectContext performBlock:^{
            AbstractPost *postInContext = (AbstractPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:nil];
            if (postInContext) {
                if ([postInContext isRevision]) {
                    postInContext = postInContext.original;
                    [postInContext applyRevision];

                    // If multiple calls to upload the same post are made, we'll delete the revision
                    // only when the last call succeeds.
                    // This avoids deleting an entity that's being used by another call, which can lead to crashes.
                    if ([self.uploadingList isSingleUpload:postObjectID]) {
                        [postInContext deleteRevision];
                    }
                }
                
                postInContext.isFirstTimePublish = isFirstTimePublish;
                [PostHelper updatePost:postInContext withRemotePost:post inContext:self.managedObjectContext];
                postInContext.remoteStatus = AbstractPostRemoteStatusSync;

                [self updateMediaForPost:postInContext success:^{

                    if (success) {
                        success(postInContext);
                    }
                } failure:^(NSError * _Nullable error) {
                    DDLogInfo(@"Error in updateMediaForPost while uploading post. description: %@", error.localizedDescription);
                    // even if media fails to attach we are answering with success because the post upload was successful.
                    if (success) {
                        success(postInContext);
                    }
                }];
            } else {
                // This can happen if the post was deleted right after triggering the upload.
                if (success) {
                    success(nil);
                }
            }

            // Remove the post from the uploading queue list
            [self.uploadingList finishedUploading:postObjectID];
        }];
    };
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:nil];
            if (postInContext) {
                [postInContext markAsFailedAndDraftIfNeeded];
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (failure) {
                failure(error);
            }

            // Remove the post from the uploading queue list
            [self.uploadingList finishedUploading:postObjectID];
        }];
    };

    if ([post.postID longLongValue] > 0) {
        [remote updatePost:remotePost
                   success:successBlock
                   failure:failureBlock];
    } else {
        if (forceDraftIfCreating) {
            remotePost.status = PostStatusDraft;
        }
        [self createPost:remotePost
                  remote:remote
                 success:successBlock
                 failure:failureBlock];
    }
}


/// Creates new post on the server.
/// If the post type is scheduled, another call to update the post is made after creation to fix the modified date.
- (void)createPost:(RemotePost *)post
            remote:(id<PostServiceRemote>)remote
           success:(void (^)(RemotePost *post))success
           failure:(void (^)(NSError *error))failure;
{
    [remote createPost:post success:^(RemotePost *post) {
        if ([post.status isEqualToString:PostStatusScheduled]) {
            [remote updatePost:post success:success failure:failure];
        }
        else {
            success(post);
        }
        
    } failure:failure];
}

#pragma mark - Helpers

- (NSDictionary *)remoteSyncParametersDictionaryForRemote:(nonnull id <PostServiceRemote>)remote
                                              withOptions:(nonnull PostServiceSyncOptions *)options
{
    return [remote dictionaryWithRemoteOptions:options];
}

- (NSArray *)entriesWithKeyLike:(NSString *)key inMetadata:(NSArray *)metadata
{
    return [metadata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key like %@", key]];
}

@end
