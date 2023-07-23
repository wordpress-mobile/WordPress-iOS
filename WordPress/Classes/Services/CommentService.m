#import "CommentService.h"
#import "AccountService.h"
#import "Blog.h"
#import "CoreDataStack.h"
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

- (instancetype)initWithCoreDataStack:(id<CoreDataStack>)coreDataStack
{
    return [self initWithCoreDataStack:coreDataStack commentServiceRemoteFactory:[CommentServiceRemoteFactory new]];
}

- (instancetype)initWithCoreDataStack:(id<CoreDataStack>)coreDataStack
          commentServiceRemoteFactory:(CommentServiceRemoteFactory *)remoteFactory
{
    self = [super initWithCoreDataStack:coreDataStack];
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

#pragma mark Public methods

#pragma mark Blog-centric methods

// Create comment
- (Comment *)createCommentForBlog:(Blog *)blog
{
    NSParameterAssert(blog.managedObjectContext != nil);

    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class])
                                                     inManagedObjectContext:blog.managedObjectContext];
    comment.dateCreated = [NSDate new];
    comment.blog = blog;
    return comment;
}

// Create reply
- (void)createReplyForComment:(Comment *)comment content:(NSString *)content completion:(void (^)(Comment *reply))completion
{
    NSManagedObjectID *parentCommentID = comment.objectID;
    NSManagedObjectID * __block replyID = nil;
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        Comment *comment = [context existingObjectWithID:parentCommentID error:nil];
        Comment *reply = [self createCommentForBlog:comment.blog];
        reply.postID = comment.postID;
        reply.post = comment.post;
        reply.parentID = comment.commentID;
        reply.status = [Comment descriptionFor:CommentStatusTypeApproved];
        reply.content = content;
        [context obtainPermanentIDsForObjects:@[reply] error:nil];
        replyID = reply.objectID;
    } completion:^{
        if (completion) {
            completion([self.coreDataStack.mainContext existingObjectWithID:replyID error:nil]);
        }
    } onQueue:dispatch_get_main_queue()];
}

// Sync comments
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
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Blog *blog = [context existingObjectWithID:blogID error:nil];
            if (!blog) {
                return;
            }

            NSArray *fetchedComments = comments;
            if (filterUnreplied) {
                NSString *author = @"";
                if (blog.account) {
                    // See if there is a linked Jetpack user that we should use.
                    BlogAuthor *blogAuthor = [blog getAuthorWithLinkedID:blog.account.userID];
                    author = (blogAuthor) ? blogAuthor.email : blog.account.email;
                } else {
                    BlogAuthor *blogAuthor = [blog getAuthorWithId:blog.userID];
                    author = (blogAuthor) ? blogAuthor.email : author;
                }
                fetchedComments = [self filterUnrepliedComments:comments forAuthor:author];
            }
            [self mergeComments:fetchedComments forBlog:blog purgeExisting:YES];
            blog.lastCommentsSync = [NSDate date];
        } completion:^{
            [[self class] stopSyncingCommentsForBlog:blogID];

            if (success) {
                // Note:
                // We'll assume that if the requested page size couldn't be filled, there are no
                // more comments left to retrieve.  However, for unreplied comments, we only fetch the first page (for now).
                BOOL hasMore = comments.count >= WPNumberOfCommentsToSync && !filterUnreplied;
                success(hasMore);
            }
        } onQueue:dispatch_get_main_queue()];
    } failure:^(NSError *error) {
        [[self class] stopSyncingCommentsForBlog:blogID];

        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
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
    NSParameterAssert(blog.managedObjectContext != nil);

    NSString *entityName = NSStringFromClass([Comment class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [NSPredicate predicateWithFormat:@"dateCreated != NULL && blog=%@", blog];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];

    Comment * __block oldestComment = nil;
    [blog.managedObjectContext performBlockAndWait:^{
        oldestComment = [[blog.managedObjectContext executeFetchRequest:request error:nil] firstObject];
    }];
    return oldestComment;
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
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Blog *blog = [context existingObjectWithID:blogID error:nil];
            if (!blog) {
                return;
            }
            [self mergeComments:comments forBlog:blog purgeExisting:NO];
        } completion:^{
            [[self class] stopSyncingCommentsForBlog:blogID];
            if (success) {
                success(comments.count > 1);
            }
        } onQueue:dispatch_get_main_queue()];
    } failure:^(NSError *error) {
        [[self class] stopSyncingCommentsForBlog:blogID];
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)loadCommentWithID:(NSNumber *)commentID
                  forBlog:(Blog *)blog
                  success:(void (^)(Comment *comment))success
                  failure:(void (^)(NSError *))failure {

    NSManagedObjectID *blogID = blog.objectID;
    id<CommentServiceRemote> remote = [self remoteForBlog:blog];

    [remote getCommentWithID:commentID
                     success:^(RemoteComment *remoteComment) {
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Blog *blog = [context existingObjectWithID:blogID error:nil];
            if (!blog) {
                return;
            }

            Comment *comment = [blog commentWithID:remoteComment.commentID];
            if (!comment) {
                comment = [self createCommentForBlog:blog];
            }

            [self updateComment:comment withRemoteComment:remoteComment];
        } completion:^{
            if (success) {
                [self.coreDataStack.mainContext performBlock:^{
                    Blog *blog = [self.coreDataStack.mainContext existingObjectWithID:blogID error:nil];
                    success([blog commentWithID:remoteComment.commentID]);
                }];
            }
        } onQueue:dispatch_get_main_queue()];
    } failure:^(NSError *error) {
        DDLogError(@"Error loading comment for blog: %@", error);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)loadCommentWithID:(NSNumber *)commentID
                  forPost:(ReaderPost *)post
                  success:(void (^)(Comment *comment))success
                  failure:(void (^)(NSError *))failure {

    NSManagedObjectID *postID = post.objectID;
    CommentServiceRemoteREST *service = [self restRemoteForSite:post.siteID];

    [service getCommentWithID:commentID
                      success:^(RemoteComment *remoteComment) {
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            ReaderPost *post = [context existingObjectWithID:postID error:nil];
            if (!post) {
                return;
            }

            Comment *comment = [post commentWithID:remoteComment.commentID];

            if (!comment) {
                comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class]) inManagedObjectContext:context];
                comment.dateCreated = [NSDate new];
            }

            comment.post = post;
            [self updateComment:comment withRemoteComment:remoteComment];
        } completion:^{
            if (success) {
                [self.coreDataStack.mainContext performBlock:^{
                    ReaderPost *post = [self.coreDataStack.mainContext existingObjectWithID:postID error:nil];
                    success([post commentWithID:remoteComment.commentID]);
                }];
            }
        } onQueue:dispatch_get_main_queue()];
    } failure:^(NSError *error) {
        DDLogError(@"Error loading comment for post: %@", error);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
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
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Comment *commentInContext = [context existingObjectWithID:commentObjectID error:nil];
            if (commentInContext) {
                [self updateComment:commentInContext withRemoteComment:comment];
            }
        } completion:success onQueue:dispatch_get_main_queue()];
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
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Comment *commentInContext = [context existingObjectWithID:commentID error:nil];
            if (commentInContext != nil){
                [context deleteObject:commentInContext];
            }
        } completion:success onQueue:dispatch_get_main_queue()];
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
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Comment *commentInContext = [context existingObjectWithID:comment.objectID error:nil];
            if (commentInContext != nil) {
                [context deleteObject:commentInContext];
            }
        } completion:success onQueue:dispatch_get_main_queue()];
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
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        Comment *commentInContext = [context existingObjectWithID:comment.objectID error:nil];
        if (commentInContext != nil) {
            [context deleteObject:commentInContext];
        }
    } completion:^{
        [remote trashComment:remoteComment success:success failure:^(NSError *error) {
            // Failure.  Restore the comment.
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Blog *blog = [context objectWithID:blogObjID];
                if (!blog) {
                    return;
                }

                Comment *comment = [self createCommentForBlog:blog];
                [self updateComment:comment withRemoteComment:remoteComment];
            } completion:^{
                if (failure) {
                    failure(error);
                }
            } onQueue:dispatch_get_main_queue()];
        }];
    } onQueue:dispatch_get_main_queue()];
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

    CommentServiceRemoteREST *service = [self restRemoteForSite:siteID];
    [service syncHierarchicalCommentsForPost:postID
                                        page:pageNumber
                                      number:commentsPerPage
                                     success:^(NSArray *comments, NSNumber *totalComments) {
                                         BOOL __block includesNewComments = NO;
                                         [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                                             NSError *error;
                                             ReaderPost *aPost = [context existingObjectWithID:postObjectID error:&error];
                                             if (!aPost) {
                                                 if (failure) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         failure(error);
                                                     });
                                                 }
                                                 return;
                                             }

                                             includesNewComments = [self mergeHierarchicalComments:comments forPage:page forPost:aPost];
                                         } completion:^{
                                             if (!success) {
                                                 return;
                                             }

                                             [self.coreDataStack.mainContext performBlock:^{
                                                 NSError *error;
                                                 ReaderPost *aPost = [self.coreDataStack.mainContext existingObjectWithID:postObjectID error:&error];
                                                 if (!aPost) {
                                                     if (failure) {
                                                         failure(error);
                                                     }
                                                     return;
                                                 }

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

                                                 success(hasMore, totalComments);
                                             }];
                                         } onQueue:dispatch_get_main_queue()];
                                     } failure:^(NSError *error) {
                                         if (failure) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 failure(error);
                                             });
                                         }
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
    BOOL isPrivateSite = post.isPrivate;
    [self createHierarchicalCommentWithContent:content withParent:nil postObjectID:post.objectID siteID:post.siteID completion:^(NSManagedObjectID *commentID) {
        if (!commentID) {
            NSError *error = [NSError errorWithDomain:WKErrorDomain code:WKErrorUnknown userInfo:@{NSDebugDescriptionErrorKey: @"Failed to create a comment for a post"}];
            if (failure) {
                failure(error);
            }
            [WordPressAppDelegate logError:error];
            return;
        }
        void (^successBlock)(RemoteComment *remoteComment) = ^void(RemoteComment *remoteComment) {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Comment *comment = [context existingObjectWithID:commentID error:nil];
                if (!comment) {
                    return;
                }

                remoteComment.content = [self sanitizeCommentContent:remoteComment.content isPrivateSite:isPrivateSite];

                [self updateHierarchicalComment:comment withRemoteComment:remoteComment];
            } completion:success onQueue:dispatch_get_main_queue()];
        };

        void (^failureBlock)(NSError *error) = ^void(NSError *error) {
            // Remove the optimistically saved comment.
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Comment *commentInContext = [context existingObjectWithID:commentID error:nil];
                if (commentInContext != nil) {
                    [context deleteObject:commentInContext];
                }
            } completion:^{
                if (failure) {
                    failure(error);
                }
            } onQueue:dispatch_get_main_queue()];
        };

        CommentServiceRemoteREST *remote = [self restRemoteForSite:post.siteID];
        [remote replyToPostWithID:post.postID
                          content:content
                          success:successBlock
                          failure:failureBlock];
    }];
}

- (void)replyToHierarchicalCommentWithID:(NSNumber *)commentID
                                  post:(ReaderPost *)post
                                 content:(NSString *)content
                                 success:(void (^)(void))success
                                 failure:(void (^)(NSError *error))failure
{
    // Create and optimistically save a comment, based on the current wpcom acct
    // post and content provided.
    BOOL isPrivateSite = post.isPrivate;
    [self createHierarchicalCommentWithContent:content withParent:nil postObjectID:post.objectID siteID:post.siteID completion:^(NSManagedObjectID *commentObjectID) {
        if (!commentObjectID) {
            NSError *error = [NSError errorWithDomain:WKErrorDomain code:WKErrorUnknown userInfo:@{NSDebugDescriptionErrorKey: @"Failed to create a comment for a post"}];
            if (failure) {
                failure(error);
            }
            [WordPressAppDelegate logError:error];
            return;
        }
        void (^successBlock)(RemoteComment *remoteComment) = ^void(RemoteComment *remoteComment) {
            // Update and save the comment
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Comment *comment = [context existingObjectWithID:commentObjectID error:nil];
                if (!comment) {
                    return;
                }

                remoteComment.content = [self sanitizeCommentContent:remoteComment.content isPrivateSite:isPrivateSite];

                [self updateHierarchicalComment:comment withRemoteComment:remoteComment];
            } completion:success onQueue:dispatch_get_main_queue()];
        };

        void (^failureBlock)(NSError *error) = ^void(NSError *error) {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Comment *commentInContext = [context existingObjectWithID:commentObjectID error:nil];
                if (!commentInContext) {
                    return;
                }
                // Remove the optimistically saved comment.
                [context deleteObject:commentInContext];
                ReaderPost *post = (ReaderPost *)commentInContext.post;
                post.commentCount = @([post.commentCount integerValue] - 1);
            } completion:^{
                if (failure) {
                    failure(error);
                }
            } onQueue:dispatch_get_main_queue()];
        };

        CommentServiceRemoteREST *remote = [self restRemoteForSite:post.siteID];
        [remote replyToCommentWithID:commentID
                             content:content
                             success:successBlock
                             failure:failureBlock];
    }];
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
                         success:^(RemoteComment * __unused comment){
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
    NSManagedObjectID *commentObjectID = comment.objectID;
    BOOL isLikedOriginally = comment.isLiked;
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        // toggle the like status and change the like count and save it
        Comment *comment = [context existingObjectWithID:commentObjectID error:nil];
        comment.isLiked = !isLikedOriginally;
        comment.likeCount = comment.likeCount + (comment.isLiked ? 1 : -1);
    } completion:^{
        // This block will reverse the like/unlike action
        void (^failureBlock)(NSError *) = ^(NSError *error) {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Comment *comment = [context existingObjectWithID:commentObjectID error:nil];
                DDLogError(@"Error while %@ comment: %@", comment.isLiked ? @"liking" : @"unliking", error);

                comment.isLiked = isLikedOriginally;
                comment.likeCount = comment.likeCount + (comment.isLiked ? 1 : -1);
            } completion:^{
                if (failure) {
                    failure(error);
                }
            } onQueue:dispatch_get_main_queue()];
        };

        NSNumber *commentID = [NSNumber numberWithInt:comment.commentID];

        if (!isLikedOriginally) {
            [self likeCommentWithID:commentID siteID:siteID success:success failure:failureBlock];
        }
        else {
            [self unlikeCommentWithID:commentID siteID:siteID success:success failure:failureBlock];
        }
    } onQueue:dispatch_get_main_queue()];
}


#pragma mark - Private methods

// Deletes orphaned comments. Does not save context.
- (void)deleteUnownedCommentsInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Comment class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = NULL && blog = NULL"];

    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching orphaned comments: %@", error);
    }
    for (Comment *comment in results) {
        [context deleteObject:comment];
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

    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        Comment *commentInContext = [context existingObjectWithID:comment.objectID error:nil];
        commentInContext.status = currentStatus;
    }];

    comment.status = currentStatus;

    id <CommentServiceRemote> remote = [self remoteForComment:comment];
    RemoteComment *remoteComment = [self remoteCommentWithComment:comment];
    [remote moderateComment:remoteComment
                    success:^(RemoteComment * __unused comment) {
                        if (success) {
                            success();
                        }
                    } failure:^(NSError *error) {
                        DDLogError(@"Error moderating comment: %@", error);
                        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                            Comment *commentInContext = [context existingObjectWithID:comment.objectID error:nil];
                            commentInContext.status = prevStatus;
                        } completion:^{
                            if (failure) {
                                failure(error);
                            }
                        } onQueue:dispatch_get_main_queue()];
                    }];
}

- (void)mergeComments:(NSArray *)comments
              forBlog:(Blog *)blog
        purgeExisting:(BOOL)purgeExisting
{
    NSParameterAssert(blog.managedObjectContext != nil);

    NSMutableArray *commentsToKeep = [NSMutableArray array];
    for (RemoteComment *remoteComment in comments) {
        Comment *comment = [blog commentWithID:remoteComment.commentID];
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
                    [blog.managedObjectContext deleteObject:comment];
                }
            }
        }
    }

    [self deleteUnownedCommentsInContext:blog.managedObjectContext];
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

- (void)createHierarchicalCommentWithContent:(NSString *)content
                                  withParent:(NSNumber *)parentID
                                postObjectID:(NSManagedObjectID *)postObjectID
                                      siteID:(NSNumber *)siteID
                                  completion:(void (^)(NSManagedObjectID *commentID))completion
{
    NSManagedObjectID * __block objectID = nil;
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderPost *post = [context existingObjectWithID:postObjectID error:nil];
        Comment *comment = [self createHierarchicalCommentWithContent:content withParent:parentID postID:post.postID siteID:siteID inContext:context];
        objectID = comment.objectID;
        // This fixes an issue where the comment may not appear for some posts after a successful posting
        // More information: https://github.com/wordpress-mobile/WordPress-iOS/issues/13259
        comment.post = post;
    } completion:^{
        completion(objectID);
    } onQueue:dispatch_get_main_queue()];
}

- (Comment *)createHierarchicalCommentWithContent:(NSString *)content withParent:(NSNumber *)parentID postID:(NSNumber *)postID siteID:(NSNumber *)siteID inContext:(NSManagedObjectContext *)context
{
    // Fetch the relevant ReaderPost
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"postID = %@ AND siteID = %@", postID, siteID];
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
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
    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class]) inManagedObjectContext:context];

    WPAccount *account = [WPAccount lookupDefaultWordPressComAccountInContext:context];
    comment.author = [account username];
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
        parentComment = [post commentWithID:parentID];
    }

    // Update depth and hierarchy
    [self setHierarchyAndDepthOnComment:comment withParentComment:parentComment];

    [context obtainPermanentIDsForObjects:@[comment] error:&error];
    if (error) {
        DDLogError(@"%@ error obtaining permanent ID for a hierarchical comment %@: %@", NSStringFromSelector(_cmd), comment, error);
    }

    return comment;
}

- (void)setHierarchyAndDepthOnComment:(Comment *)comment withParentComment:(Comment *)parentComment
{
    NSParameterAssert(comment.managedObjectContext != nil);

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
}

- (void)updateHierarchicalComment:(Comment *)comment withRemoteComment:(RemoteComment *)remoteComment
{
    NSParameterAssert(comment.managedObjectContext != nil);

    [self updateComment:comment withRemoteComment:remoteComment];
    // Find its parent comment (if it exists)
    Comment *parentComment;
    if (comment.parentID != 0) {
        NSNumber *parentID = [NSNumber numberWithInt:comment.parentID];
        parentComment = [(ReaderPost *)comment.post commentWithID:parentID];
    }

    // Update depth and hierarchy
    [self setHierarchyAndDepthOnComment:comment withParentComment:parentComment];
}

- (BOOL)mergeHierarchicalComments:(NSArray *)comments forPage:(NSUInteger)page forPost:(ReaderPost *)post
{
    NSParameterAssert(post.managedObjectContext != nil);

    if (![comments count]) {
        return NO;
    }

    NSMutableSet<NSNumber *> *visibleCommentIds = [NSMutableSet new];
    NSMutableArray *ancestors = [NSMutableArray array];
    NSMutableArray *commentsToKeep = [NSMutableArray array];
    NSString *entityName = NSStringFromClass([Comment class]);
    NSUInteger newCommentCount = 0;

    for (RemoteComment *remoteComment in comments) {
        Comment *comment = [post commentWithID:remoteComment.commentID];
        if (!comment) {
            newCommentCount++;
            comment = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:post.managedObjectContext];
        }

        [self updateComment:comment withRemoteComment:remoteComment];

        // Calculate hierarchy and depth.
        ancestors = [self ancestorsForCommentWithParentID:[NSNumber numberWithInt:comment.parentID] andCurrentAncestors:ancestors];
        comment.hierarchy = [self hierarchyFromAncestors:ancestors andCommentID:[NSNumber numberWithInt:comment.commentID]];

        // Comments are shown on the thread when (1) it is approved, and (2) its ancestors are approved.
        // Having the comments sorted hierarchically ascending ensures that each comment's predecessors will be visited first.
        // Therefore, we only need to check if the comment and its direct parent are approved.
        // Ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/18081
        BOOL hasValidParent = comment.parentID > 0 && [visibleCommentIds containsObject:@(comment.parentID)];
        if ([comment isApproved] && ([comment isTopLevelComment] || hasValidParent)) {
            [visibleCommentIds addObject:@(comment.commentID)];
        }
        comment.visibleOnReader = [visibleCommentIds containsObject:@(comment.commentID)];

        comment.depth = ancestors.count;
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
        [self deleteUnownedCommentsInContext:post.managedObjectContext];
    }

    // Make sure the post's comment count is at least the number of comments merged.
    if ([post.commentCount integerValue] < [commentsToKeep count]) {
        post.commentCount = @([commentsToKeep count]);
    }

    return newCommentCount > 0;
}

// Does not save context
- (void)deleteCommentsMissingFromHierarchicalComments:(NSArray *)commentsToKeep forPost:(ReaderPost *)post
{
    for (Comment *comment in post.comments) {
        if (![commentsToKeep containsObject:comment]) {
            [post.managedObjectContext deleteObject:comment];
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
    NSArray *fetchedObjects = [post.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching top level comments for page %i : %@", page, error);
    }
    return fetchedObjects;
}

- (NSArray *)topLevelComments:(NSUInteger)number forPost:(ReaderPost *)post
{
    NSParameterAssert(post.managedObjectContext != nil);
    NSArray * __block commentsToReturn = nil;
    [post.managedObjectContext performBlockAndWait:^{
        NSArray *comments = [self topLevelCommentsForPage:1 forPost:post];
        NSInteger count = MIN(comments.count, number);
        commentsToReturn = [comments subarrayWithRange:NSMakeRange(0, count)];
    }];
    return commentsToReturn;
}

#pragma mark - Transformations

- (void)updateComment:(Comment *)comment withRemoteComment:(RemoteComment *)remoteComment
{
    NSParameterAssert(comment.managedObjectContext != nil);

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
        comment.post = [comment.blog lookupPostWithID:[NSNumber numberWithInt:comment.postID] inContext:comment.managedObjectContext];
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
    NSParameterAssert(comment.managedObjectContext != nil);

    // If the comment is fetched through the Reader API, the blog will always be nil.
    // Try to find the Blog locally first, as it should exist if the user has a role on the site.
    if (comment.post && [comment.post isKindOfClass:[ReaderPost class]]) {
        ReaderPost *readerPost = (ReaderPost *)comment.post;
        return [self remoteForBlog:[Blog lookupWithHostname:readerPost.blogURL inContext:comment.managedObjectContext]];
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
    WPAccount * __block defaultAccount = nil;
    [self.coreDataStack.mainContext performBlockAndWait:^{
        defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:self.coreDataStack.mainContext];
    }];

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
