#import "BlogServiceRemoteREST.h"
#import <WordPressComApi.h>
#import "Blog.h"
#import "PostCategory.h"
#import "RemoteBlogSettings.h"


static NSString const *BlogRemoteNameKey                = @"name";
static NSString const *BlogRemoteDescriptionKey         = @"description";
static NSString const *BlogRemoteSettingsKey            = @"settings";
static NSString const *BlogRemoteDefaultCategoryKey     = @"default_category";
static NSString const *BlogRemoteDefaultPostFormatKey   = @"default_post_format";


@implementation BlogServiceRemoteREST

- (void)checkMultiAuthorForBlog:(Blog *)blog
                        success:(void(^)(BOOL isMultiAuthor))success
                        failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert(blog.dotComID != nil);
    
    NSDictionary *parameters = @{@"authors_only":@(YES)};
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/users", blog.dotComID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  NSDictionary *response = (NSDictionary *)responseObject;
                  BOOL isMultiAuthor = [[response arrayForKey:@"users"] count] > 1;
                  success(isMultiAuthor);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(OptionsHandler)success
                   failure:(void (^)(NSError *))failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert(blog.dotComID != nil);
    
    NSString *path = [self pathForOptionsWithBlog:blog];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *response = (NSDictionary *)responseObject;
              NSDictionary *options = [self mapOptionsFromResponse:response];
              if (success) {
                  success(options);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(PostFormatsHandler)success
                       failure:(void (^)(NSError *))failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert(blog.dotComID != nil);
    
    NSString *path = [self pathForPostFormatsWithBlog:blog];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *formats = [self mapPostFormatsFromResponse:responseObject[@"formats"]];
              if (success) {
                  success(formats);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)syncSettingsForBlog:(Blog *)blog
                    success:(SettingsHandler)success
                    failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert(blog.dotComID != nil);
    
    NSString *path = [self pathForSettingsWithBlog:blog];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (![responseObject isKindOfClass:[NSDictionary class]]){
                  if (failure) {
                      failure(nil);
                  }
              }
              NSDictionary *jsonDictionary = (NSDictionary *)responseObject;
              RemoteBlogSettings *remoteSettings = [self remoteBlogSettingFromJSONDictionary:jsonDictionary];
              if (success) {
                  success(remoteSettings);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)updateSettingsForBlog:(Blog *)blog
                      success:(SuccessHandler)success
                      failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSDictionary *parameters = @{ @"blogname" : blog.blogName,
                                  @"blogdescription" : blog.blogTagline,
                                  @"default_category" : blog.defaultCategoryID,
                                  @"default_post_format" : blog.defaultPostFormat
                                  };
    NSString *path = [NSString stringWithFormat:@"sites/%@/settings?context=edit", blog.dotComID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (![responseObject isKindOfClass:[NSDictionary class]]) {
                   if (failure) {
                       failure(nil);
                   }
               }
               NSDictionary *jsonDictionary = (NSDictionary *)responseObject;
               if (!jsonDictionary[@"updated"]) {
                   if (failure) {
                       failure(nil);
                   }
               }
               if (success) {
                   success();
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

#pragma mark - API paths

- (NSString *)pathForOptionsWithBlog:(Blog *)blog
{
    return [NSString stringWithFormat:@"sites/%@", blog.dotComID];
}

- (NSString *)pathForPostFormatsWithBlog:(Blog *)blog
{
    return [NSString stringWithFormat:@"sites/%@/post-formats", blog.dotComID];
}

- (NSString *)pathForSettingsWithBlog:(Blog *)blog
{
    return [NSString stringWithFormat:@"sites/%@/settings", blog.dotComID];
}


#pragma mark - Mapping methods

- (NSDictionary *)mapOptionsFromResponse:(NSDictionary *)response
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[@"home_url"] = response[@"URL"];
    // We'd be better off saving this as a BOOL property on Blog, but let's do what XML-RPC does for now
    options[@"blog_public"] = [[response numberForKey:@"is_private"] boolValue] ? @"-1" : @"0";
    if ([[response numberForKey:@"jetpack"] boolValue]) {
        options[@"jetpack_client_id"] = [response numberForKey:@"ID"];
    }
    if ( response[@"options"] ) {
        options[@"post_thumbnail"] = [response valueForKeyPath:@"options.featured_images_enabled"];
        NSArray *optionsDirectMapKeys = @[
                                    @"admin_url",
                                    @"login_url",
                                    @"image_default_link_type",
                                    @"software_version",
                                    @"videopress_enabled",
                                    @"timezone",
                                    @"gmt_offset",
                                    @"allowed_file_types",
                                    ];

        for (NSString *key in optionsDirectMapKeys) {
            NSString *sourceKeyPath = [NSString stringWithFormat:@"options.%@", key];
            if ([response valueForKeyPath:sourceKeyPath] != nil) {
                options[key] = [response valueForKeyPath:sourceKeyPath];
            }
        }
    } else {
        //valid default values
        options[@"software_version"] = @"3.6";
    }
    NSMutableDictionary *valueOptions = [NSMutableDictionary dictionaryWithCapacity:options.count];
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        valueOptions[key] = @{@"value": obj};
    }];

    return [NSDictionary dictionaryWithDictionary:valueOptions ];
}

- (NSDictionary *)mapPostFormatsFromResponse:(id)response
{
    if ([response isKindOfClass:[NSDictionary class]]) {
        return response;
    } else {
        return @{};
    }
}

- (RemoteBlogSettings *)remoteBlogSettingFromJSONDictionary:(NSDictionary *)json
{
    NSDictionary *rawSettings = [json dictionaryForKey:BlogRemoteSettingsKey];
    
    RemoteBlogSettings *remoteSettings = [RemoteBlogSettings new];
    
    remoteSettings.name = [json stringForKey:BlogRemoteNameKey];
    remoteSettings.desc = [json stringForKey:BlogRemoteDescriptionKey];
    remoteSettings.defaultCategory = [rawSettings numberForKey:BlogRemoteDefaultCategoryKey] ?: @(PostCategoryUncategorized);

    // Note:
    // YES, the backend might send '0' as a number, OR a string value.
    // Reference: https://github.com/wordpress-mobile/WordPress-iOS/issues/4187
    //
    if ([[rawSettings numberForKey:BlogRemoteDefaultPostFormatKey] isEqualToNumber:@(0)] ||
        [[rawSettings stringForKey:BlogRemoteDefaultPostFormatKey] isEqualToString:@"0"]) {
        remoteSettings.defaultPostFormat = PostFormatStandard;
    } else {
        remoteSettings.defaultPostFormat = [rawSettings stringForKey:BlogRemoteDefaultPostFormatKey];
    }
    
    return remoteSettings;
}

@end
