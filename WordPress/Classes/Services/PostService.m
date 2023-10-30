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

    // It's possible that the post has been updated while the user is making changes to the post in the app.
    // In that case, this function here will overwrite the latest revision on the server.
    //
    // See also: https://github.com/wordpress-mobile/WordPress-iOS/issues/8111
    //
    // Here we check (only for WP.com posts for now) and log events for such scenario to get a sense of how
    // often it occurs.
    //
    // The updating post API is made in parallel with this get revision API request–we don't want to delay
    // saving post. In theory, it's possible that the updating post API finishes before the server handles
    // the get revision API request, which means we'll receive an incorrect revision. But that should be
    // extremely rare and we'll ignore it for now.
    [self checkLatestRevisionForPost:post usingRemote:remote];

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

#pragma mark - Autosave Related

typedef void (^AutosaveFailureBlock)(NSError *error);
typedef void (^AutosaveSuccessBlock)(RemotePost *post, NSString *previewURL);

- (NSError *)defaultAutosaveError
{
    return [NSError errorWithDomain:PostServiceErrorDomain
                               code:0
                           userInfo:@{ NSLocalizedDescriptionKey : @"Previews are unavailable for this kind of post." }];
}

- (AutosaveFailureBlock)wrappedAutosaveFailureBlock:(AbstractPost *)post failure:(void (^)(NSError * _Nullable error))failure
{
    NSManagedObjectID *postObjectID = post.objectID;
    return ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            AbstractPost *postInContext = (AbstractPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:nil];
            if (postInContext) {
                postInContext.remoteStatus = AbstractPostRemoteStatusFailed;
            }

            failure(error);
        }];
    };
}

- (AutosaveSuccessBlock)wrappedAutosaveSuccessBlock:(NSManagedObjectID *)postObjectID
                                            success:(void (^)(AbstractPost *post, NSString *previewURL))success
{
    return ^(RemotePost *__unused post, NSString *previewURL) {
        [self.managedObjectContext performBlock:^{
            AbstractPost *postInContext = (AbstractPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:nil];
            if (postInContext) {
                postInContext.remoteStatus = AbstractPostRemoteStatusAutoSaved;
                [self updateMediaForPost:postInContext success:^{
                    if (success) {
                        success(postInContext, previewURL);
                    }
                } failure:^(NSError * _Nullable error) {
                    DDLogInfo(@"Error in updateMediaForPost while remote auto-saving post. description: %@", error.localizedDescription);
                    // even if media fails to attach we are answering with success because the post auto-save was successful.
                    if (success) {
                        success(postInContext, previewURL);
                    }
                }];
            } else {
                // This can happen if the post was deleted right after triggering the auto-save.
                if (success) {
                    success(nil, nil);
                }
            }
        }];
    };

}

- (void)autoSave:(AbstractPost *)post
         success:(void (^)(AbstractPost *post, NSString *previewURL))success
         failure:(void (^)(NSError * _Nullable error))failure
{
    id<PostServiceRemote> remote = [self.postServiceRemoteFactory forBlog:post.blog];
    if ([remote isKindOfClass:[PostServiceRemoteREST class]]) {
        [self handleAutoSaveWithRestRemote:(PostServiceRemoteREST *)remote forPost:post success:success failure:failure];

    } else if ([post originalIsDraft] && [post isDraft]) {
        [self uploadPost:post
                 success:^(AbstractPost * _Nonnull post) {
                     success(post, nil);
                 } failure:failure];

    } else {
        NSError *defaultError = [self defaultAutosaveError];
        AutosaveFailureBlock failureBlock = [self wrappedAutosaveFailureBlock:post failure:failure];
        failureBlock(defaultError);
    }
}

- (void)handleAutoSaveWithRestRemote:(PostServiceRemoteREST *)restRemote
                             forPost:(AbstractPost *)post
                             success:(void (^)(AbstractPost *post, NSString *previewURL))success
                             failure:(void (^)(NSError * _Nullable error))failure
{
    NSManagedObjectID *postObjectID = post.objectID;
    RemotePost *remotePost = [PostHelper remotePostWithPost:post];

    AutosaveSuccessBlock autosaveSuccessBlock = [self wrappedAutosaveSuccessBlock:postObjectID success:success];
    AutosaveFailureBlock setPostAsFailedAndCallFailureBlock = [self wrappedAutosaveFailureBlock:post failure:failure];

    // The autoSave endpoint returns an exception on posts that do not exist on the server
    // so we'll create the post instead if necessary.
    BOOL mustBeCreated = ![post hasRemote];

    if (mustBeCreated) {
        // Abort if the status is trashed/deleted. We'd rather not automatically create a
        // locally trashed post as drafts in the server.
        if ([post.status isEqualToString:PostStatusTrash] || [post.status isEqualToString:PostStatusDeleted]) {
            NSError *error = [self defaultAutosaveError];
            setPostAsFailedAndCallFailureBlock(error);
            return;
        }

        [self uploadPost:post
    forceDraftIfCreating:YES
                 success:^(AbstractPost * _Nonnull post) {
                     success(post, nil);
                 }
                 failure:failure];
        return;
    }

    // Calling the v1.1 autosave endpoint for a draft post will close
    // the comments for the post. See https://github.com/wordpress-mobile/WordPress-iOS/issues/13079
    // and p3hLNG-15Z-p2 for more background on this issue.
    // For drafts, we can just call uploadPost and a new revision is
    // automatically created anyway. We check original is draft since
    // the post should be a draft on the server if we're uploading vs
    // autosaving.
    [restRemote getPostWithID:remotePost.postID success:^(RemotePost *tempPost) {
        if ([tempPost.status isEqualToString:PostStatusDraft]) {

            // We have to be careful about uploading when the status has been
            // changed locally. Since the post is a draft on the server,
            // use the draft status now, and restore to whatever the status
            // might have been set to after the call completes.
            NSString *savedStatus = post.status;
            post.status = PostStatusDraft;

            [self uploadPost:post
            success:^(AbstractPost * _Nonnull post) {
                post.status = savedStatus;
                success(post, nil);
            } failure:^(NSError * _Nonnull error) {
                post.status = savedStatus;
                failure(error);
            }];

        } else {
            [restRemote autoSave:remotePost
                         success:autosaveSuccessBlock
                         failure:setPostAsFailedAndCallFailureBlock];
        }
    } failure:^(NSError *error) {
        setPostAsFailedAndCallFailureBlock(error);
    }];

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
