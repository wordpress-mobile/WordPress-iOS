#import "CommentServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "RemoteComment.h"
#import <WordPressApi.h>

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
                   failure:(void (^)(NSError *))failure {
    NSDictionary *extraParameters = @{
                                     @"number": @100
                                     };
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

#pragma mark - Private methods

- (NSArray *)remoteCommentsFromXMLRPCArray:(NSArray *)xmlrpcArray {
    NSMutableArray *comments = [NSMutableArray arrayWithCapacity:xmlrpcArray.count];
    for (NSDictionary *xmlrpcComment in xmlrpcArray) {
        [comments addObject:[self remoteCommentFromXMLRPCDictionary:xmlrpcComment]];
    }
    return [NSArray arrayWithArray:comments];
}

- (RemoteComment *)remoteCommentFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary {
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
