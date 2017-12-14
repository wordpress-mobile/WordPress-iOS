#import "TaxonomyServiceRemoteXMLRPC.h"
#import "RemotePostTag.h"
#import "RemoteTaxonomyPaging.h"
#import <WordPressKit/WordPressKit-Swift.h>
#import "Logging.h"
@import WordPressShared;
@import NSObject_SafeExpectations;

NS_ASSUME_NONNULL_BEGIN

static NSString * const TaxonomyXMLRPCCategoryIdentifier = @"category";
static NSString * const TaxonomyXMLRPCTagIdentifier = @"post_tag";

static NSString * const TaxonomyXMLRPCIDParameter = @"term_id";
static NSString * const TaxonomyXMLRPCSlugParameter = @"slug";
static NSString * const TaxonomyXMLRPCNameParameter = @"name";
static NSString * const TaxonomyXMLRPCDescriptionParameter = @"description";
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
    [extraParameters setObject:tag.tagDescription ?: [NSNull null] forKey:TaxonomyXMLRPCDescriptionParameter];
    
    [self createTaxonomyWithType:TaxonomyXMLRPCTagIdentifier
                      parameters:extraParameters
                         success:^(NSString *responseString) {
                             RemotePostTag *newTag = [RemotePostTag new];
                             NSString *tagID = responseString;
                             newTag.tagID = [tagID numericValue];
                             newTag.name = tag.name;
                             newTag.tagDescription = tag.tagDescription;
                             newTag.slug = tag.slug;
                             if (success) {
                                 success(newTag);
                             }
                         } failure:failure];
}

- (void)updateTag:(RemotePostTag *)tag
          success:(nullable void (^)(RemotePostTag *tag))success
          failure:(nullable void (^)(NSError *error))failure
{
    NSMutableDictionary *extraParameters = [NSMutableDictionary dictionary];
    [extraParameters setObject:tag.name ?: [NSNull null] forKey:TaxonomyXMLRPCNameParameter];
    [extraParameters setObject:tag.tagDescription ?: [NSNull null] forKey:TaxonomyXMLRPCDescriptionParameter];

    [self editTaxonomyWithType:TaxonomyXMLRPCTagIdentifier
                        termId:tag.tagID
                    parameters:extraParameters success:^(BOOL response) {
                        if (success) {
                            success(tag);
                        }
                    } failure:failure];
}

- (void)deleteTag:(RemotePostTag *)tag
          success:(nullable void (^)(void))success
          failure:(nullable void (^)(NSError *error))failure
{
    [self deleteTaxonomyWithType:TaxonomyXMLRPCTagIdentifier
                          termId:tag.tagID
                      parameters:nil success:^(BOOL response) {
                          if (success) {
                              success();
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
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     if (![responseObject respondsToSelector:@selector(numericValue)]) {
                         NSString *message = [NSString stringWithFormat:@"Invalid response creating taxonomy of type: %@", typeIdentifier];
                         [self handleResponseErrorWithMessage:message method:@"wp.newTerm" failure:failure];
                         return;
                     }
                     success(responseObject);
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     if (![responseObject isKindOfClass:[NSArray class]]) {
                         NSString *message = [NSString stringWithFormat:@"Invalid response requesting taxonomy of type: %@", typeIdentifier];
                         [self handleResponseErrorWithMessage:message method:@"wp.getTerms" failure:failure];
                         return;
                     }
                     success(responseObject);
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)deleteTaxonomyWithType:(NSString *)typeIdentifier
                        termId:(NSNumber *)termId
                    parameters:(nullable NSDictionary *)parameters
                       success:(void (^)(BOOL response))success
                       failure:(nullable void (^)(NSError *error))failure
{
    NSArray *xmlrpcParameters = [self XMLRPCArgumentsWithExtraDefaults:@[typeIdentifier, termId]
                                                              andExtra:nil];
    
    [self.api callMethod:@"wp.deleteTerm"
              parameters:xmlrpcParameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     if (![responseObject respondsToSelector:@selector(boolValue)]) {
                         NSString *message = [NSString stringWithFormat:@"Invalid response deleting taxonomy of type: %@", typeIdentifier];
                         [self handleResponseErrorWithMessage:message method:@"wp.deleteTerm" failure:failure];
                         return;
                     }
                     success([responseObject boolValue]);
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)editTaxonomyWithType:(NSString *)typeIdentifier
                      termId:(NSNumber *)termId
                  parameters:(nullable NSDictionary *)parameters
                     success:(void (^)(BOOL response))success
                     failure:(nullable void (^)(NSError *error))failure
{
    NSMutableDictionary *mutableParametersDict = [NSMutableDictionary dictionaryWithDictionary:@{@"taxonomy": typeIdentifier}];
    NSArray *xmlrpcParameters = nil;
    if (parameters.count) {
        [mutableParametersDict addEntriesFromDictionary:parameters];
    }

    xmlrpcParameters = [self XMLRPCArgumentsWithExtraDefaults:@[termId] andExtra:mutableParametersDict];
    
    [self.api callMethod:@"wp.editTerm"
              parameters:xmlrpcParameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     if (![responseObject respondsToSelector:@selector(boolValue)]) {
                         NSString *message = [NSString stringWithFormat:@"Invalid response editing taxonomy of type: %@", typeIdentifier];
                         [self handleResponseErrorWithMessage:message method:@"wp.editTerm" failure:failure];
                         return;
                     }
                     success([responseObject boolValue]);
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
    tag.name = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCNameParameter];
    tag.slug = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCSlugParameter];
    tag.tagDescription = [xmlrpcDictionary stringForKey:TaxonomyXMLRPCDescriptionParameter];
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
