#import "CommentServiceRemoteREST.h"
#import "WPKit-Swift.h"
#import "RemoteComment.h"
#import "RemoteUser.h"

@import NSObject_SafeExpectations;
@import WordPressShared;

@implementation CommentServiceRemoteREST

#pragma mark Public methods

#pragma mark - Blog-centric methods

- (void)getCommentsWithMaximumCount:(NSInteger)maximumComments
                            success:(void (^)(NSArray *comments))success
                            failure:(void (^)(NSError *error))failure
{
    [self getCommentsWithMaximumCount:maximumComments options:nil success:success failure:failure];
}

- (void)getCommentsWithMaximumCount:(NSInteger)maximumComments
                            options:(NSDictionary *)options
                            success:(void (^)(NSArray *posts))success
                            failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                 @"force": @"wpcom", // Force fetching data from shadow site on Jetpack sites
                                 @"number": @(maximumComments)
                                 }];

    if (options) {
        [parameters addEntriesFromDictionary:options];
    }
    
    NSNumber *statusFilter = [parameters numberForKey:@"status"];
    [parameters removeObjectForKey:@"status"];
    parameters[@"status"] = [self parameterForCommentStatus:statusFilter];

    [self.wordPressComRESTAPI get:requestUrl
                       parameters:parameters
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              if (success) {
                                  success([self remoteCommentsFromJSONArray:responseObject[@"comments"]]);
                              }
                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                              if (failure) {
                                  failure(error);
                              }
                          }];

}

- (NSString *)parameterForCommentStatus:(NSNumber *)status
{
    switch (status.intValue) {
        case CommentStatusFilterUnapproved:
            return @"unapproved";
            break;
        case CommentStatusFilterApproved:
            return @"approved";
            break;
        case CommentStatusFilterTrash:
            return @"trash";
            break;
        case CommentStatusFilterSpam:
            return @"spam";
            break;
        default:
            return @"all";
            break;
    }
}

- (void)getCommentWithID:(NSNumber *)commentID
                 success:(void (^)(RemoteComment *comment))success
                 failure:(void (^)(NSError * error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI get:requestUrl
                       parameters:nil
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        RemoteComment *comment = [self remoteCommentFromJSONDictionary:responseObject];
        if (success) {
            success(comment);
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)createComment:(RemoteComment *)comment
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *))failure
{
    NSString *path;
    if (comment.parentID) {
        path = [NSString stringWithFormat:@"sites/%@/comments/%@/replies/new", self.siteID, comment.parentID];
    } else {
        path = [NSString stringWithFormat:@"sites/%@/posts/%@/replies/new", self.siteID, comment.postID];
    }
    
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *parameters = @{
                                 @"content": comment.content,
                                 @"context": @"edit",
                                 };
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:parameters
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               // TODO: validate response
                               RemoteComment *comment = [self remoteCommentFromJSONDictionary:responseObject];
                               if (success) {
                                   success(comment);
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)updateComment:(RemoteComment *)comment
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, comment.commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *parameters = @{
        @"content": comment.content,
        @"author": comment.author,
        @"author_email": comment.authorEmail,
        @"author_url": comment.authorUrl,
        @"context": @"edit",
    };

    [self.wordPressComRESTAPI post:requestUrl
                        parameters:parameters
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               // TODO: validate response
                               RemoteComment *comment = [self remoteCommentFromJSONDictionary:responseObject];
                               if (success) {
                                   success(comment);
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)moderateComment:(RemoteComment *)comment
                success:(void (^)(RemoteComment *))success
                failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, comment.commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *parameters = @{
                                 @"status": [self remoteStatusWithStatus:comment.status],
                                 @"context": @"edit",
                                 };
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:parameters
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               // TODO: validate response
                               RemoteComment *comment = [self remoteCommentFromJSONDictionary:responseObject];
                               if (success) {
                                   success(comment);
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)trashComment:(RemoteComment *)comment
             success:(void (^)(void))success
             failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/delete", self.siteID, comment.commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:nil
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               if (success) {
                                   success();
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}


#pragma mark Post-centric methods

- (void)syncHierarchicalCommentsForPost:(NSNumber *)postID
                                   page:(NSUInteger)page
                                 number:(NSUInteger)number
                                success:(void (^)(NSArray *comments, NSNumber *found))success
                                failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/replies?order=ASC&hierarchical=1&page=%lu&number=%lu", self.siteID, postID, (unsigned long)page, (unsigned long)number];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    NSDictionary *parameters = @{
        @"force": @"wpcom" // Force fetching data from shadow site on Jetpack sites
    };
    [self.wordPressComRESTAPI get:requestUrl
                       parameters:parameters
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (success) {
            NSDictionary *dict = (NSDictionary *)responseObject;
            NSArray *comments = [self remoteCommentsFromJSONArray:[dict arrayForKey:@"comments"]];
            NSNumber *found = [responseObject numberForKey:@"found"] ?: @0;
            success(comments, found);
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Public Methods

- (void)updateCommentWithID:(NSNumber *)commentID
                    content:(NSString *)content
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *parameters = @{
        @"content": content,
        @"context": @"edit",
    };
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:parameters
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               if (success) {
                                   success();
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)replyToPostWithID:(NSNumber *)postID
                  content:(NSString *)content
                  success:(void (^)(RemoteComment *comment))success
                  failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/replies/new", self.siteID, postID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *parameters = @{@"content": content};
    
    [self.wordPressComRESTAPI post:requestUrl
        parameters:parameters
           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
               if (success) {
                   NSDictionary *commentDict = (NSDictionary *)responseObject;
                   RemoteComment *comment = [self remoteCommentFromJSONDictionary:commentDict];
                   success(comment);
               }
           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)replyToCommentWithID:(NSNumber *)commentID
                     content:(NSString *)content
                     success:(void (^)(RemoteComment *comment))success
                     failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/replies/new", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *parameters = @{
        @"content": content,
        @"context": @"edit",
    };
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:parameters
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               if (success) {
                                   NSDictionary *commentDict = (NSDictionary *)responseObject;
                                   RemoteComment *comment = [self remoteCommentFromJSONDictionary:commentDict];
                                   success(comment);
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)moderateCommentWithID:(NSNumber *)commentID
                       status:(NSString *)status
                      success:(void (^)(void))success
                      failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *parameters = @{
        @"status"   : status,
        @"context"  : @"edit",
    };
    
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:parameters
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               if (success) {
                                   success();
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)trashCommentWithID:(NSNumber *)commentID
                   success:(void (^)(void))success
                   failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/delete", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:nil
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               if (success) {
                                   success();
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)likeCommentWithID:(NSNumber *)commentID
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/likes/new", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:nil
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               if (success) {
                                   success();
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)unlikeCommentWithID:(NSNumber *)commentID
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/likes/mine/delete", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI post:requestUrl
                        parameters:nil
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               if (success) {
                                   success();
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)getLikesForCommentID:(NSNumber *)commentID
                       count:(NSNumber *)count
                      before:(NSString *)before
              excludeUserIDs:(NSArray<NSNumber *> *)excludeUserIDs
                     success:(void (^)(NSArray<RemoteLikeUser *> * _Nonnull users, NSNumber *found))success
                     failure:(void (^)(NSError *))failure
{
    NSParameterAssert(commentID);

    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/likes", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_2];
    NSNumber *siteID = self.siteID;

    // If no count provided, default to endpoint max.
    if (count == 0) {
        count = @90;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"number": count }];
    
    if (before) {
        parameters[@"before"] = before;
    }
    
    if (excludeUserIDs) {
        parameters[@"exclude"] = excludeUserIDs;
    }

    [self.wordPressComRESTAPI get:requestUrl
                       parameters:parameters
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (success) {
            NSArray *jsonUsers = responseObject[@"likes"] ?: @[];
            NSArray<RemoteLikeUser *> *users = [self remoteUsersFromJSONArray:jsonUsers commentID:commentID siteID:siteID];
            NSNumber *found = [responseObject numberForKey:@"found"] ?: @0;
            success(users, found);
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - Private methods

- (NSArray *)remoteCommentsFromJSONArray:(NSArray *)jsonComments
{
    return [jsonComments wp_map:^id(NSDictionary *jsonComment) {
        return [self remoteCommentFromJSONDictionary:jsonComment];
    }];
}

- (RemoteComment *)remoteCommentFromJSONDictionary:(NSDictionary *)jsonDictionary
{
    RemoteComment *comment = [RemoteComment new];

    comment.authorID = [jsonDictionary numberForKeyPath:@"author.ID"];
    comment.author = jsonDictionary[@"author"][@"name"];
    // Email might be `false`, turn into `nil`
    comment.authorEmail = [jsonDictionary[@"author"] stringForKey:@"email"];
    comment.authorUrl = jsonDictionary[@"author"][@"URL"];
    comment.authorAvatarURL = [jsonDictionary stringForKeyPath:@"author.avatar_URL"];
    comment.authorIP = [jsonDictionary stringForKeyPath:@"author.ip_address"];
    comment.commentID = jsonDictionary[@"ID"];
    comment.date = [NSDate dateWithWordPressComJSONString:jsonDictionary[@"date"]];
    comment.link = jsonDictionary[@"URL"];
    comment.parentID = [jsonDictionary numberForKeyPath:@"parent.ID"];
    comment.postID = [jsonDictionary numberForKeyPath:@"post.ID"];
    comment.postTitle = [jsonDictionary stringForKeyPath:@"post.title"];
    comment.status = [self statusWithRemoteStatus:jsonDictionary[@"status"]];
    comment.type = jsonDictionary[@"type"];
    comment.isLiked = [[jsonDictionary numberForKey:@"i_like"] boolValue];
    comment.likeCount = [jsonDictionary numberForKey:@"like_count"];
    comment.canModerate = [[jsonDictionary numberForKey:@"can_moderate"] boolValue];
    comment.content = jsonDictionary[@"content"];
    comment.rawContent = jsonDictionary[@"raw_content"];

    return comment;
}

- (NSString *)statusWithRemoteStatus:(NSString *)remoteStatus
{
    NSString *status = remoteStatus;
    if ([status isEqualToString:@"unapproved"]) {
        status = @"hold";
    } else if ([status isEqualToString:@"approved"]) {
        status = @"approve";
    }
    return status;
}

- (NSString *)remoteStatusWithStatus:(NSString *)status
{
    NSString *remoteStatus = status;
    if ([remoteStatus isEqualToString:@"hold"]) {
        remoteStatus = @"unapproved";
    } else if ([remoteStatus isEqualToString:@"approve"]) {
        remoteStatus = @"approved";
    }
    return remoteStatus;
}

/**
 Returns an array of RemoteLikeUser based on provided JSON representation of users.
 
 @param jsonUsers An array containing JSON representations of users.
 @param commentID ID of the Comment the users liked.
 @param siteID    ID of the Comment's site.
 */
- (NSArray<RemoteLikeUser *> *)remoteUsersFromJSONArray:(NSArray *)jsonUsers
                                              commentID:(NSNumber *)commentID
                                                 siteID:(NSNumber *)siteID
{
    return [jsonUsers wp_map:^id(NSDictionary *jsonUser) {
        return [[RemoteLikeUser alloc] initWithDictionary:jsonUser commentID:commentID siteID:siteID];
    }];
}

@end
