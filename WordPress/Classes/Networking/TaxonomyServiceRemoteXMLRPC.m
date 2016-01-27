#import "TaxonomyServiceRemoteXMLRPC.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"
#import "RemoteTaxonomyPaging.h"
#import <WordPressShared/NSString+Util.h>
#import <WordPressApi/WordPressApi.h>

static NSString * const TaxonomyServiceRemoteXMLRPCCategoryTypeIdentifier = @"category";
static NSString * const TaxonomyServiceRemoteXMLRPCTagTypeIdentifier = @"post_tag";

@implementation TaxonomyServiceRemoteXMLRPC

#pragma mark - categories

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *extraParameters = [NSMutableDictionary dictionaryWithCapacity:2];
    [extraParameters setObject:category.name ?: [NSNull null] forKey:@"name"];
    if ([category.parentID integerValue] > 0) {
        [extraParameters setObject:category.parentID forKey:@"parent"];
    }
    
    [self createTaxonomyWithType:TaxonomyServiceRemoteXMLRPCCategoryTypeIdentifier
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
    [self getCategoriesWithSuccess:success
                            paging:nil
                           failure:failure];
}

- (void)getCategoriesWithSuccess:(void (^)(NSArray<RemotePostCategory *> *))success
                          paging:(RemoteTaxonomyPaging *)paging
                         failure:(void (^)(NSError *))failure
{
    [self getTaxonomiesWithType:TaxonomyServiceRemoteXMLRPCCategoryTypeIdentifier
                     parameters:[self parametersForPaging:paging]
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
    [self getTagsWithSuccess:success
                      paging:nil
                     failure:failure];
}

- (void)getTagsWithSuccess:(void (^)(NSArray<RemotePostTag *> *))success
                    paging:(RemoteTaxonomyPaging *)paging
                   failure:(void (^)(NSError *))failure
{
    [self getTaxonomiesWithType:TaxonomyServiceRemoteXMLRPCTagTypeIdentifier
                     parameters:[self parametersForPaging:paging]
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
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = [xmlrpcDictionary numberForKey:@"term_id"];
    category.name = [xmlrpcDictionary stringForKey:@"name"];
    category.parentID = [xmlrpcDictionary numberForKey:@"parent"];
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
    RemotePostTag *tag = [RemotePostTag new];
    tag.tagID = [xmlrpcDictionary numberForKey:@"term_id"];
    tag.name = [xmlrpcDictionary stringForKey:@"name"];
    tag.slug = [xmlrpcDictionary stringForKey:@"slug"];
    return tag;
}

- (NSDictionary *)parametersForPaging:(RemoteTaxonomyPaging *)paging
{
    if (!paging) {
        return nil;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (paging.number) {
        [dictionary setObject:paging.number forKey:@"number"];
    }
    
    if (paging.offset) {
        [dictionary setObject:paging.offset forKey:@"offset"];
    }
    
    if (paging.order == RemoteTaxonomyPagingOrderAscending) {
        [dictionary setObject:@"ASC" forKey:@"order"];
    } else if (paging.order == RemoteTaxonomyPagingOrderDescending) {
        [dictionary setObject:@"DESC" forKey:@"order"];
    }
    
    if (paging.orderBy == RemoteTaxonomyPagingResultsOrderingByName) {
        [dictionary setObject:@"name" forKey:@"order_by"];
    } else if (paging.orderBy == RemoteTaxonomyPagingResultsOrderingByCount) {
        [dictionary setObject:@"count" forKey:@"order_by"];
    }
    
    return dictionary.count ? dictionary : nil;
}

@end
