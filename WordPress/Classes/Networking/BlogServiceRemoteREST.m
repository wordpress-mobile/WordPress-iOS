#import "BlogServiceRemoteREST.h"
#import "NSMutableDictionary+Helpers.h"
#import <WordPressComApi.h>
#import "WordPress-Swift.h"


static NSString const *BlogRemoteNameKey                = @"name";
static NSString const *BlogRemoteDescriptionKey         = @"description";
static NSString const *BlogRemoteSettingsKey            = @"settings";
static NSString const *BlogRemoteDefaultCategoryKey     = @"default_category";
static NSString const *BlogRemoteDefaultPostFormatKey   = @"default_post_format";
static NSString * const BlogRemoteDefaultPostFormat = @"standard";
static NSInteger const BlogRemoteUncategorizedCategory = 1;

@implementation BlogServiceRemoteREST

- (void)checkMultiAuthorForBlogID:(NSNumber *)blogID
                          success:(void(^)(BOOL isMultiAuthor))success
                          failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([blogID isKindOfClass:[NSNumber class]]);
    
    NSDictionary *parameters = @{@"authors_only":@(YES)};
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/users", blogID];
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

- (void)syncOptionsForBlogID:(NSNumber *)blogID
                     success:(OptionsHandler)success
                     failure:(void (^)(NSError *))failure
{
    NSParameterAssert([blogID isKindOfClass:[NSNumber class]]);
    
    NSString *path = [self pathForOptionsWithBlogID:blogID];
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

- (void)syncPostFormatsForBlogID:(NSNumber *)blogID
                         success:(PostFormatsHandler)success
                         failure:(void (^)(NSError *))failure
{
    NSParameterAssert([blogID isKindOfClass:[NSNumber class]]);
    
    NSString *path = [self pathForPostFormatsWithBlogID:blogID];
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

- (void)syncSettingsForBlogID:(NSNumber *)blogID
                    success:(SettingsHandler)success
                    failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([blogID isKindOfClass:[NSNumber class]]);
    
    NSString *path = [self pathForSettingsWithBlogID:blogID];
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (![responseObject isKindOfClass:[NSDictionary class]]){
                  if (failure) {
                      failure(nil);
                  }
                  return;
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

- (void)updateBlogSettings:(RemoteBlogSettings *)remoteSettings
                 forBlogID:(NSNumber *)blogID
                   success:(SuccessHandler)success
                   failure:(void (^)(NSError *error))failure;
{
    NSParameterAssert(remoteSettings);
    NSParameterAssert([blogID isKindOfClass:[NSNumber class]]);
    
    NSMutableDictionary *parameters = [@{
        @"blogname"             : remoteSettings.name,
        @"blogdescription"      : remoteSettings.desc,
        @"default_category"     : remoteSettings.defaultCategory,
        @"default_post_format"  : remoteSettings.defaultPostFormat,
        @"blog_public"          : remoteSettings.privacy,
    } mutableCopy];

    if (remoteSettings.relatedPostsEnabled) {
        [parameters setValueIfNotNil:remoteSettings.relatedPostsEnabled         forKey:@"jetpack_relatedposts_enabled"];
        [parameters setValueIfNotNil:remoteSettings.relatedPostsShowHeadline    forKey:@"jetpack_relatedposts_show_headline"];
        [parameters setValueIfNotNil:remoteSettings.relatedPostsShowThumbnails  forKey:@"jetpack_relatedposts_show_thumbnails"];
    }
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/settings?context=edit", blogID];
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (![responseObject isKindOfClass:[NSDictionary class]]) {
                   if (failure) {
                       failure(nil);
                   }
                   return;
               }
               NSDictionary *jsonDictionary = (NSDictionary *)responseObject;
               if (!jsonDictionary[@"updated"]) {
                   if (failure) {
                       failure(nil);
                   }
               } else  if (success) {
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

- (NSString *)pathForOptionsWithBlogID:(NSNumber *)blogID
{
    return [NSString stringWithFormat:@"sites/%@", blogID];
}

- (NSString *)pathForPostFormatsWithBlogID:(NSNumber *)blogID
{
    return [NSString stringWithFormat:@"sites/%@/post-formats", blogID];
}

- (NSString *)pathForSettingsWithBlogID:(NSNumber *)blogID
{
    return [NSString stringWithFormat:@"sites/%@/settings", blogID];
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
    RemoteBlogSettings *settings = [RemoteBlogSettings new];
    
    // General
    settings.name = [json stringForKey:BlogRemoteNameKey];
    settings.desc = [json stringForKey:BlogRemoteDescriptionKey];
    settings.privacy = [rawSettings numberForKey:@"blog_public"];
    
    // Writing
    settings.defaultCategory = [rawSettings numberForKey:BlogRemoteDefaultCategoryKey] ?: @(BlogRemoteUncategorizedCategory);

    // Note: the backend might send '0' as a number, OR a string value. Ref. Issue #4187
    if ([[rawSettings numberForKey:BlogRemoteDefaultPostFormatKey] isEqualToNumber:@(0)] ||
        [[rawSettings stringForKey:BlogRemoteDefaultPostFormatKey] isEqualToString:@"0"])
    {
        settings.defaultPostFormat = BlogRemoteDefaultPostFormat;
    } else {
        settings.defaultPostFormat = [rawSettings stringForKey:BlogRemoteDefaultPostFormatKey];
    }
    
    // Discussion
    settings.commentsAllowed = [rawSettings numberForKey:@"default_comment_status"];
    settings.commentsCloseAutomatically = [rawSettings numberForKey:@"close_comments_for_old_posts"];
    settings.commentsCloseAutomaticallyAfterDays = [rawSettings numberForKey:@"close_comments_days_old"];
    
    settings.commentsPagingEnabled = [rawSettings numberForKey:@"page_comments"];
    settings.commentsPageSize = [rawSettings numberForKey:@"comments_per_page"];
    
    settings.commentsRequireManualModeration = [rawSettings numberForKey:@"comment_moderation"];
    settings.commentsRequireNameAndEmail = [rawSettings numberForKey:@"require_name_email"];
    settings.commentsRequireRegistration = [rawSettings numberForKey:@"comment_registration"];
    
    settings.commentsSortOrder = [rawSettings stringForKey:@"comment_order"];
    
    settings.commentsThreadingEnabled = [rawSettings numberForKey:@"thread_comments"];
    settings.commentsThreadingDepth = [rawSettings numberForKey:@"thread_comments_depth"];
    
    settings.pingbacksOutboundEnabled = [rawSettings numberForKey:@"default_pingback_flag"];
    settings.pingbacksInboundEnabled = [rawSettings numberForKey:@"default_ping_status"];
    
    
    // Related Posts
    settings.relatedPostsAllowed = [rawSettings numberForKey:@"jetpack_relatedposts_allowed"];
    settings.relatedPostsEnabled = [rawSettings numberForKey:@"jetpack_relatedposts_enabled"];
    settings.relatedPostsShowHeadline = [rawSettings numberForKey:@"jetpack_relatedposts_show_headline"];
    settings.relatedPostsShowThumbnails = [rawSettings numberForKey:@"jetpack_relatedposts_show_thumbnails"];
    
    return settings;
}

@end
