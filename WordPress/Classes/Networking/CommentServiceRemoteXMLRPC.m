#import "CommentServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "RemoteComment.h"
#import <WordPressApi.h>

static const NSInteger NumberOfCommentsToSync = 100;

@interface CommentServiceRemoteXMLRPC ()
@property (nonatomic, strong) WPXMLRPCClient *api;
@end

@implementation CommentServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)getCommentsForBlog:(Blog *)blog
                   success:(void (^)(NSArray *))success
                   failure:(void (^)(NSError *))failure
{
    [self getCommentsForBlog:blog options:nil success:success failure:failure];
}

- (void)getCommentsForBlog:(Blog *)blog
                   options:(NSDictionary *)options
                   success:(void (^)(NSArray *))success
                   failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *extraParameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                      @"number": @(NumberOfCommentsToSync)
                                      }];
    if (options) {
        [extraParameters addEntriesFromDictionary:options];
    }
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];
    [self.api callMethod:@"wp.getComments"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remoteCommentsFromXMLRPCArray:responseObject]);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)getCommentWithID:(NSNumber *)commentID
                 forBlog:(Blog *)blog
                 success:(void (^)(RemoteComment *comment))success
                 failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:commentID];
    [self.api callMethod:@"wp.getComment"
              parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (success) {
                      // TODO: validate response
                      RemoteComment *comment = [self remoteCommentFromXMLRPCDictionary:responseObject];
                      success(comment);
                  }
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  failure(error);
              }];
}

- (void)createComment:(RemoteComment *)comment
              forBlog:(Blog *)blog
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
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];
    [self.api callMethod:@"wp.newComment"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSNumber *commentID = responseObject;
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                    forBlog:blog
                                    success:success
                                    failure:failure];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)updateComment:(RemoteComment *)comment
              forBlog:(Blog *)blog
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSNumber *commentID = comment.commentID;
    NSArray *extraParameters = @[
                                 comment.commentID,
                                 @{@"content": comment.content},
                                 ];
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];
    [self.api callMethod:@"wp.editComment"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                    forBlog:blog
                                    success:success
                                    failure:failure];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)moderateComment:(RemoteComment *)comment
                forBlog:(Blog *)blog
                success:(void (^)(RemoteComment *))success
                failure:(void (^)(NSError *))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSArray *extraParameters = @[
                                 comment.commentID,
                                 @{@"status": comment.status},
                                 ];
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];
    [self.api callMethod:@"wp.editComment"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSNumber *commentID = responseObject;
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                    forBlog:blog
                                    success:success
                                    failure:failure];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)trashComment:(RemoteComment *)comment
             forBlog:(Blog *)blog
             success:(void (^)())success
             failure:(void (^)(NSError *))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:comment.commentID];
    [self.api callMethod:@"wp.deleteComment"
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

#pragma mark - Private methods

- (NSArray *)remoteCommentsFromXMLRPCArray:(NSArray *)xmlrpcArray
{
    NSMutableArray *comments = [NSMutableArray arrayWithCapacity:xmlrpcArray.count];
    for (NSDictionary *xmlrpcComment in xmlrpcArray) {
        [comments addObject:[self remoteCommentFromXMLRPCDictionary:xmlrpcComment]];
    }
    return [NSArray arrayWithArray:comments];
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
