#import "CommentServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "RemoteComment.h"
#import "NSDate+WordPressJSON.h"
#import <NSObject_SafeExpectations/NSObject+SafeExpectations.h>



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
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                 @"status": @"all",
                                 @"context": @"edit",
                                 @"number": @(maximumComments)
                                 }];
    if (options) {
        [parameters addEntriesFromDictionary:options];
    }
    
    [self.api GET:requestUrl
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remoteCommentsFromJSONArray:responseObject[@"comments"]]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{
                                 @"content": comment.content,
                                 @"context": @"edit",
                                 };
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               // TODO: validate response
               RemoteComment *comment = [self remoteCommentFromJSONDictionary:responseObject];
               if (success) {
                   success(comment);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{
                                 @"content": comment.content,
                                 @"context": @"edit",
                                 };
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               // TODO: validate response
               RemoteComment *comment = [self remoteCommentFromJSONDictionary:responseObject];
               if (success) {
                   success(comment);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{
                                 @"status": [self remoteStatusWithStatus:comment.status],
                                 @"context": @"edit",
                                 };
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               // TODO: validate response
               RemoteComment *comment = [self remoteCommentFromJSONDictionary:responseObject];
               if (success) {
                   success(comment);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)trashComment:(RemoteComment *)comment
             success:(void (^)())success
             failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/delete", self.siteID, comment.commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}


#pragma mark Post-centric methods

- (void)syncHierarchicalCommentsForPost:(NSNumber *)postID
                                   page:(NSUInteger)page
                                 number:(NSUInteger)number
                                success:(void (^)(NSArray *comments))success
                                failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/replies?order=ASC&hierarchical=1&page=%d&number=%d", self.siteID, postID, page, number];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];

    [self.api GET:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSDictionary *dict = (NSDictionary *)responseObject;
            NSArray *comments = [self remoteCommentsFromJSONArray:[dict arrayForKey:@"comments"]];
            success(comments);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Public Methods

- (void)updateCommentWithID:(NSNumber *)commentID
                    content:(NSString *)content
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{
        @"content": content,
        @"context": @"edit",
    };
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{@"content": content};
    
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   NSDictionary *commentDict = (NSDictionary *)responseObject;
                   RemoteComment *comment = [self remoteCommentFromJSONDictionary:commentDict];
                   success(comment);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{
        @"content": content,
        @"context": @"edit",
    };
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   NSDictionary *commentDict = (NSDictionary *)responseObject;
                   RemoteComment *comment = [self remoteCommentFromJSONDictionary:commentDict];
                   success(comment);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)moderateCommentWithID:(NSNumber *)commentID
                       status:(NSString *)status
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{
        @"status"   : status,
        @"context"  : @"edit",
    };
    
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)trashCommentWithID:(NSNumber *)commentID
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/delete", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)likeCommentWithID:(NSNumber *)commentID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/likes/new", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)unlikeCommentWithID:(NSNumber *)commentID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/likes/mine/delete", self.siteID, commentID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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

    comment.author = jsonDictionary[@"author"][@"name"];
    // Email might be `false`, turn into `nil`
    comment.authorEmail = [jsonDictionary[@"author"] stringForKey:@"email"];
    comment.authorUrl = jsonDictionary[@"author"][@"URL"];
    comment.authorAvatarURL = [jsonDictionary stringForKeyPath:@"author.avatar_URL"];
    comment.commentID = jsonDictionary[@"ID"];
    comment.content = jsonDictionary[@"content"];
    comment.date = [NSDate dateWithWordPressComJSONString:jsonDictionary[@"date"]];
    comment.link = jsonDictionary[@"URL"];
    comment.parentID = [jsonDictionary numberForKeyPath:@"parent.ID"];
    comment.postID = [jsonDictionary numberForKeyPath:@"post.ID"];
    comment.postTitle = [jsonDictionary stringForKeyPath:@"post.title"];
    comment.status = [self statusWithRemoteStatus:jsonDictionary[@"status"]];
    comment.type = jsonDictionary[@"type"];
    comment.isLiked = [[jsonDictionary numberForKey:@"i_like"] boolValue];
    comment.likeCount = [jsonDictionary numberForKey:@"like_count"];

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

@end
