#import "CategoryServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "RemoteCategory.h"

@interface CategoryServiceRemoteREST ()
@property (nonatomic, strong) WordPressComApi *api;
@end

@implementation CategoryServiceRemoteREST

- (instancetype)initWithApi:(WordPressComApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

- (void)createCategory:(RemoteCategory *)category
               forBlog:(Blog *)blog
               success:(void (^)(RemoteCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSParameterAssert(category.name != nil);
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories/new?context=edit", blog.dotComID];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"name"] = category.name;
    if (category.parentID) {
        parameters[@"parent"] = category.parentID;
    }

    [self.api POST:path
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               RemoteCategory *receivedCategory = [self remoteCategoryWithJSONDictionary:responseObject];
               if (success) {
                   success(receivedCategory);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (RemoteCategory *)remoteCategoryWithJSONDictionary:(NSDictionary *)jsonCategory
{
    RemoteCategory *category = [RemoteCategory new];
    category.categoryID = jsonCategory[@"ID"];
    category.name = jsonCategory[@"name"];
    category.parentID = jsonCategory[@"parent"];
    return category;
}

@end
