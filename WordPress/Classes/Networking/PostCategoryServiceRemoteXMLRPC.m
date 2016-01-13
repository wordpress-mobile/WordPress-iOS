#import "PostCategoryServiceRemoteXMLRPC.h"
#import "RemotePostCategory.h"
#import <WordPressShared/NSString+Util.h>
#import <WordPressApi/WordPressApi.h>

@implementation PostCategoryServiceRemoteXMLRPC

- (void)getCategoriesWithSuccess:(void (^)(NSArray *categories))success
                         failure:(void (^)(NSError *error))failure
{
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:@"category"];
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

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSDictionary *extraParameters = @{
                                      @"name" : category.name ?: [NSNull null],
                                      @"parent_id" : category.parentID ?: @0,
                                      @"taxonomy" : @"category",
                                      };
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:extraParameters];


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
                     RemotePostCategory *newCategory = [RemotePostCategory new];
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
    return [xmlrpcArray wp_map:^id(NSDictionary *xmlrpcCategory) {
        return [self remoteCategoryFromXMLRPCDictionary:xmlrpcCategory];
    }];
}

- (RemotePostCategory *)remoteCategoryFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = [xmlrpcDictionary numberForKey:@"term_id"];
    category.name = [xmlrpcDictionary stringForKey:@"name"];
    category.parentID = [xmlrpcDictionary numberForKey:@"parent"];
    return category;
}

@end
