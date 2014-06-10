#import "CommentServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "RemoteComment.h"
#import "NSDate+JSON.h"
#import <NSObject+SafeExpectations.h>

@interface CommentServiceRemoteREST ()
@property (nonatomic, strong) WordPressComApi *api;
@end

@implementation CommentServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api {
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

- (void)getCommentsForBlog:(Blog *)blog
                   success:(void (^)(NSArray *))success
                   failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments", blog.dotComID];
    NSDictionary *parameters = @{
                                 @"status": @"all",
                                 };
    [self.api GET:path
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
              forBlog:(Blog *)blog
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *))failure {
    NSString *path;
    if (comment.parentID) {
        path = [NSString stringWithFormat:@"sites/%@/comments/%@/replies/new", blog.dotComID, comment.parentID];
    } else {
        path = [NSString stringWithFormat:@"sites/%@/posts/%@/replies/new", blog.dotComID, comment.postID];
    }
    NSDictionary *parameters = @{
                                 @"content": comment.content,
                                 };
    [self.api POST:path
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
              forBlog:(Blog *)blog
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", blog.dotComID, comment.commentID];
    NSDictionary *parameters = @{
                                 @"content": comment.content,
                                 };
    [self.api POST:path
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
                forBlog:(Blog *)blog
                success:(void (^)(RemoteComment *))success
                failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", blog.dotComID, comment.commentID];
    NSDictionary *parameters = @{
                                 @"status": [self remoteStatusWithStatus:comment.status],
                                 };
    [self.api POST:path
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
             forBlog:(Blog *)blog
             success:(void (^)())success
             failure:(void (^)(NSError *error))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@/delete", blog.dotComID, comment.commentID];
    [self.api POST:path
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

- (NSArray *)remoteCommentsFromJSONArray:(NSArray *)jsonComments {
    NSMutableArray *comments = [NSMutableArray arrayWithCapacity:jsonComments.count];
    for (NSDictionary *jsonComment in jsonComments) {
        [comments addObject:[self remoteCommentFromJSONDictionary:jsonComment]];
    }
    return [NSArray arrayWithArray:comments];

}

- (RemoteComment *)remoteCommentFromJSONDictionary:(NSDictionary *)jsonDictionary {
    RemoteComment *comment = [RemoteComment new];

    comment.author = jsonDictionary[@"author"][@"name"];
    // Email might be `false`, turn into `nil`
    comment.authorEmail = [jsonDictionary[@"author"] stringForKey:@"email"];
    comment.authorUrl = jsonDictionary[@"author"][@"URL"];
    comment.commentID = jsonDictionary[@"ID"];
    comment.content = jsonDictionary[@"content"];
    comment.date = [NSDate dateWithWordPressComJSONString:jsonDictionary[@"date"]];
    comment.link = jsonDictionary[@"URL"];
    comment.parentID = [jsonDictionary numberForKeyPath:@"parent.ID"];
    comment.postID = [jsonDictionary numberForKeyPath:@"post.ID"];
    comment.postTitle = [jsonDictionary stringForKeyPath:@"post.title"];
    comment.status = [self statusWithRemoteStatus:jsonDictionary[@"status"]];
    comment.type = jsonDictionary[@"type"];

    return comment;
}

- (NSString *)statusWithRemoteStatus:(NSString *)remoteStatus {
    NSString *status = remoteStatus;
    if ([status isEqualToString:@"unapproved"]) {
        status = @"hold";
    }
    return status;
}

- (NSString *)remoteStatusWithStatus:(NSString *)status {
    NSString *remoteStatus = status;
    if ([remoteStatus isEqualToString:@"hold"]) {
        remoteStatus = @"unapproved";
    }
    return remoteStatus;
}

@end
