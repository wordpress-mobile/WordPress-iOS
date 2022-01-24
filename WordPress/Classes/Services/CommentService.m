#import "CommentService.h"
#import "AccountService.h"
#import "Blog.h"
#import "ContextManager.h"
#import "ReaderPost.h"
#import "WPAccount.h"
#import "PostService.h"
#import "AbstractPost.h"
#import "WordPress-Swift.h"


NSUInteger const WPTopLevelHierarchicalCommentsPerPage = 20;
NSInteger const  WPNumberOfCommentsToSync = 100;
static NSTimeInterval const CommentsRefreshTimeoutInSeconds = 60 * 5; // 5 minutes

@interface CommentService ()

@property (nonnull, strong, nonatomic) CommentServiceRemoteFactory *remoteFactory;

@end

@implementation CommentService

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    return [self initWithManagedObjectContext:context
                  commentServiceRemoteFactory:[CommentServiceRemoteFactory new]];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                 commentServiceRemoteFactory:(CommentServiceRemoteFactory *)remoteFactory
{
    self = [super initWithManagedObjectContext:context];
    if (self) {
        self.remoteFactory = remoteFactory;
    }

    return self;
}

+ (NSMutableSet *)syncingCommentsLocks
{
    static NSMutableSet *syncingCommentsLocks;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        syncingCommentsLocks = [NSMutableSet set];
    });
    return syncingCommentsLocks;
}

+ (BOOL)isSyncingCommentsForBlog:(Blog *)blog {
    return [self isSyncingCommentsForBlogID:blog.objectID];
}

+ (BOOL)isSyncingCommentsForBlogID:(NSManagedObjectID *)blogID
{
    NSParameterAssert(blogID);
    return [[self syncingCommentsLocks] containsObject:blogID];
}

+ (BOOL)startSyncingCommentsForBlog:(NSManagedObjectID *)blogID
{
    NSParameterAssert(blogID);
    @synchronized([self syncingCommentsLocks]) {
        if ([self isSyncingCommentsForBlogID:blogID]){
            return NO;
        }
        [[self syncingCommentsLocks] addObject:blogID];
         return YES;
    }
}

+ (void)stopSyncingCommentsForBlog:(NSManagedObjectID *)blogID
{
    NSParameterAssert(blogID);
    @synchronized([self syncingCommentsLocks]) {
        [[self syncingCommentsLocks] removeObject:blogID];
    }
}

+ (BOOL)shouldRefreshCacheFor:(Blog *)blog
{
    NSDate *lastSynced = blog.lastCommentsSync;
    BOOL isSyncing = [self isSyncingCommentsForBlog:blog];
    return !isSyncing && (lastSynced == nil || ABS(lastSynced.timeIntervalSinceNow) > CommentsRefreshTimeoutInSeconds);
}

- (NSSet *)findCommentsWithPostID:(NSNumber *)postID inBlog:(Blog *)blog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postID = %@", postID];
    return [blog.comments filteredSetUsingPredicate:predicate];
}

#pragma mark Public methods

#pragma mark Blog-centric methods

// Create comment
- (Comment *)createCommentForBlog:(Blog *)blog
{
    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class])
                                                     inManagedObjectContext:blog.managedObjectContext];
    comment.dateCreated = [NSDate new];
    comment.blog = blog;
    return comment;
}

// Create reply
- (Comment *)createReplyForComment:(Comment *)comment
{
    Comment *reply = [self createCommentForBlog:comment.blog];
    reply.postID = comment.postID;
    reply.post = comment.post;
    reply.parentID = comment.commentID;
    reply.status = [Comment descriptionFor:CommentStatusTypeApproved];
    return reply;
}

// Restore draft reply
- (Comment *)restoreReplyForComment:(Comment *)comment
{
    NSFetchRequest *existingReply = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Comment class])];
    NSString *draft = [Comment descriptionFor:CommentStatusTypeDraft];
    existingReply.predicate = [NSPredicate predicateWithFormat:@"status == %@ AND parentID == %@",
                               draft,
                               comment.commentID];
    existingReply.fetchLimit = 1;

    NSError *error;
    NSArray *replies = [self.managedObjectContext executeFetchRequest:existingReply error:&error];
    if (error) {
        DDLogError(@"Failed to fetch reply: %@", error);
    }

    Comment *reply = [replies firstObject];
    if (!reply) {
        reply = [self createReplyForComment:comment];
    }

    reply.status = draft;
    return reply;
}

// Sync comments

- (void)syncCommentsForBlog:(Blog *)blog
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure
{
    [self syncCommentsForBlog:blog withStatus:CommentStatusFilterAll success:success failure:failure];
}

- (void)syncCommentsForBlog:(Blog *)blog
                 withStatus:(CommentStatusFilter)status
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure
{
    [self syncCommentsForBlog:blog withStatus:status filterUnreplied:NO success:success failure:failure];
}

- (void)syncCommentsForBlog:(Blog *)blog
                 withStatus:(CommentStatusFilter)status
            filterUnreplied:(BOOL)filterUnreplied
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogID = blog.objectID;
    if (![[self class] startSyncingCommentsForBlog:blogID]){
        // We assume success because a sync is already running and it will change the comments
        if (success) {
            success(YES);
        }
        return;
    }
    
    // If the comment status is not specified, default to all.
    CommentStatusFilter commentStatus = status ?: CommentStatusFilterAll;
    NSDictionary *options = @{ @"status": [NSNumber numberWithInt:commentStatus] };

    id<CommentServiceRemote> remote = [self remoteForBlog:blog];

    [remote getCommentsWithMaximumCount:WPNumberOfCommentsToSync
                                options:options
                                success:^(NSArray *comments) {
        [self.managedObjectContext performBlock:^{
            Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
            
            if (!blogInContext) {
                return;
            }
            NSArray *fetchedComments = comments;
            if (filterUnreplied) {
                NSString *author = @"";
                if (blog.account) {
                    // See if there is a linked Jetpack user that we should use.
                    BlogAuthor *blogAuthor = [blogInContext getAuthorWithLinkedID:blog.account.userID];
                    author = (blogAuthor) ? blogAuthor.email : blogInContext.account.email;
                } else {
                    BlogAuthor *blogAuthor = [blogInContext getAuthorWithId:blogInContext.userID];
                    author = (blogAuthor) ? blogAuthor.email : author;
                }
                fetchedComments = [self filterUnrepliedComments:comments forAuthor:author];
            }
            
            [self mergeComments:fetchedComments
                        forBlog:blog
                  purgeExisting:YES
              completionHandler:^{
                [[self class] stopSyncingCommentsForBlog:blogID];
                
                [self.managedObjectContext performBlock:^{
                    blogInContext.lastCommentsSync = [NSDate date];
                    [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                        if (success) {
                            // Note:
                            // We'll assume that if the requested page size couldn't be filled, there are no
                            // more comments left to retrieve.  However, for unreplied comments, we only fetch the first page (for now).
                            BOOL hasMore = comments.count >= WPNumberOfCommentsToSync && !filterUnreplied;
                            success(hasMore);
                        }
                    }];
                }];
            }];
        }];
    } failure:^(NSError *error) {
        [[self class] stopSyncingCommentsForBlog:blogID];
        if (failure) {
            [self.managedObjectContext performBlock:^{
                failure(error);
            }];
        }
    }];
}

- (NSArray *)filterUnrepliedComments:(NSArray *)comments forAuthor:(NSString *)author {
    NSMutableArray *marr = [comments mutableCopy];

    NSMutableArray *foundIDs = [NSMutableArray array];
    NSMutableArray *discardables = [NSMutableArray array];

    // get ids of comments that user has replied to.
    for (RemoteComment *comment in marr) {
        if (![comment.authorEmail isEqualToString:author] || !comment.parentID) {
            continue;
        }
        [foundIDs addObject:comment.parentID];
        [discardables addObject:comment];
    }
    // Discard the replies, they aren't needed.
    [marr removeObjectsInArray:discardables];
    [discardables removeAllObjects];

    // Get the parents, grandparents etc. and discard those too.
    while ([foundIDs count] > 0) {
        NSArray *needles = [foundIDs copy];
        [foundIDs removeAllObjects];
        for (RemoteComment *comment in marr) {
            if ([needles containsObject:comment.commentID]) {
                if (comment.parentID) {
                    [foundIDs addObject:comment.parentID];
                }
                [discardables addObject:comment];
            }
        }
        // Discard the matches, and keep looking if items were found.
        [marr removeObjectsInArray:discardables];
        [discardables removeAllObjects];
    }

    // remove any remaining child comments.
    // remove any remaining root comments made by the user.
    for (RemoteComment *comment in marr) {
        if (comment.parentID.intValue != 0) {
            [discardables addObject:comment];
        } else if ([comment.authorEmail isEqualToString:author]) {
            [discardables addObject:comment];
        }
    }
    [marr removeObjectsInArray:discardables];

    // these are the most recent unreplied comments from other users.
    return [NSArray arrayWithArray:marr];
}

- (Comment *)oldestCommentForBlog:(Blog *)blog {
    NSString *entityName = NSStringFromClass([Comment class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [NSPredicate predicateWithFormat:@"dateCreated != NULL && blog=%@", blog];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    Comment *oldestComment = [[self.managedObjectContext executeFetchRequest:request error:nil] firstObject];
    return oldestComment;
}

- (void)loadMoreCommentsForBlog:(Blog *)blog
                        success:(void (^)(BOOL hasMore))success
                        failure:(void (^)(NSError *))failure
{
    [self loadMoreCommentsForBlog:blog withStatus:CommentStatusFilterAll success:success failure:failure];
}

- (void)loadMoreCommentsForBlog:(Blog *)blog
                     withStatus:(CommentStatusFilter)status
                        success:(void (^)(BOOL hasMore))success
                        failure:(void (^)(NSError *))failure
{
    NSManagedObjectID *blogID = blog.objectID;
    if (![[self class] startSyncingCommentsForBlog:blogID]){
        // We assume success because a sync is already running and it will change the comments
        if (success) {
            success(YES);
        }
    }

    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    
    // If the comment status is not specified, default to all.
    CommentStatusFilter commentStatus = status ?: CommentStatusFilterAll;
    options[@"status"] = [NSNumber numberWithInt:commentStatus];

    id<CommentServiceRemote> remote = [self remoteForBlog:blog];
    
    if ([remote isKindOfClass:[CommentServiceRemoteREST class]]) {
        Comment *oldestComment = [self oldestCommentForBlog:blog];
        if (oldestComment.dateCreated) {
            options[@"before"] = [oldestComment.dateCreated WordPressComJSONString];
            options[@"order"] = @"desc";
        }
    } else if ([remote isKindOfClass:[CommentServiceRemoteXMLRPC class]]) {
        NSUInteger commentCount = [blog.comments count];
        options[@"offset"] = @(commentCount);
    }
    
    [remote getCommentsWithMaximumCount:WPNumberOfCommentsToSync
                                options:options
                                success:^(NSArray *comments) {
        [self.managedObjectContext performBlock:^{
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
            if (!blog) {
                return;
            }

            [self mergeComments:comments forBlog:blog purgeExisting:NO completionHandler:^{
                [[self class] stopSyncingCommentsForBlog:blogID];
                if (success) {
                    success(comments.count > 1);
                }
            }];
        }];
        
    } failure:^(NSError *error) {
        [[self class] stopSyncingCommentsForBlog:blogID];
        if (failure) {
            [self.managedObjectContext performBlock:^{
                failure(error);
            }];
        }
    }];
}

// Upload comment
- (void)uploadComment:(Comment *)comment
              success:(void (^)(void))success
              failure:(void (^)(NSError *error))failure
{
    id<CommentServiceRemote> remote = [self remoteForComment:comment];
    RemoteComment *remoteComment = [self remoteCommentWithComment:comment];

    NSManagedObjectID *commentObjectID = comment.objectID;
    void (^successBlock)(RemoteComment *comment) = ^(RemoteComment *comment) {
        [self.managedObjectContext performBlock:^{
            Comment *commentInContext = (Comment *)[self.managedObjectContext existingObjectWithID:commentObjectID error:nil];
            if (commentInContext) {
                [self updateComment:commentInContext withRemoteComment:comment];
            }
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            if (success) {
                success();
            }
        }];
    };

    if (comment.commentID != 0) {
        [remote updateComment:remoteComment
                      success:successBlock
                      failure:failure];
    } else {
        [remote createComment:remoteComment
                      success:successBlock
                      failure:failure];
    }
}

// Approve
- (void)approveComment:(Comment *)comment
               success:(void (^)(void))success
               failure:(void (^)(NSError *error))failure
{
    [self moderateComment:comment
               withStatus:CommentStatusTypeApproved
                  success:success
                  failure:failure];
}

// Unapprove
- (void)unapproveComment:(Comment *)comment
                 success:(void (^)(void))success
                 failure:(void (^)(NSError *error))failure
{
    [self moderateComment:comment
               withStatus:CommentStatusTypePending
                  success:success
                  failure:failure];
}

// Spam
- (void)spamComment:(Comment *)comment
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure
{
    
    // If the Comment is not permanently deleted, don't remove it from the local cache as it can still be displayed.
    if (!comment.deleteWillBePermanent) {
        [self moderateComment:comment
                   withStatus:CommentStatusTypeSpam
                      success:success
                      failure:failure];
        
        return;
    }

    NSManagedObjectID *commentID = comment.objectID;
    
    [self moderateComment:comment
               withStatus:CommentStatusTypeSpam
                  success:^{
        Comment *commentInContext = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
        [self.managedObjectContext deleteObject:commentInContext];
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        if (success) {
            success();
        }
    } failure: failure];
    
    
}

// Trash comment
- (void)trashComment:(Comment *)comment
                 success:(void (^)(void))success
                 failure:(void (^)(NSError *error))failure
{
    [self moderateComment:comment
               withStatus:CommentStatusTypeUnapproved
                  success:success
                  failure:failure];
}

// Delete comment
- (void)deleteComment:(Comment *)comment
              success:(void (^)(void))success
              failure:(void (^)(NSError *error))failure
{
    // If this comment is local only, just delete. No need to query the endpoint or do any other work.
    if (comment.commentID == 0) {
        [self.managedObjectContext deleteObject:comment];
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        if (success) {
            success();
        }
        return;
    }

    RemoteComment *remoteComment = [self remoteCommentWithComment:comment];
    id<CommentServiceRemote> remote = [self remoteForBlog:comment.blog];
    
    // If the Comment is not permanently deleted, don't remove it from the local cache as it can still be displayed.
    if (!comment.deleteWillBePermanent) {
        [remote trashComment:remoteComment success:success failure:failure];
        return;
    }

    // For the best user experience we want to optimistically delete the comment.
    // However, if there is an error we need to restore it.
    NSManagedObjectID *blogObjID = comment.blog.objectID;
    NSManagedObjectContext *context = self.managedObjectContext;

    [context deleteObject:comment];
    [[ContextManager sharedInstance] saveContext:context withCompletionBlock:^{
        [remote trashComment:remoteComment success:success failure:^(NSError *error) {
            // Failure.  Restore the comment.
            Blog *blog = (Blog *)[context objectWithID:blogObjID];
            if (!blog) {
                if (failure) {
                    failure(error);
                }
                return;
            }

            Comment *comment = [self createCommentForBlog:blog];
            [self updateComment:comment withRemoteComment:remoteComment];
            [[ContextManager sharedInstance] saveContext:context withCompletionBlock:^{
                if (failure) {
                    failure(error);
                }
            }];
        }];
    }];
}

#pragma mark - Post-centric methods

- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                                   page:(NSUInteger)page
                                success:(void (^)(BOOL hasMore, NSNumber *totalComments))success
                                failure:(void (^)(NSError *error))failure
{
    [self syncHierarchicalCommentsForPost:post
                                     page:page
                         topLevelComments:WPTopLevelHierarchicalCommentsPerPage
                                  success:success
                                  failure:failure];
}

- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                       topLevelComments:(NSUInteger)number
                                success:(void (^)(BOOL hasMore, NSNumber *totalComments))success
                                failure:(void (^)(NSError *error))failure
{
    [self syncHierarchicalCommentsForPost:post
                                     page:1
                         topLevelComments:number
                                  success:success
                                  failure:failure];
}

- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                                   page:(NSUInteger)page
                       topLevelComments:(NSUInteger)number
                                success:(void (^)(BOOL hasMore, NSNumber *totalComments))success
                                failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *postObjectID = post.objectID;
    NSNumber *siteID = post.siteID;
    NSNumber *postID = post.postID;
    
    NSUInteger commentsPerPage = number ?: WPTopLevelHierarchicalCommentsPerPage;
    NSUInteger pageNumber = page ?: 1;
    
    [self.managedObjectContext performBlock:^{
        CommentServiceRemoteREST *service = [self restRemoteForSite:siteID];
        [service syncHierarchicalCommentsForPost:postID
                                            page:pageNumber
                                          number:commentsPerPage
                                         success:^(NSArray *comments, NSNumber *totalComments) {
                                             [self.managedObjectContext performBlock:^{
                                                 NSError *error;
                                                 ReaderPost *aPost = (ReaderPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:&error];
                                                 if (!aPost) {
                                                     if (failure) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             failure(error);
                                                         });
                                                     }
                                                     return;
                                                 }

                                                 [self mergeHierarchicalComments:comments forPage:page forPost:aPost onComplete:^(BOOL includesNewComments) {
                                                     if (!success) {
                                                         return;
                                                     }

                                                     [self.managedObjectContext performBlock:^{
                                                         // There are no more comments when:
                                                         // - There are fewer top level comments in the results than requested
                                                         // - Page > 1, the number of top level comments matches those requested, but there are no new comments
                                                         // We check this way because the API can return the last page of results instead
                                                         // of returning zero results when the requested page is the last + 1.
                                                         NSArray *parents = [self topLevelCommentsForPage:page forPost:aPost];
                                                         BOOL hasMore = YES;
                                                         if (([parents count] < WPTopLevelHierarchicalCommentsPerPage) || (page > 1 && !includesNewComments)) {
                                                             hasMore = NO;
                                                         }

                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             success(hasMore, totalComments);
                                                         });
                                                     }];
                                                 }];
                                             }];
                                         } failure:^(NSError *error) {
                                             [self.managedObjectContext performBlock:^{
                                                 if (failure) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         failure(error);
                                                     });
                                                 }
                                             }];
                                         }];
    }];
}

- (NSInteger)numberOfHierarchicalPagesSyncedforPost:(ReaderPost *)post
{
    NSSet *topComments = [post.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"parentID = 0"]];
    CGFloat page = [topComments count] / WPTopLevelHierarchicalCommentsPerPage;
    return (NSInteger)page;
}

#pragma mark - REST Helpers

- (NSString *)sanitizeCommentContent:(NSString *)string isPrivateSite:(BOOL)isPrivateSite
{
    NSString *content = string;
    content = [RichContentFormatter removeTrailingBreakTags:content];
    content = [RichContentFormatter formatContentString:content isPrivateSite:isPrivateSite];
    return content;
}

// Edition
- (void)updateCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    content:(NSString *)content
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote updateCommentWithID:commentID
                        content:content
                        success:success
                        failure:failure];
}

// Replies
- (void)replyToPost:(ReaderPost *)post
            content:(NSString *)content
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure
{
    // Create and optimistically save a comment, based on the current wpcom acct
    // post and content provided.
    Comment *comment = [self createHierarchicalCommentWithContent:content withParent:nil postID:post.postID siteID:post.siteID];
    BOOL isPrivateSite = post.isPrivate;
    
    // This fixes an issue where the comment may not appear for some posts after a successful posting
    // More information: https://github.com/wordpress-mobile/WordPress-iOS/issues/13259
    comment.post = post;

    NSManagedObjectID *commentID = comment.objectID;
    void (^successBlock)(RemoteComment *remoteComment) = ^void(RemoteComment *remoteComment) {
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
            if (!comment) {
                return;
            }

            remoteComment.content = [self sanitizeCommentContent:remoteComment.content isPrivateSite:isPrivateSite];

            // Update and save the comment
            [self updateCommentAndSave:comment withRemoteComment:remoteComment];
            if (success) {
                success();
            }
        }];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
            if (!comment) {
                return;
            }
            // Remove the optimistically saved comment.
            [self deleteComment:comment success:nil failure:nil];
            if (failure) {
                failure(error);
            }
        }];
    };

    CommentServiceRemoteREST *remote = [self restRemoteForSite:post.siteID];
    [remote replyToPostWithID:post.postID
                      content:content
                      success:successBlock
                      failure:failureBlock];
}

- (void)replyToHierarchicalCommentWithID:(NSNumber *)commentID
                                  post:(ReaderPost *)post
                                 content:(NSString *)content
                                 success:(void (^)(void))success
                                 failure:(void (^)(NSError *error))failure
{
    // Create and optimistically save a comment, based on the current wpcom acct
    // post and content provided.
    Comment *comment = [self createHierarchicalCommentWithContent:content withParent:commentID postID:post.postID siteID:post.siteID];
    BOOL isPrivateSite = post.isPrivate;
    
    // This fixes an issue where the comment may not appear for some posts after a successful posting
    // More information: https://github.com/wordpress-mobile/WordPress-iOS/issues/13259
    comment.post = post;

    NSManagedObjectID *commentObjectID = comment.objectID;
    void (^successBlock)(RemoteComment *remoteComment) = ^void(RemoteComment *remoteComment) {
        // Update and save the comment
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentObjectID error:nil];
            if (!comment) {
                return;
            }

            remoteComment.content = [self sanitizeCommentContent:remoteComment.content isPrivateSite:isPrivateSite];

            [self updateCommentAndSave:comment withRemoteComment:remoteComment];
            if (success) {
                success();
            }
        }];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentObjectID error:nil];
            if (!comment) {
                return;
            }
            // Remove the optimistically saved comment.
            ReaderPost *post = (ReaderPost *)comment.post;
            post.commentCount = @([post.commentCount integerValue] - 1);
            [self deleteComment:comment success:nil failure:nil];
            if (failure) {
                failure(error);
            }
        }];
    };

    CommentServiceRemoteREST *remote = [self restRemoteForSite:post.siteID];
    [remote replyToCommentWithID:commentID
                         content:content
                         success:successBlock
                         failure:failureBlock];
}

- (void)replyToCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     content:(NSString *)content
                     success:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote replyToCommentWithID:commentID
                         content:content
                         success:^(RemoteComment *comment){
                             if (success){
                                 success();
                             }
                         }
                         failure:failure];
}


// Likes
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote likeCommentWithID:commentID
                      success:success
                      failure:failure];
}

- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote unlikeCommentWithID:commentID
                        success:success
                        failure:failure];
}

// Moderation
- (void)approveCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     success:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote moderateCommentWithID:commentID
                           status:@"approved"
                          success:success
                          failure:failure];
}

- (void)unapproveCommentWithID:(NSNumber *)commentID
                        siteID:(NSNumber *)siteID
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote moderateCommentWithID:commentID
                           status:@"unapproved"
                          success:success
                          failure:failure];
}

- (void)spamCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote moderateCommentWithID:commentID
                           status:[Comment descriptionFor:CommentStatusTypeSpam]
                          success:success
                          failure:failure];
}

- (void)deleteCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote trashCommentWithID:commentID
                       success:success
                       failure:failure];
}

- (void)toggleLikeStatusForComment:(Comment *)comment
                            siteID:(NSNumber *)siteID
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *error))failure
{
    // toggle the like status and change the like count and save it
    comment.isLiked = !comment.isLiked;
    comment.likeCount = comment.likeCount + (comment.isLiked ? 1 : -1);

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    __weak __typeof(self) weakSelf = self;
    NSManagedObjectID *commentObjectID = comment.objectID;

    // This block will reverse the like/unlike action
    void (^failureBlock)(NSError *) = ^(NSError *error) {
        Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentObjectID error:nil];
        if (!comment) {
            return;
        }
        DDLogError(@"Error while %@ comment: %@", comment.isLiked ? @"liking" : @"unliking", error);

        comment.isLiked = !comment.isLiked;
        comment.likeCount = comment.likeCount + (comment.isLiked ? 1 : -1);

        [[ContextManager sharedInstance] saveContext:weakSelf.managedObjectContext];

        if (failure) {
            failure(error);
        }
    };

    NSNumber *commentID = [NSNumber numberWithInt:comment.commentID];

    if (comment.isLiked) {
        [self likeCommentWithID:commentID siteID:siteID success:success failure:failureBlock];
    }
    else {
        [self unlikeCommentWithID:commentID siteID:siteID success:success failure:failureBlock];
    }
}


#pragma mark - Private methods

// Deletes orphaned comments. Does not save context.
- (void)deleteUnownedComments
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Comment class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = NULL && blog = NULL"];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching orphaned comments: %@", error);
    }
    for (Comment *comment in results) {
        [self.managedObjectContext deleteObject:comment];
    }
}




#pragma mark - Blog centric methods
// Generic moderation
- (void)moderateComment:(Comment *)comment
             withStatus:(CommentStatusType)status
                success:(void (^)(void))success
                failure:(void (^)(NSError *error))failure
{
    NSString *currentStatus = [Comment descriptionFor:status];
    NSString *prevStatus = comment.status;

    if ([prevStatus isEqualToString:currentStatus]) {
        if (success) {
            success();
        }
        return;
    }

    comment.status = currentStatus;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    id <CommentServiceRemote> remote = [self remoteForComment:comment];
    RemoteComment *remoteComment = [self remoteCommentWithComment:comment];
    NSManagedObjectID *commentID = comment.objectID;
    [remote moderateComment:remoteComment
                    success:^(RemoteComment *comment) {
                        if (success) {
                            success();
                        }
                    } failure:^(NSError *error) {
                        DDLogError(@"Error moderating comment: %@", error);
                        [self.managedObjectContext performBlock:^{
                            // Note: The comment might have been deleted at this point
                            Comment *commentInContext = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
                            if (commentInContext) {
                                commentInContext.status = prevStatus;
                                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                            }

                            if (failure) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    failure(error);
                                });
                            }
                        }];
                    }];
}

- (void)mergeComments:(NSArray *)comments
              forBlog:(Blog *)blog
        purgeExisting:(BOOL)purgeExisting
    completionHandler:(void (^)(void))completion
{
    NSMutableArray *commentsToKeep = [NSMutableArray array];
    for (RemoteComment *remoteComment in comments) {
        Comment *comment = [self findCommentWithID:remoteComment.commentID inBlog:blog];
        if (!comment) {
            comment = [self createCommentForBlog:blog];
        }
        [self updateComment:comment withRemoteComment:remoteComment];
        [commentsToKeep addObject:comment];
    }

    if (purgeExisting) {
        NSSet *existingComments = blog.comments;
        if (existingComments.count > 0) {
            for (Comment *comment in existingComments) {
                // Don't delete unpublished comments
                if (![commentsToKeep containsObject:comment] && comment.commentID != 0) {
                    DDLogInfo(@"Deleting Comment: %@", comment);
                    [self.managedObjectContext deleteObject:comment];
                }
            }
        }
    }

    [self deleteUnownedComments];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    }];
}

- (Comment *)findCommentWithID:(NSNumber *)commentID inBlog:(Blog *)blog
{
    NSSet *comments = [blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentID]];
    return [comments anyObject];
}

#pragma mark - Post centric methods

- (NSMutableArray *)ancestorsForCommentWithParentID:(NSNumber *)parentID andCurrentAncestors:(NSArray *)currentAncestors
{
    NSMutableArray *ancestors = [currentAncestors mutableCopy];

    // Calculate hierarchy and depth.
    if (parentID.intValue != 0) {
        if ([ancestors containsObject:parentID]) {
            NSUInteger index = [ancestors indexOfObject:parentID] + 1;
            NSArray *subarray = [ancestors subarrayWithRange:NSMakeRange(0, index)];
            [ancestors removeAllObjects];
            [ancestors addObjectsFromArray:subarray];
        } else {
            [ancestors addObject:parentID];
        }
    } else {
        [ancestors removeAllObjects];
    }
    return ancestors;
}

- (NSString *)hierarchyFromAncestors:(NSArray *)ancestors andCommentID:(NSNumber *)commentID
{
    NSArray *arr = [ancestors arrayByAddingObject:commentID];
    arr = [self formatHierarchyElements:arr];
    return [arr componentsJoinedByString:@"."];
}

- (NSArray *)formatHierarchyElements:(NSArray *)hierarchy
{
    NSMutableArray *arr = [NSMutableArray array];
    for (NSNumber *commentID in hierarchy) {
        [arr addObject:[self formattedHierarchyElement:commentID]];
    }
    return arr;
}

- (NSString *)formattedHierarchyElement:(NSNumber *)commentID
{
    return [NSString stringWithFormat:@"%010u", [commentID integerValue]];
}

- (Comment *)createHierarchicalCommentWithContent:(NSString *)content withParent:(NSNumber *)parentID postID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    // Fetch the relevant ReaderPost
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"postID = %@ AND siteID = %@", postID, siteID];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching post with id %@ and site %@. %@", postID, siteID, error);
        return nil;
    }

    ReaderPost *post = [results firstObject];
    if (!post) {
        return nil;
    }

    // (Insert a new comment into core data. Check for its existance first for paranoia sake.
    // In theory a sync could include a newly created comment before the request that created it returned.
    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class]) inManagedObjectContext:self.managedObjectContext];

    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *account = [service defaultWordPressComAccount];
    comment.author = account.username;
    comment.authorID = [account.userID intValue];
    comment.content = content;
    comment.dateCreated = [NSDate date];
    comment.parentID = [parentID intValue];
    comment.postID = [postID intValue];
    comment.postTitle = post.postTitle;
    comment.status = [Comment descriptionFor:CommentStatusTypeDraft];
    comment.post = post;

    // Increment the post's comment count. 
    post.commentCount = @([post.commentCount integerValue] + 1);

    // Find its parent comment (if it exists)
    Comment *parentComment;
    if (parentID.intValue != 0) {
        parentComment = [self findCommentWithID:parentID fromPost:post];
    }

    // Update depth and hierarchy
    [self setHierarchyAndDepthOnComment:comment withParentComment:parentComment];

    [self.managedObjectContext obtainPermanentIDsForObjects:@[comment] error:&error];
    if (error) {
        DDLogError(@"%@ error obtaining permanent ID for a hierarchical comment %@: %@", NSStringFromSelector(_cmd), comment, error);
    }
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    return comment;
}

- (void)setHierarchyAndDepthOnComment:(Comment *)comment withParentComment:(Comment *)parentComment
{
    // Update depth and hierarchy
    NSNumber *commentID = [NSNumber numberWithInt:comment.commentID];

    if (commentID != 0) {
        // A new comment will have a 0 commentID. If 0 is used when formatting the hierarchy,
        // the comment will preceed any other comment in its level of the hierarchy.
        // Instead we'll pass a number so large as to ensure the comment will appear last in a list.
        commentID = @9999999;
    }

    if (parentComment) {
        comment.hierarchy = [NSString stringWithFormat:@"%@.%@", parentComment.hierarchy, [self formattedHierarchyElement:commentID]];
        comment.depth = parentComment.depth + 1;
    } else {
        comment.hierarchy = [self formattedHierarchyElement:commentID];
        comment.depth = 0;
    }

    [self.managedObjectContext performBlock:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)updateCommentAndSave:(Comment *)comment withRemoteComment:(RemoteComment *)remoteComment
{
    [self updateComment:comment withRemoteComment:remoteComment];
    // Find its parent comment (if it exists)
    Comment *parentComment;
    if (comment.parentID != 0) {
        NSNumber *parentID = [NSNumber numberWithInt:comment.parentID];
        parentComment = [self findCommentWithID:parentID fromPost:(ReaderPost *)comment.post];
    }

    // Update depth and hierarchy
    [self setHierarchyAndDepthOnComment:comment withParentComment:parentComment];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)mergeHierarchicalComments:(NSArray *)comments forPage:(NSUInteger)page forPost:(ReaderPost *)post onComplete:(void (^)(BOOL includesNewComments))onComplete
{
    if (![comments count]) {
        onComplete(NO);
        return;
    }

    NSMutableArray *ancestors = [NSMutableArray array];
    NSMutableArray *commentsToKeep = [NSMutableArray array];
    NSString *entityName = NSStringFromClass([Comment class]);
    NSUInteger newCommentCount = 0;

    for (RemoteComment *remoteComment in comments) {
        Comment *comment = [self findCommentWithID:remoteComment.commentID fromPost:post];
        if (!comment) {
            newCommentCount++;
            comment = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        }

        [self updateComment:comment withRemoteComment:remoteComment];

        // Calculate hierarchy and depth.
        ancestors = [self ancestorsForCommentWithParentID:[NSNumber numberWithInt:comment.parentID] andCurrentAncestors:ancestors];
        comment.hierarchy = [self hierarchyFromAncestors:ancestors andCommentID:[NSNumber numberWithInt:comment.commentID]];
        comment.depth = [ancestors count];
        comment.post = post;
        comment.content = [self sanitizeCommentContent:comment.content isPrivateSite:post.isPrivate];
        [commentsToKeep addObject:comment];
    }

    // Remove deleted comments
    // When merging the first fetched page of comments, clear out anything that was previously
    // cached and missing from the comments just synced. This provides for a clean slate and
    // helps avoid certain cases where some pages might not be resynced, creating gaps in the content.
    if (page == 1) {
        [self deleteCommentsMissingFromHierarchicalComments:commentsToKeep forPost:post];
        [self deleteUnownedComments];
    }

    // Make sure the post's comment count is at least the number of comments merged.
    if ([post.commentCount integerValue] < [commentsToKeep count]) {
        post.commentCount = @([commentsToKeep count]);
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
        onComplete(newCommentCount > 0);
    }];
}

// Does not save context
- (void)deleteCommentsMissingFromHierarchicalComments:(NSArray *)commentsToKeep forPost:(ReaderPost *)post
{
    for (Comment *comment in post.comments) {
        if (![commentsToKeep containsObject:comment]) {
            [self.managedObjectContext deleteObject:comment];
        }
    }
}

- (NSArray *)topLevelCommentsForPage:(NSUInteger)page forPost:(ReaderPost *)post
{
    NSString *entityName = NSStringFromClass([Comment class]);

    // Retrieve the starting and ending comments for the specified page.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@ AND parentID = 0", post];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"hierarchy" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    [fetchRequest setFetchLimit:WPTopLevelHierarchicalCommentsPerPage];
    NSUInteger offset = WPTopLevelHierarchicalCommentsPerPage * (page - 1);
    [fetchRequest setFetchOffset:offset];

    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching top level comments for page %i : %@", page, error);
    }
    return fetchedObjects;
}

- (NSArray *)topLevelComments:(NSUInteger)number forPost:(ReaderPost *)post
{
    NSArray *comments = [self topLevelCommentsForPage:1 forPost:post];
    NSInteger count = MIN(comments.count, number);
    return [comments subarrayWithRange:NSMakeRange(0, count)];
}

- (Comment *)firstCommentForPage:(NSUInteger)page forPost:(ReaderPost *)post
{
    NSArray *comments = [self topLevelCommentsForPage:page forPost:post];
    return [comments firstObject];
}

- (Comment *)lastCommentForPage:(NSUInteger)page forPost:(ReaderPost *)post
{
    NSArray *comments = [self topLevelCommentsForPage:page forPost:post];
    Comment *lastParentComment = [comments lastObject];

    NSString *entityName = NSStringFromClass([Comment class]);
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSString *wildCard = [NSString stringWithFormat:@"%@*", lastParentComment.hierarchy];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@ AND hierarchy LIKE %@", post, wildCard];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"hierarchy" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching last comment for page %i : %@", page, error);
    }
    return [fetchedObjects lastObject];
}

- (Comment *)findCommentWithID:(NSNumber *)commentID fromPost:(ReaderPost *)post
{
    NSSet *comments = [post.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentID]];
    return [comments anyObject];
}


#pragma mark - Transformations

- (void)updateComment:(Comment *)comment withRemoteComment:(RemoteComment *)remoteComment
{
    comment.commentID = [remoteComment.commentID intValue];
    comment.authorID = [remoteComment.authorID intValue];
    comment.author = remoteComment.author;
    comment.author_email = remoteComment.authorEmail;
    comment.author_url = remoteComment.authorUrl;
    comment.authorAvatarURL = remoteComment.authorAvatarURL;
    comment.author_ip = remoteComment.authorIP;
    comment.content = remoteComment.content;
    comment.rawContent = remoteComment.rawContent;
    comment.dateCreated = remoteComment.date;
    comment.link = remoteComment.link;
    comment.parentID = [remoteComment.parentID intValue];
    comment.postID = [remoteComment.postID intValue];
    comment.postTitle = remoteComment.postTitle;
    comment.status = remoteComment.status;
    comment.type = remoteComment.type;
    comment.isLiked = remoteComment.isLiked;
    comment.likeCount = [remoteComment.likeCount intValue];
    comment.canModerate = remoteComment.canModerate;

    // if the post for the comment is not set, check if that post is already stored and associate them
    if (!comment.post) {
        PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
        comment.post = [postService findPostWithID:[NSNumber numberWithInt:comment.postID] inBlog:comment.blog];
    }
}

- (RemoteComment *)remoteCommentWithComment:(Comment *)comment
{
    RemoteComment *remoteComment = [RemoteComment new];
    remoteComment.commentID = [NSNumber numberWithInt:comment.commentID];
    remoteComment.authorID = [NSNumber numberWithInt:comment.authorID];
    remoteComment.author = comment.author;
    remoteComment.authorEmail = comment.author_email;
    remoteComment.authorUrl = comment.author_url;
    remoteComment.authorAvatarURL = comment.authorAvatarURL;
    remoteComment.authorIP = comment.author_ip;
    remoteComment.content = comment.content;
    remoteComment.date = comment.dateCreated;
    remoteComment.link = comment.link;
    remoteComment.parentID = [NSNumber numberWithInt:comment.parentID];
    remoteComment.postID = [NSNumber numberWithInt:comment.postID];
    remoteComment.postTitle = comment.postTitle;
    remoteComment.status = comment.status;
    remoteComment.type = comment.type;
    remoteComment.isLiked = comment.isLiked;
    remoteComment.likeCount = [NSNumber numberWithInt:comment.likeCount];
    remoteComment.canModerate = comment.canModerate;
    return remoteComment;
}


#pragma mark - Remotes

- (id<CommentServiceRemote>)remoteForComment:(Comment *)comment
{
    // If the comment is fetched through the Reader API, the blog will always be nil.
    // Try to find the Blog locally first, as it should exist if the user has a role on the site.
    if (comment.post && [comment.post isKindOfClass:[ReaderPost class]]) {
        ReaderPost *readerPost = (ReaderPost *)comment.post;
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
        return [self remoteForBlog:[blogService blogByHostname:readerPost.blogURL]];
    }

    return [self remoteForBlog:comment.blog];
}

- (id<CommentServiceRemote>)remoteForBlog:(Blog *)blog
{
    return [self.remoteFactory remoteWithBlog:blog];
}

- (CommentServiceRemoteREST *)restRemoteForSite:(NSNumber *)siteID
{
    return [self.remoteFactory restRemoteWithSiteID:siteID api:[self apiForRESTRequest]];
}

/**
 Get the api to use for the request.
 */
- (WordPressComRestApi *)apiForRESTRequest
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WordPressComRestApi *api = [defaultAccount wordPressComRestApi];
    //Sergio Estevao: Do we really want to do this? If the call going to be valid if no credential is available?
    if (![api hasCredentials]) {
        api = [WordPressComRestApi defaultApiWithOAuthToken:nil
                                                  userAgent:[WPUserAgent wordPressUserAgent]
                                                  localeKey:[WordPressComRestApi LocaleKeyDefault]];
    }
    return api;
}

@end
