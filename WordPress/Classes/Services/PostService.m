#import "PostService.h"
#import "Coordinate.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "ContextManager.h"
#import "CommentService.h"
#import "MediaService.h"
#import "Media.h"
#import "WordPress-Swift.h"
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

- (Post *)createPostForBlog:(Blog *)blog {
    NSAssert(self.managedObjectContext == blog.managedObjectContext, @"Blog's context should be the the same as the service's");
    Post *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Post class]) inManagedObjectContext:self.managedObjectContext];
    post.blog = blog;
    post.remoteStatus = AbstractPostRemoteStatusSync;
    PostCategoryService *postCategoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];

    if (blog.settings.defaultCategoryID && blog.settings.defaultCategoryID.integerValue != PostCategoryUncategorized) {
        PostCategory *category = [postCategoryService findWithBlogObjectID:blog.objectID andCategoryID:blog.settings.defaultCategoryID];
        if (category) {
            [post addCategoriesObject:category];
        }
    }

    post.postFormat = blog.settings.defaultPostFormat;
    post.postType = Post.typeDefaultIdentifier;

    BlogAuthor *author = [blog getAuthorWithId:blog.userID];
    post.authorID = author.userID;
    post.author = author.displayName;

    [blog.managedObjectContext obtainPermanentIDsForObjects:@[post] error:nil];
    NSAssert(![post.objectID isTemporaryID], @"The new post for this blog must have a permanent ObjectID");

    return post;
}

- (Post *)createDraftPostForBlog:(Blog *)blog {
    Post *post = [self createPostForBlog:blog];
    [self initializeDraft:post];
    return post;
}

- (Page *)createPageForBlog:(Blog *)blog {
    NSAssert(self.managedObjectContext == blog.managedObjectContext, @"Blog's context should be the the same as the service's");
    Page *page = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Page class]) inManagedObjectContext:self.managedObjectContext];
    page.blog = blog;
    page.date_created_gmt = [NSDate date];
    page.remoteStatus = AbstractPostRemoteStatusSync;

    BlogAuthor *author = [blog getAuthorWithId:blog.userID];
    page.authorID = author.userID;
    page.author = author.displayName;

    [blog.managedObjectContext obtainPermanentIDsForObjects:@[page] error:nil];
    NSAssert(![page.objectID isTemporaryID], @"The new page for this blog must have a permanent ObjectID");

    return page;
}

- (Page *)createDraftPageForBlog:(Blog *)blog {
    Page *page = [self createPageForBlog:blog];
    [self initializeDraft:page];
    return page;
}


- (void)getFailedPosts:(void (^)( NSArray<AbstractPost *>* posts))result {
    [self.managedObjectContext performBlock:^{
        NSString *entityName = NSStringFromClass([AbstractPost class]);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
        
        request.predicate = [NSPredicate predicateWithFormat:@"remoteStatusNumber == %d", AbstractPostRemoteStatusFailed];
        
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
        
        if (!results) {
            result(@[]);
        } else {
            result(results);
        }
    }];
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
                              AbstractPost *post = [self findPostWithID:postID inBlog:blog];
                              
                              if (!post) {
                                  if ([remotePost.type isEqualToString:PostServiceTypePage]) {
                                      post = [self createPageForBlog:blog];
                                  } else {
                                      post = [self createPostForBlog:blog];
                                  }
                              }
                              
                              [self updatePost:post withRemotePost:remotePost];
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
                               [self mergePosts:[loadedPosts copy]
                                         ofType:postType
                                   withStatuses:options.statuses
                                       byAuthor:options.authorID
                                        forBlog:blogInContext
                                  purgeExisting:options.purgesLocalSync
                              completionHandler:^(NSArray<AbstractPost *> *posts) {
                                  if (success) {
                                      success(posts);
                                  }
                              }];
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
    RemotePost *remotePost = [self remotePostWithPost:post];

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
                [self updatePost:postInContext withRemotePost:post];
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
                [self markAsFailedAndDraftIfNeededWithPost:postInContext];
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

        [remote createPost:remotePost
                   success:successBlock
                   failure:failureBlock];
    }
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
    return ^(RemotePost *post, NSString *previewURL) {
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
    RemotePost *remotePost = [self remotePostWithPost:post];

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

#pragma mark - Delete, Trashing, Restoring

- (void)deletePost:(AbstractPost *)post
           success:(void (^)(void))success
           failure:(void (^)(NSError *error))failure
{
    void (^privateBlock)(void) = ^void() {
        NSNumber *postID = post.postID;
        if ([postID longLongValue] > 0) {
            RemotePost *remotePost = [self remotePostWithPost:post];
            id<PostServiceRemote> remote = [self.postServiceRemoteFactory forBlog:post.blog];
            [remote deletePost:remotePost success:success failure:failure];
        }
        [self.managedObjectContext deleteObject:post];
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    };
    
    if ([post isRevision]) {
        [self deletePost:post.original success:privateBlock failure:failure];
    } else {
        privateBlock();
    }
}

- (void)trashPost:(AbstractPost *)post
          success:(void (^)(void))success
          failure:(void (^)(NSError *error))failure
{
    if ([post.status isEqualToString:PostStatusTrash]) {
        [self deletePost:post success:success failure:failure];
        return;
    }
    
    void(^privateBodyBlock)(void) = ^void() {
        post.restorableStatus = post.status;
        
        NSNumber *postID = post.postID;
        
        if ([post isRevision] || [postID longLongValue] <= 0) {
            post.status = PostStatusTrash;
            
            if (success) {
                success();
            }
            
            return;
        }
        
        [self trashRemotePostWithPost:post
                              success:success
                              failure:failure];
    };
    
    if ([post isRevision]) {
        [self trashPost:post.original
                success:privateBodyBlock
                failure:failure];
    } else {
        privateBodyBlock();
    }
}

- (void)trashRemotePostWithPost:(AbstractPost*)post
                        success:(void (^)(void))success
                        failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *postObjectID = post.objectID;
    
    void (^successBlock)(RemotePost *post) = ^(RemotePost *remotePost) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            if (!remotePost || [remotePost.status isEqualToString:PostStatusDeleted]) {
                [self.managedObjectContext deleteObject:post];
            } else {
                [self updatePost:postInContext withRemotePost:remotePost];
                postInContext.latest.statusAfterSync = postInContext.statusAfterSync;
                postInContext.latest.status = postInContext.status;
            }
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }
        if (success) {
            success();
        }
    };
    
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            postInContext.restorableStatus = nil;
        }
        if (failure){
            failure(error);
        }
    };
    
    RemotePost *remotePost = [self remotePostWithPost:post];
    id<PostServiceRemote> remote = [self.postServiceRemoteFactory forBlog:post.blog];
    [remote trashPost:remotePost success:successBlock failure:failureBlock];
}

- (void)restorePost:(AbstractPost *)post
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure
{
    void (^privateBodyBlock)(void) = ^void() {
        post.status = post.restorableStatus;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        
        if (![post isRevision] && [post.postID longLongValue] > 0) {
            [self restoreRemotePostWithPost:post success:success failure:failure];
        } else {
            if (success) {
                success();
            }
        }
    };
    
    if (post.isRevision) {
        [self restorePost:post.original
                  success:privateBodyBlock
                  failure:failure];
        
        return;
    } else {
        privateBodyBlock();
    }
}

- (void)restoreRemotePostWithPost:(AbstractPost*)post
                          success:(void (^)(void))success
                          failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *postObjectID = post.objectID;
    
    void (^successBlock)(RemotePost *post) = ^(RemotePost *remotePost) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        postInContext.restorableStatus = nil;
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            [self updatePost:postInContext withRemotePost:remotePost];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }
        if (success) {
            success();
        }
    };
    
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            // Put the post back in the trash bin.
            postInContext.status = PostStatusTrash;
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }
        if (failure){
            failure(error);
        }
    };
    
    RemotePost *remotePost = [self remotePostWithPost:post];
    if (post.restorableStatus) {
        remotePost.status = post.restorableStatus;
    } else {
        // Assign a status of draft to the remote post. The WordPress.com REST API will
        // ignore this and should restore the post's previous status. The XML-RPC API
        // needs a status assigned to move a post out of the trash folder. Draft is the
        // safest option when we don't know what the status was previously.
        remotePost.status = PostStatusDraft;
    }
    
    id<PostServiceRemote> remote = [self.postServiceRemoteFactory forBlog:post.blog];
    [remote restorePost:remotePost success:successBlock failure:failureBlock];
}

#pragma mark - Helpers

- (void)initializeDraft:(AbstractPost *)post {
    post.remoteStatus = AbstractPostRemoteStatusLocal;
    post.dateModified = [NSDate date];
    post.status = PostStatusDraft;
}

- (void)mergePosts:(NSArray <RemotePost *> *)remotePosts
            ofType:(NSString *)syncPostType
      withStatuses:(NSArray *)statuses
          byAuthor:(NSNumber *)authorID
           forBlog:(Blog *)blog
     purgeExisting:(BOOL)purge
 completionHandler:(void (^)(NSArray <AbstractPost *> *posts))completion
{
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:remotePosts.count];
    for (RemotePost *remotePost in remotePosts) {
        AbstractPost *post = [self findPostWithID:remotePost.postID inBlog:blog];
        if (!post) {
            if ([remotePost.type isEqualToString:PostServiceTypePage]) {
                // Create a Page entity for posts with a remote type of "page"
                post = [self createPageForBlog:blog];
            } else {
                // Create a Post entity for any other posts that have a remote post type of "post" or a custom post type.
                post = [self createPostForBlog:blog];
            }
        }
        [self updatePost:post withRemotePost:remotePost];
        [posts addObject:post];
    }
    
    if (purge) {
        // Set up predicate for fetching any posts that could be purged for the sync.
        NSPredicate *predicate  = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original = NULL) AND (revision = NULL) AND (blog = %@)", @(AbstractPostRemoteStatusSync), blog];
        if ([statuses count] > 0) {
            NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"status IN %@", statuses];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, statusPredicate]];
        }
        if (authorID) {
            NSPredicate *authorPredicate = [NSPredicate predicateWithFormat:@"authorID = %@", authorID];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, authorPredicate]];
        }
        
        NSFetchRequest *request;
        if ([syncPostType isEqualToString:PostServiceTypeAny]) {
            // If syncing "any" posts, set up the fetch for any AbstractPost entities (including child entities).
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([AbstractPost class])];
        } else if ([syncPostType isEqualToString:PostServiceTypePage]) {
            // If syncing "page" posts, set up the fetch for any Page entities.
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Page class])];
        } else {
            // If not syncing "page" or "any" post, use the Post entity.
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
            // Include the postType attribute in the predicate.
            NSPredicate *postTypePredicate = [NSPredicate predicateWithFormat:@"postType = %@", syncPostType];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, postTypePredicate]];
        }
        request.predicate = predicate;
        
        NSError *error;
        NSArray *existingPosts = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"Error fetching existing posts for purging: %@", error);
        } else {
            NSSet *postsToKeep = [NSSet setWithArray:posts];
            NSMutableSet *postsToDelete = [NSMutableSet setWithArray:existingPosts];
            // Delete the posts not being updated.
            [postsToDelete minusSet:postsToKeep];
            for (AbstractPost *post in postsToDelete) {
                DDLogInfo(@"Deleting Post: %@", post);
                [self.managedObjectContext deleteObject:post];
            }
        }
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    if (completion) {
        completion(posts);
    }
}

- (AbstractPost *)findPostWithID:(NSNumber *)postID inBlog:(Blog *)blog {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([AbstractPost class])];
    request.predicate = [NSPredicate predicateWithFormat:@"blog = %@ AND original = NULL AND postID = %@", blog, postID];
    NSArray *posts = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [posts firstObject];
}

- (NSUInteger)countPostsWithoutRemote
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([AbstractPost class])];
    request.predicate = [NSPredicate predicateWithFormat:@"postID = NULL OR postID <= 0"];

    return [self.managedObjectContext countForFetchRequest:request error:nil];
}

- (NSDictionary *)remoteSyncParametersDictionaryForRemote:(nonnull id <PostServiceRemote>)remote
                                              withOptions:(nonnull PostServiceSyncOptions *)options
{
    return [remote dictionaryWithRemoteOptions:options];
}

- (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost {
    NSNumber *previousPostID = post.postID;
    post.postID = remotePost.postID;
    // Used to populate author information for self-hosted sites.
    BlogAuthor *author = [post.blog getAuthorWithId:remotePost.authorID];

    post.author = remotePost.authorDisplayName ?: author.displayName;
    post.authorID = remotePost.authorID;
    post.date_created_gmt = remotePost.date;
    post.dateModified = remotePost.dateModified;
    post.postTitle = remotePost.title;
    post.permaLink = [remotePost.URL absoluteString];
    post.content = remotePost.content;
    post.status = remotePost.status;
    post.password = remotePost.password;
    
    if (remotePost.postThumbnailID != nil) {
        post.featuredImage = [Media existingOrStubMediaWithMediaID: remotePost.postThumbnailID inBlog:post.blog];
    } else {
        post.featuredImage = nil;
    }
    
    post.pathForDisplayImage = remotePost.pathForDisplayImage;
    if (post.pathForDisplayImage.length == 0) {
        [post updatePathForDisplayImageBasedOnContent];
    }
    post.authorAvatarURL = remotePost.authorAvatarURL ?: author.avatarURL;
    post.mt_excerpt = remotePost.excerpt;
    post.wp_slug = remotePost.slug;
    post.suggested_slug = remotePost.suggestedSlug;
    
    if ([remotePost.revisions wp_isValidObject]) {
        post.revisions = [remotePost.revisions copy];
    }

    if (remotePost.postID != previousPostID) {
        [self updateCommentsForPost:post];
    }

    post.autosaveTitle = remotePost.autosave.title;
    post.autosaveExcerpt = remotePost.autosave.excerpt;
    post.autosaveContent = remotePost.autosave.content;
    post.autosaveModifiedDate = remotePost.autosave.modifiedDate;
    post.autosaveIdentifier = remotePost.autosave.identifier;

    if ([post isKindOfClass:[Page class]]) {
        Page *pagePost = (Page *)post;
        pagePost.parentID = remotePost.parentID;
    } else if ([post isKindOfClass:[Post class]]) {
        Post *postPost = (Post *)post;
        postPost.commentCount = remotePost.commentCount;
        postPost.likeCount = remotePost.likeCount;
        postPost.postFormat = remotePost.format;
        postPost.tags = [remotePost.tags componentsJoinedByString:@","];
        postPost.postType = remotePost.type;
        postPost.isStickyPost = (remotePost.isStickyPost != nil) ? remotePost.isStickyPost.boolValue : NO;
        [self updatePost:postPost withRemoteCategories:remotePost.categories];

        Coordinate *geolocation = nil;
        NSString *latitudeID = nil;
        NSString *longitudeID = nil;
        NSString *publicID = nil;
        NSString *publicizeMessage = nil;
        NSString *publicizeMessageID = nil;
        NSMutableDictionary *disabledPublicizeConnections = [NSMutableDictionary dictionary];
        if (remotePost.metadata) {
            NSDictionary *latitudeDictionary = [self dictionaryWithKey:@"geo_latitude" inMetadata:remotePost.metadata];
            NSDictionary *longitudeDictionary = [self dictionaryWithKey:@"geo_longitude" inMetadata:remotePost.metadata];
            NSDictionary *geoPublicDictionary = [self dictionaryWithKey:@"geo_public" inMetadata:remotePost.metadata];
            if (latitudeDictionary && longitudeDictionary) {
                NSNumber *latitude = [latitudeDictionary numberForKey:@"value"];
                NSNumber *longitude = [longitudeDictionary numberForKey:@"value"];
                CLLocationCoordinate2D coord;
                coord.latitude = [latitude doubleValue];
                coord.longitude = [longitude doubleValue];
                geolocation = [[Coordinate alloc] initWithCoordinate:coord];
                latitudeID = [latitudeDictionary stringForKey:@"id"];
                longitudeID = [longitudeDictionary stringForKey:@"id"];
                publicID = [geoPublicDictionary stringForKey:@"id"];
            }
            NSDictionary *publicizeMessageDictionary = [self dictionaryWithKey:@"_wpas_mess" inMetadata:remotePost.metadata];
            publicizeMessage = [publicizeMessageDictionary stringForKey:@"value"];
            publicizeMessageID = [publicizeMessageDictionary stringForKey:@"id"];

            NSArray *disabledPublicizeConnectionsArray = [self entriesWithKeyLike:@"_wpas_skip_*" inMetadata:remotePost.metadata];
            for (NSDictionary *disabledConnectionDictionary in disabledPublicizeConnectionsArray) {
                NSString *dictKey = [disabledConnectionDictionary stringForKey:@"key"];
                // We only want to keep the keyringID value from the key
                NSNumber *keyringConnectionID = @([[dictKey stringByReplacingOccurrencesOfString:@"_wpas_skip_"
                                                                                      withString:@""]integerValue]);
                NSMutableDictionary *keyringConnectionData = [NSMutableDictionary dictionaryWithCapacity:2];
                keyringConnectionData[@"id"] = [disabledConnectionDictionary stringForKey:@"id"];
                keyringConnectionData[@"value"] = [disabledConnectionDictionary stringForKey:@"value"];
                disabledPublicizeConnections[keyringConnectionID] = keyringConnectionData;
            }
        }
        postPost.publicID = publicID;
        postPost.publicizeMessage = publicizeMessage;
        postPost.publicizeMessageID = publicizeMessageID;
        postPost.disabledPublicizeConnections = disabledPublicizeConnections;
    }

    post.statusAfterSync = post.status;
}

- (RemotePost *)remotePostWithPost:(AbstractPost *)post
{
    RemotePost *remotePost = [RemotePost new];
    remotePost.postID = post.postID;
    remotePost.date = post.date_created_gmt;
    remotePost.dateModified = post.dateModified;
    remotePost.title = post.postTitle ?: @"";
    remotePost.content = post.content;
    remotePost.status = post.status;
    if (post.featuredImage) {
        remotePost.postThumbnailID = post.featuredImage.mediaID;
    }
    remotePost.password = post.password;
    remotePost.type = @"post";
    remotePost.authorAvatarURL = post.authorAvatarURL;
    remotePost.authorID = post.authorID;
    remotePost.excerpt = post.mt_excerpt;
    remotePost.slug = post.wp_slug;

    if ([post isKindOfClass:[Page class]]) {
        Page *pagePost = (Page *)post;
        remotePost.parentID = pagePost.parentID;
        remotePost.type = @"page";
    }
    if ([post isKindOfClass:[Post class]]) {
        Post *postPost = (Post *)post;
        remotePost.format = postPost.postFormat;        
        remotePost.tags = [[postPost.tags componentsSeparatedByString:@","] wp_map:^id(NSString *obj) {
            return [obj stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        }];
        remotePost.categories = [self remoteCategoriesForPost:postPost];
        remotePost.metadata = [self remoteMetadataForPost:postPost];

        // Because we can't get what's the self-hosted non JetPack site capabilities
        // only Admin users are allowed to set a post as sticky.
        // This doesn't affect WPcom sites.
        //
        BOOL canMarkPostAsSticky = ([post.blog supports:BlogFeatureWPComRESTAPI] || post.blog.isAdmin);
        remotePost.isStickyPost = canMarkPostAsSticky ? @(postPost.isStickyPost) : nil;
    }

    remotePost.isFeaturedImageChanged = post.isFeaturedImageChanged;

    return remotePost;
}

- (NSArray *)remoteCategoriesForPost:(Post *)post
{
    return [[post.categories allObjects] wp_map:^id(PostCategory *category) {
        return [self remoteCategoryWithCategory:category];
    }];
}

- (RemotePostCategory *)remoteCategoryWithCategory:(PostCategory *)category
{
    RemotePostCategory *remoteCategory = [RemotePostCategory new];
    remoteCategory.categoryID = category.categoryID;
    remoteCategory.name = category.categoryName;
    remoteCategory.parentID = category.parentID;
    return remoteCategory;
}

- (NSArray *)remoteMetadataForPost:(Post *)post {
    NSMutableArray *metadata = [NSMutableArray arrayWithCapacity:3];

    if (post.publicID) {
        NSMutableDictionary *publicDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        publicDictionary[@"id"] = [post.publicID numericValue];
        [metadata addObject:publicDictionary];
    }
    if (post.publicizeMessageID || post.publicizeMessage.length) {
        NSMutableDictionary *publicizeMessageDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        if (post.publicizeMessageID) {
            publicizeMessageDictionary[@"id"] = post.publicizeMessageID;
        }
        publicizeMessageDictionary[@"key"] = @"_wpas_mess";
        publicizeMessageDictionary[@"value"] = post.publicizeMessage.length ? post.publicizeMessage : @"";
        [metadata addObject:publicizeMessageDictionary];
    }
    for (NSNumber *keyringConnectionId in post.disabledPublicizeConnections.allKeys) {
        NSMutableDictionary *disabledConnectionsDictionary = [NSMutableDictionary dictionaryWithCapacity: 3];
        // We need to compose back the key
        disabledConnectionsDictionary[@"key"] = [NSString stringWithFormat:@"_wpas_skip_%@",
                                                                           keyringConnectionId];
        [disabledConnectionsDictionary addEntriesFromDictionary:post.disabledPublicizeConnections[keyringConnectionId]];
        [metadata addObject:disabledConnectionsDictionary];
    }
    return metadata;
}

- (void)updatePost:(Post *)post withRemoteCategories:(NSArray *)remoteCategories {
    NSManagedObjectID *blogObjectID = post.blog.objectID;
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
    [categories removeAllObjects];
    for (RemotePostCategory *remoteCategory in remoteCategories) {
        PostCategory *category = [categoryService findWithBlogObjectID:blogObjectID andCategoryID:remoteCategory.categoryID];
        if (!category) {
            category = [categoryService newCategoryForBlogObjectID:blogObjectID];
            category.categoryID = remoteCategory.categoryID;
            category.categoryName = remoteCategory.name;
            category.parentID = remoteCategory.parentID;
        }
        [categories addObject:category];
    }
}

- (void)updateCommentsForPost:(AbstractPost *)post
{
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    NSMutableSet *currentComments = [post mutableSetValueForKey:@"comments"];
    NSSet *allComments = [commentService findCommentsWithPostID:post.postID inBlog:post.blog];
    [currentComments addObjectsFromArray:[allComments allObjects]];
}

- (NSDictionary *)dictionaryWithKey:(NSString *)key inMetadata:(NSArray *)metadata {
    NSArray *matchingEntries = [metadata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key = %@", key]];
    // In theory, there shouldn't be duplicated fields, but I've seen some bugs where there's more than one geo_* value
    // In any case, they should be sorted by id, so `lastObject` should have the newer value
    return [matchingEntries lastObject];
}

- (NSArray *)entriesWithKeyLike:(NSString *)key inMetadata:(NSArray *)metadata
{
    return [metadata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key like %@", key]];
}

@end
