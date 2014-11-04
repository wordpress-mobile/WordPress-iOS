#import "CategoryServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "RemoteCategory.h"
#import <NSString+Util.h>

@interface CategoryServiceRemoteXMLRPC ()
@property (nonatomic, strong) WPXMLRPCClient *api;
@end

@implementation CategoryServiceRemoteXMLRPC

- (instancetype)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)getCategoriesForBlog:(Blog *)blog
                     success:(void (^)(NSArray *categories))success
                     failure:(void (^)(NSError *error))failure
{
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:@"category"];
    [self.api callMethod:@"wp.getTerms"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remoteCategoriesFromXMLRPCArray:responseObject]);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)createCategory:(RemoteCategory *)category
               forBlog:(Blog *)blog
               success:(void (^)(RemoteCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSDictionary *extraParameters = @{
                                      @"name" : category.name ?: [NSNull null],
                                      @"parent_id" : category.parentID ?: @0,
                                      @"taxonomy" : @"category",
                                      };
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];


    [self.api callMethod:@"wp.newTerm"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSString class]], @"wp.newTerm response should be a string");
                     if (![responseObject respondsToSelector:@selector(numericValue)]) {
                         NSString *errorMessage = @"Invalid response to wp.newTerm";
                         NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: errorMessage };
                         NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
                         DDLogError(@"%@: %@", errorMessage, responseObject);
                         if (failure) {
                             failure(error);
                         }
                         return;
                     }
                     RemoteCategory *newCategory = [RemoteCategory new];
                     NSString *categoryID = (NSString *)responseObject;
                     newCategory.categoryID = [categoryID numericValue];
                     if (success) {
                         success(newCategory);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (NSArray *)remoteCategoriesFromXMLRPCArray:(NSArray *)xmlrpcArray
{
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:xmlrpcArray.count];
    for (NSDictionary *xmlrpcCategory in xmlrpcArray) {
        [categories addObject:[self remoteCategoryFromXMLRPCDictionary:xmlrpcCategory]];
    }
    return [NSArray arrayWithArray:categories];
}

- (RemoteCategory *)remoteCategoryFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    RemoteCategory *category = [RemoteCategory new];
    category.categoryID = [xmlrpcDictionary numberForKey:@"term_id"];
    category.name = [xmlrpcDictionary stringForKey:@"name"];
    category.parentID = [xmlrpcDictionary numberForKey:@"parent"];
    return category;
}

@end
