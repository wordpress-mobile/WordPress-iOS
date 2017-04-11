#import "CommentServiceRemoteXMLRPC.h"
#import "RemoteComment.h"
#import "WordPress-Swift.h"
@import wpxmlrpc;

@implementation CommentServiceRemoteXMLRPC

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
    NSMutableDictionary *extraParameters = [@{
                                                @"number": @(maximumComments)
                                            } mutableCopy];
    if (options) {
        [extraParameters addEntriesFromDictionary:options];
    }
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:extraParameters];
    [self.api callMethod:@"wp.getComments"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remoteCommentsFromXMLRPCArray:responseObject]);
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)getCommentWithID:(NSNumber *)commentID
                 success:(void (^)(RemoteComment *comment))success
                 failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:commentID];
    [self.api callMethod:@"wp.getComment"
              parameters:parameters success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                  if (success) {
                      // TODO: validate response
                      RemoteComment *comment = [self remoteCommentFromXMLRPCDictionary:responseObject];
                      success(comment);
                  }
              } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                  failure(error);
              }];
}

- (void)createComment:(RemoteComment *)comment
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(comment.postID != nil);
    NSDictionary *commentDictionary = @{
                                        @"content": comment.content,
                                        @"comment_parent": comment.parentID,
                                        };
    NSArray *extraParameters = @[
                                 comment.postID,
                                 commentDictionary,
                                 ];
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:extraParameters];
    [self.api callMethod:@"wp.newComment"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     NSNumber *commentID = responseObject;
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                    success:success
                                    failure:failure];
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)updateComment:(RemoteComment *)comment
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSNumber *commentID = comment.commentID;
    NSArray *extraParameters = @[
                                 comment.commentID,
                                 @{@"content": comment.content},
                                 ];
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:extraParameters];
    [self.api callMethod:@"wp.editComment"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                    success:success
                                    failure:failure];
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
    NSParameterAssert(comment.commentID != nil);
    NSArray *extraParameters = @[
                                 comment.commentID,
                                 @{@"status": comment.status},
                                 ];
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:extraParameters];
    [self.api callMethod:@"wp.editComment"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     NSNumber *commentID = responseObject;
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                    success:success
                                    failure:failure];
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     // If the error is a 500 this could be a signal that the error changed status on the server
                     if ([error.domain isEqualToString:WPXMLRPCFaultErrorDomain]
                         && error.code == 500) {
                         [self getCommentWithID:comment.commentID success:success failure:failure];
                         return;
                     }
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)trashComment:(RemoteComment *)comment
             success:(void (^)())success
             failure:(void (^)(NSError *))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:comment.commentID];
    [self.api callMethod:@"wp.deleteComment"
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

#pragma mark - Private methods

- (NSArray *)remoteCommentsFromXMLRPCArray:(NSArray *)xmlrpcArray
{
    return [xmlrpcArray wp_map:^id(NSDictionary *xmlrpcComment) {
        return [self remoteCommentFromXMLRPCDictionary:xmlrpcComment];
    }];
}

- (RemoteComment *)remoteCommentFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    RemoteComment *comment = [RemoteComment new];
    comment.author = xmlrpcDictionary[@"author"];
    comment.authorEmail = xmlrpcDictionary[@"author_email"];
    comment.authorUrl = xmlrpcDictionary[@"author_url"];
    comment.commentID = [xmlrpcDictionary numberForKey:@"comment_id"];
    comment.content = xmlrpcDictionary[@"content"];
    comment.date = xmlrpcDictionary[@"date_created_gmt"];
    comment.link = xmlrpcDictionary[@"link"];
    comment.parentID = [xmlrpcDictionary numberForKey:@"parent"];
    comment.postID = [xmlrpcDictionary numberForKey:@"post_id"];
    comment.postTitle = xmlrpcDictionary[@"post_title"];
    comment.status = xmlrpcDictionary[@"status"];
    comment.type = xmlrpcDictionary[@"type"];
    return comment;
}

@end
