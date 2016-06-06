#import "BlogServiceRemoteXMLRPC.h"
#import "NSMutableDictionary+Helpers.h"
#import "WordPress-Swift.h"
#import "RemotePostType.h"

static NSString * const RemotePostTypeNameKey = @"name";
static NSString * const RemotePostTypeLabelKey = @"label";
static NSString * const RemotePostTypePublicKey = @"public";

@implementation BlogServiceRemoteXMLRPC

- (void)checkMultiAuthorWithSuccess:(void(^)(BOOL isMultiAuthor))success
                            failure:(void (^)(NSError *error))failure
{
    NSDictionary *filter = @{@"who":@"authors"};
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:filter];
    [self.api callMethod:@"wp.getUsers"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *response) {
                     if (success) {
                         NSArray *response = (NSArray *)responseObject;
                         BOOL isMultiAuthor = [response count] > 1;
                         success(isMultiAuthor);
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *response) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)syncOptionsWithSuccess:(OptionsHandler)success failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [self defaultXMLRPCArguments];
    [self.api callMethod:@"wp.getOptions"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *response) {
                     NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");

                     if (success) {
                         success(responseObject);
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *response) {
                     DDLogError(@"Error syncing options: %@", error);

                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)syncPostTypesWithSuccess:(PostTypesHandler)success failure:(void (^)(NSError *error))failure
{
    NSArray *parameters = [self defaultXMLRPCArguments];
    [self.api callMethod:@"wp.getPostTypes"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *response) {

                     NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");
                     NSArray <RemotePostType *> *postTypes = [[responseObject allObjects] wp_map:^id(NSDictionary *json) {
                         return [self remotePostTypeFromXMLRPCDictionary:json];
                     }];
                     if (!postTypes.count) {
                         DDLogError(@"Response to %@ did not include post types for site.", @"wp.getPostTypes");
                         failure(nil);
                         return;
                     }
                     if (success) {
                         success(postTypes);
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *response) {
                     DDLogError(@"Error syncing post types (%@): %@", response.URL, error);
                     
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)syncPostFormatsWithSuccess:(PostFormatsHandler)success failure:(void (^)(NSError *))failure
{
    NSDictionary *dict = @{@"show-supported": @"1"};
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:dict];

    [self.api callMethod:@"wp.getPostFormats"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *response) {
                     NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");

                     NSDictionary *postFormats = responseObject;
                     NSDictionary *respDict = responseObject;
                     if ([postFormats objectForKey:@"supported"]) {
                         NSMutableArray *supportedKeys;
                         if ([[postFormats objectForKey:@"supported"] isKindOfClass:[NSArray class]]) {
                             supportedKeys = [NSMutableArray arrayWithArray:[postFormats objectForKey:@"supported"]];
                         } else if ([[postFormats objectForKey:@"supported"] isKindOfClass:[NSDictionary class]]) {
                             supportedKeys = [NSMutableArray arrayWithArray:[[postFormats objectForKey:@"supported"] allValues]];
                         }

                         // Standard isn't included in the list of supported formats? Maybe it will be one day?
                         if (![supportedKeys containsObject:@"standard"]) {
                             [supportedKeys addObject:@"standard"];
                         }

                         NSDictionary *allFormats = [postFormats objectForKey:@"all"];
                         NSMutableArray *supportedValues = [NSMutableArray array];
                         for (NSString *key in supportedKeys) {
                             [supportedValues addObject:[allFormats objectForKey:key]];
                         }
                         respDict = [NSDictionary dictionaryWithObjects:supportedValues forKeys:supportedKeys];
                     }
                     
                     if (success) {
                         success(respDict);
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *response) {
                     DDLogError(@"Error syncing post formats (%@): %@", response.URL, error);
                     
                     if (failure) {
                         failure(error);
                     }
                 }];

}

- (void)syncSettingsWithSuccess:(SettingsHandler)success
                    failure:(void (^)(NSError *error))failure
{
    NSArray *parameters = [self defaultXMLRPCArguments];
    [self.api callMethod:@"wp.getOptions" parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *response) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (failure) {
                failure(nil);
            }
            return;
        }
        NSDictionary *XMLRPCDictionary = (NSDictionary *)responseObject;
        RemoteBlogSettings *remoteSettings = [self remoteBlogSettingFromXMLRPCDictionary:XMLRPCDictionary];
        if (success) {
            success(remoteSettings);
        }
    } failure:^(NSError *error, NSHTTPURLResponse *response) {
        DDLogError(@"Error syncing settings: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updateBlogSettings:(RemoteBlogSettings *)remoteBlogSettings
                   success:(SuccessHandler)success
                   failure:(void (^)(NSError *error))failure
{
    NSMutableDictionary *rawParameters = [NSMutableDictionary dictionary];    
    [rawParameters setValueIfNotNil:remoteBlogSettings.name forKey:@"blog_title"];
    [rawParameters setValueIfNotNil:remoteBlogSettings.tagline forKey:@"blog_tagline"];
    
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:rawParameters];
    
    [self.api callMethod:@"wp.setOptions" parameters:parameters success:^(id responseObject, NSHTTPURLResponse *response) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (failure) {
                failure(nil);
            }
            return;
        }
        NSDictionary *XMLRPCDictionary = (NSDictionary *)responseObject;
        RemoteBlogSettings *remoteSettings = [self remoteBlogSettingFromXMLRPCDictionary:XMLRPCDictionary];
        if (success) {
            success(remoteSettings);
        }
    } failure:^(NSError *error, NSHTTPURLResponse *response) {
        DDLogError(@"Error syncing settings: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

- (RemotePostType *)remotePostTypeFromXMLRPCDictionary:(NSDictionary *)json
{
    RemotePostType *postType = [[RemotePostType alloc] init];
    postType.name = [json stringForKey:RemotePostTypeNameKey];
    postType.label = [json stringForKey:RemotePostTypeLabelKey];
    postType.apiQueryable = [json numberForKey:RemotePostTypePublicKey];
    return postType;
}

- (RemoteBlogSettings *)remoteBlogSettingFromXMLRPCDictionary:(NSDictionary *)json
{
    RemoteBlogSettings *remoteSettings = [RemoteBlogSettings new];
    
    remoteSettings.name = [[json stringForKeyPath:@"blog_title.value"] stringByDecodingXMLCharacters];
    remoteSettings.tagline = [[json stringForKeyPath:@"blog_tagline.value"] stringByDecodingXMLCharacters];
    if (json[@"blog_public"]) {
        remoteSettings.privacy = [json numberForKeyPath:@"blog_public.value"];
    }
    return remoteSettings;
}

@end
