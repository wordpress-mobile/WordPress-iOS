#import "TaxonomyServiceRemoteXMLRPC.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"
#import "RemoteTaxonomyPaging.h"
#import <WordPressShared/NSString+Util.h>
#import <WordPressApi/WordPressApi.h>

static NSString * const TaxonomyXMLRPCCategoryIdentifier = @"category";
static NSString * const TaxonomyXMLRPCTagIdentifier = @"post_tag";

static NSString * const TaxonomyXMLRPCIDParameter = @"term_id";
static NSString * const TaxonomyXMLRPCSlugParameter = @"slug";
static NSString * const TaxonomyXMLRPCNameParameter = @"name";
static NSString * const TaxonomyXMLRPCParentParameter = @"parent";
static NSString * const TaxonomyXMLRPCSearchParameter = @"search";
static NSString * const TaxonomyXMLRPCOrderParameter = @"order";
static NSString * const TaxonomyXMLRPCOrderByParameter = @"order_by";
static NSString * const TaxonomyXMLRPCNumberParameter = @"number";
static NSString * const TaxonomyXMLRPCOffsetParameter = @"offset";


@implementation TaxonomyServiceRemoteXMLRPC

#pragma mark - categories

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *extraParameters = [NSMutableDictionary dictionary];
    [extraParameters setObject:category.name ?: [NSNull null] forKey:TaxonomyXMLRPCNameParameter];
    if ([category.parentID integerValue] > 0) {
        [extraParameters setObject:category.parentID forKey:TaxonomyXMLRPCParentParameter];
    }
    
    [self createTaxonomyWithType:TaxonomyXMLRPCCategoryIdentifier
                      parameters:extraParameters
                         success:^(NSString *responseString) {
                             
                             RemotePostCategory *newCategory = [RemotePostCategory new];
                             NSString *categoryID = responseString;
                             newCategory.categoryID = [categoryID numericValue];
                             if (success) {
                                 success(newCategory);
                             }
                             
                         } failure:failure];
}

- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *))success
                         failure:(void (^)(NSError *))failure
{
    [self getCategoriesWithPaging:nil
                          success:success
                          failure:failure];
}

- (void)getCategoriesWithPaging:(RemoteTaxonomyPaging *)paging
                        success:(void (^)(NSArray <RemotePostCategory *> *categories))success
                        failure:(void (^)(NSError *error))failure
{
    [self getTaxonomiesWithType:TaxonomyXMLRPCCategoryIdentifier
                     parameters:[self parametersForPaging:paging]
                        success:^(NSArray *responseArray) {
                            if (success) {
                                success([self remoteCategoriesFromXMLRPCArray:responseArray]);
                            }
                        } failure:failure];
}

- (void)searchCategoriesWithName:(NSString *)nameQuery
                         success:(void (^)(NSArray<RemotePostCategory *> *))success
                         failure:(void (^)(NSError *))failure
{
    NSDictionary *searchParameters = @{TaxonomyXMLRPCSearchParameter: nameQuery};
    [self getTaxonomiesWithType:TaxonomyXMLRPCCategoryIdentifier
                     parameters:searchParameters
                        success:^(NSArray *responseArray) {
                            if (success) {
                                success([self remoteCategoriesFromXMLRPCArray:responseArray]);
                            }
                        } failure:failure];
}

#pragma mark - tags

- (void)getTagsWithSuccess:(void (^)(NSArray<RemotePostTag *> *))success
                   failure:(void (^)(NSError *))failure
{
    [self getTagsWithPaging:nil
                    success:success
                    failure:failure];
}

- (void)getTagsWithPaging:(RemoteTaxonomyPaging *)paging
                  success:(void (^)(NSArray <RemotePostTag *> *tags))success
                  failure:(void (^)(NSError *error))failure
{
    [self getTaxonomiesWithType:TaxonomyXMLRPCTagIdentifier
                     parameters:[self parametersForPaging:paging]
                        success:^(NSArray *responseArray) {
                            if (success) {
                                success([self remoteTagsFromXMLRPCArray:responseArray]);
                            }
                        } failure:failure];
}

- (void)searchTagsWithName:(NSString *)nameQuery
                         success:(void (^)(NSArray<RemotePostTag *> *))success
                         failure:(void (^)(NSError *))failure
{
    NSDictionary *searchParameters = @{TaxonomyXMLRPCSearchParameter: nameQuery};
    [self getTaxonomiesWithType:TaxonomyXMLRPCTagIdentifier
                     parameters:searchParameters
                        success:^(NSArray *responseArray) {
                            if (success) {
                                success([self remoteTagsFromXMLRPCArray:responseArray]);
                            }
                        } failure:failure];
}

#pragma mark - default methods

- (void)createTaxonomyWithType:(NSString *)typeIdentifier
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSString *responseString))success
                       failure:(void (^)(NSError *error))failure
{
    NSMutableDictionary *mutableParametersDict = [NSMutableDictionary dictionaryWithDictionary:@{@"taxonomy": typeIdentifier}];
    NSArray *xmlrpcParameters = nil;
    if (parameters.count) {
        [mutableParametersDict addEntriesFromDictionary:parameters];
    }
    
    xmlrpcParameters = [self XMLRPCArgumentsWithExtra:mutableParametersDict];
    
    [self.api callMethod:@"wp.newTerm"
              parameters:xmlrpcParameters
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
                     if (success) {
                         success(responseObject);
                     }
                     
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)getTaxonomiesWithType:(NSString *)typeIdentifier
                 parameters:(NSDictionary *)parameters
                    success:(void (^)(NSArray *responseArray))success
                      failure:(void (^)(NSError *error))failure
{
    NSArray *xmlrpcParameters = nil;
    if (parameters.count) {
        xmlrpcParameters = [self XMLRPCArgumentsWithExtra:@[typeIdentifier, parameters]];
    }else {
        xmlrpcParameters = [self XMLRPCArgumentsWithExtra:typeIdentifier];
    }
    [self.api callMethod:@"wp.getTerms"
              parameters:xmlrpcParameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (![responseObject isKindOfClass:[NSArray class]]) {
                         responseObject = nil;
                     }
                     if (success) {
                         success(responseObject);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

#pragma mark - helpers

- (NSArray <RemotePostCategory *> *)remoteCategoriesFromXMLRPCArray:(NSArray *)xmlrpcArray
{
    return [xmlrpcArray wp_map:^id(NSDictionary *xmlrpcCategory) {
        return [self remoteCategoryFromXMLRPCDictionary:xmlrpcCategory];
    }];
}

- (RemotePostCategory *)remoteCategoryFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    if (!xmlrpcDictionary) {
        return nil;
    }
    
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = [xmlrpcDictionary numberForKey:TaxonomyXMLRPCIDParameter];
    category.name = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCNameParameter];
    category.parentID = [xmlrpcDictionary numberForKey:TaxonomyXMLRPCParentParameter];
    return category;
}

- (NSArray <RemotePostTag *> *)remoteTagsFromXMLRPCArray:(NSArray *)xmlrpcArray
{
    return [xmlrpcArray wp_map:^id(NSDictionary *xmlrpcTag) {
        return [self remoteTagFromXMLRPCDictionary:xmlrpcTag];
    }];
}

- (RemotePostTag *)remoteTagFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    if (!xmlrpcDictionary) {
        return nil;
    }
    
    RemotePostTag *tag = [RemotePostTag new];
    tag.tagID = [xmlrpcDictionary numberForKey:TaxonomyXMLRPCIDParameter];
    tag.name = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCNumberParameter];
    tag.slug = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCSlugParameter];
    return tag;
}

- (NSDictionary *)parametersForPaging:(RemoteTaxonomyPaging *)paging
{
    if (!paging) {
        return nil;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (paging.number) {
        [dictionary setObject:paging.number forKey:TaxonomyXMLRPCNumberParameter];
    }
    
    if (paging.offset) {
        [dictionary setObject:paging.offset forKey:TaxonomyXMLRPCOffsetParameter];
    }
    
    if (paging.order == RemoteTaxonomyPagingOrderAscending) {
        [dictionary setObject:@"ASC" forKey:TaxonomyXMLRPCOrderParameter];
    } else if (paging.order == RemoteTaxonomyPagingOrderDescending) {
        [dictionary setObject:@"DESC" forKey:TaxonomyXMLRPCOrderParameter];
    }
    
    if (paging.orderBy == RemoteTaxonomyPagingResultsOrderingByName) {
        [dictionary setObject:@"name" forKey:TaxonomyXMLRPCOrderByParameter];
    } else if (paging.orderBy == RemoteTaxonomyPagingResultsOrderingByCount) {
        [dictionary setObject:@"count" forKey:TaxonomyXMLRPCOrderByParameter];
    }
    
    return dictionary.count ? dictionary : nil;
}

@end
