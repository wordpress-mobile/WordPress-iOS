#import "PostServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "RemotePost.h"
#import "RemoteCategory.h"
#import <WordPressApi.h>

@interface PostServiceRemoteXMLRPC ()
@property (nonatomic, strong) WPXMLRPCClient *api;
@end

@implementation PostServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)getPostsForBlog:(Blog *)blog
                success:(void (^)(NSArray *))success
                failure:(void (^)(NSError *))failure {
    NSDictionary *extraParameters = @{
                                      @"number": @40,
                                      };
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];
    [self.api callMethod:@"wp.getPosts"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remotePostsFromXMLRPCArray:responseObject]);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

#pragma mark - Private methods

- (NSArray *)remotePostsFromXMLRPCArray:(NSArray *)xmlrpcArray {
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:xmlrpcArray.count];
    for (NSDictionary *xmlrpcPost in xmlrpcArray) {
        [posts addObject:[self remotePostFromXMLRPCDictionary:xmlrpcPost]];
    }
    return [NSArray arrayWithArray:posts];
}

- (RemotePost *)remotePostFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary {
    RemotePost *post = [RemotePost new];

    post.postID = [xmlrpcDictionary numberForKey:@"post_id"];
    post.date = xmlrpcDictionary[@"post_date_gmt"];
    if (xmlrpcDictionary[@"link"]) {
        post.URL = [NSURL URLWithString:xmlrpcDictionary[@"link"]];
    }
    post.title = xmlrpcDictionary[@"post_title"];
    post.content = xmlrpcDictionary[@"post_content"];
    post.excerpt = xmlrpcDictionary[@"post_excerpt"];
    post.slug = xmlrpcDictionary[@"post_name"];
    post.status = xmlrpcDictionary[@"post_status"];
    post.password = xmlrpcDictionary[@"post_password"];
    if ([post.password isEmpty]) {
        post.password = nil;
    }
    post.parentID = [xmlrpcDictionary numberForKey:@"post_parent"];
    // When there is no featured image, post_thumbnail is an empty array :(
    post.postThumbnailID = [[xmlrpcDictionary dictionaryForKey:@"post_thumbnail"] numberForKey:@"attachment_id"];
    post.type = xmlrpcDictionary[@"post_type"];
    post.format = xmlrpcDictionary[@"post_format"];

    post.metadata = xmlrpcDictionary[@"custom_fields"];

    NSArray *terms = [xmlrpcDictionary arrayForKey:@"terms"];
    post.tags = [self tagsFromXMLRPCTermsArray:terms];
    post.categories = [self remoteCategoriesFromXMLRPCTermsArray:terms];

    return post;
}

- (NSArray *)tagsFromXMLRPCTermsArray:(NSArray *)terms {
    NSArray *tags = [terms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"taxonomy = 'post_tag' AND name != NIL"]];
    return [tags valueForKey:@"name"];
}

- (NSArray *)remoteCategoriesFromXMLRPCTermsArray:(NSArray *)terms {
    NSArray *categories = [terms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"taxonomy = 'category'"]];
    NSMutableArray *remoteCategories = [NSMutableArray arrayWithCapacity:categories.count];
    for (NSDictionary *category in categories) {
        [remoteCategories addObject:[self remoteCategoryFromXMLRPCDictionary:category]];
    }
    return [NSArray arrayWithArray:remoteCategories];
}

- (RemoteCategory *)remoteCategoryFromXMLRPCDictionary:(NSDictionary *)xmlrpcCategory {
    RemoteCategory *category = [RemoteCategory new];
    category.categoryID = [xmlrpcCategory numberForKey:@"term_id"];
    category.name = [xmlrpcCategory stringForKey:@"name"];
    category.parentID = [xmlrpcCategory numberForKey:@"parent"];
    return category;
}

@end
