#import "TaxonomyServiceRemoteXMLRPC.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"
#import "RemoteTaxonomyPaging.h"
#import <WordPressShared/NSString+Util.h>
#import <WordPressApi/WordPressApi.h>

NS_ASSUME_NONNULL_BEGIN

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
               success:(nullable void (^)(RemotePostCategory *))success
               failure:(nullable void (^)(NSError *))failure
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
                         failure:(nullable void (^)(NSError *))failure
{
    [self getTaxonomiesWithType:TaxonomyXMLRPCCategoryIdentifier
                     parameters:nil
                        success:^(NSArray *responseArray) {
                            success([self remoteCategoriesFromXMLRPCArray:responseArray]);
                        } failure:failure];
}

- (void)getCategoriesWithPaging:(RemoteTaxonomyPaging *)paging
                        success:(void (^)(NSArray <RemotePostCategory *> *categories))success
                        failure:(nullable void (^)(NSError *error))failure
{
    [self getTaxonomiesWithType:TaxonomyXMLRPCCategoryIdentifier
                     parameters:[self parametersForPaging:paging]
                        success:^(NSArray *responseArray) {
                            success([self remoteCategoriesFromXMLRPCArray:responseArray]);
                        } failure:failure];
}

- (void)searchCategoriesWithName:(NSString *)nameQuery
                         success:(void (^)(NSArray<RemotePostCategory *> *))success
                         failure:(nullable void (^)(NSError *))failure
{
    NSDictionary *searchParameters = @{TaxonomyXMLRPCSearchParameter: nameQuery};
    [self getTaxonomiesWithType:TaxonomyXMLRPCCategoryIdentifier
                     parameters:searchParameters
                        success:^(NSArray *responseArray) {
                            success([self remoteCategoriesFromXMLRPCArray:responseArray]);
                        } failure:failure];
}

#pragma mark - tags

- (void)createTag:(RemotePostTag *)tag
          success:(nullable void (^)(RemotePostTag *tag))success
          failure:(nullable void (^)(NSError *error))failure
{
    NSMutableDictionary *extraParameters = [NSMutableDictionary dictionary];
    [extraParameters setObject:tag.name ?: [NSNull null] forKey:TaxonomyXMLRPCNameParameter];
    
    [self createTaxonomyWithType:TaxonomyXMLRPCTagIdentifier
                      parameters:extraParameters
                         success:^(NSString *responseString) {
                             RemotePostTag *newTag = [RemotePostTag new];
                             NSString *tagID = responseString;
                             newTag.tagID = [tagID numericValue];
                             if (success) {
                                 success(newTag);
                             }
                         } failure:failure];
}

- (void)getTagsWithSuccess:(void (^)(NSArray<RemotePostTag *> *))success
                   failure:(nullable void (^)(NSError *))failure
{
    [self getTaxonomiesWithType:TaxonomyXMLRPCTagIdentifier
                     parameters:nil
                        success:^(NSArray *responseArray) {
                            success([self remoteTagsFromXMLRPCArray:responseArray]);
                        } failure:failure];
}

- (void)getTagsWithPaging:(RemoteTaxonomyPaging *)paging
                  success:(void (^)(NSArray <RemotePostTag *> *tags))success
                  failure:(nullable void (^)(NSError *error))failure
{
    [self getTaxonomiesWithType:TaxonomyXMLRPCTagIdentifier
                     parameters:[self parametersForPaging:paging]
                        success:^(NSArray *responseArray) {
                            success([self remoteTagsFromXMLRPCArray:responseArray]);
                        } failure:failure];
}

- (void)searchTagsWithName:(NSString *)nameQuery
                   success:(void (^)(NSArray<RemotePostTag *> *))success
                   failure:(nullable void (^)(NSError *))failure
{
    NSDictionary *searchParameters = @{TaxonomyXMLRPCSearchParameter: nameQuery};
    [self getTaxonomiesWithType:TaxonomyXMLRPCTagIdentifier
                     parameters:searchParameters
                        success:^(NSArray *responseArray) {
                            success([self remoteTagsFromXMLRPCArray:responseArray]);
                        } failure:failure];
}

#pragma mark - default methods

- (void)createTaxonomyWithType:(NSString *)typeIdentifier
                    parameters:(nullable NSDictionary *)parameters
                       success:(void (^)(NSString *responseString))success
                       failure:(nullable void (^)(NSError *error))failure
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
                     if (![responseObject respondsToSelector:@selector(numericValue)]) {
                         NSString *message = [NSString stringWithFormat:@"Invalid response creating taxonomy of type: %@", typeIdentifier];
                         [self handleResponseErrorWithMessage:message method:@"wp.newTerm" failure:failure];
                         return;
                     }
                     success(responseObject);
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)getTaxonomiesWithType:(NSString *)typeIdentifier
                   parameters:(nullable NSDictionary *)parameters
                      success:(void (^)(NSArray *responseArray))success
                      failure:(nullable void (^)(NSError *error))failure
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
                     if (![responseObject isKindOfClass:[NSArray class]]) {
                         NSString *message = [NSString stringWithFormat:@"Invalid response requesting taxonomy of type: %@", typeIdentifier];
                         [self handleResponseErrorWithMessage:message method:@"wp.getTerms" failure:failure];
                         return;
                     }
                     success(responseObject);
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
    RemotePostTag *tag = [RemotePostTag new];
    tag.tagID = [xmlrpcDictionary numberForKey:TaxonomyXMLRPCIDParameter];
    tag.name = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCNumberParameter];
    tag.slug = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCSlugParameter];
    return tag;
}

- (NSDictionary *)parametersForPaging:(RemoteTaxonomyPaging *)paging
{
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

- (void)handleResponseErrorWithMessage:(NSString *)message
                                method:(NSString *)methodStr
                               failure:(nullable void(^)(NSError *error))failure
{
    DDLogError(@"%@ - method: %@", message, methodStr);
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
    if (failure) {
        failure(error);
    }
}

@end

NS_ASSUME_NONNULL_END
