#import "BlogServiceRemoteREST.h"
#import "NSMutableDictionary+Helpers.h"
#import "WordPressComApi.h"
#import "WordPress-Swift.h"


#pragma mark - Parsing Keys
static NSString * const RemoteBlogNameKey                                   = @"name";
static NSString * const RemoteBlogTaglineKey                                = @"description";
static NSString * const RemoteBlogPrivacyKey                                = @"blog_public";

static NSString * const RemoteBlogSettingsKey                               = @"settings";
static NSString * const RemoteBlogDefaultCategoryKey                        = @"default_category";
static NSString * const RemoteBlogDefaultPostFormatKey                      = @"default_post_format";
static NSString * const RemoteBlogCommentsAllowedKey                        = @"default_comment_status";
static NSString * const RemoteBlogCommentsBlacklistKeys                     = @"blacklist_keys";
static NSString * const RemoteBlogCommentsCloseAutomaticallyKey             = @"close_comments_for_old_posts";
static NSString * const RemoteBlogCommentsCloseAutomaticallyAfterDaysKey    = @"close_comments_days_old";
static NSString * const RemoteBlogCommentsKnownUsersWhitelistKey            = @"comment_whitelist";
static NSString * const RemoteBlogCommentsMaxLinksKey                       = @"comment_max_links";
static NSString * const RemoteBlogCommentsModerationKeys                    = @"moderation_keys";
static NSString * const RemoteBlogCommentsPagingEnabledKey                  = @"page_comments";
static NSString * const RemoteBlogCommentsPageSizeKey                       = @"comments_per_page";
static NSString * const RemoteBlogCommentsRequireModerationKey              = @"comment_moderation";
static NSString * const RemoteBlogCommentsRequireNameAndEmailKey            = @"require_name_email";
static NSString * const RemoteBlogCommentsRequireRegistrationKey            = @"comment_registration";
static NSString * const RemoteBlogCommentsSortOrderKey                      = @"comment_order";
static NSString * const RemoteBlogCommentsThreadingEnabledKey               = @"thread_comments";
static NSString * const RemoteBlogCommentsThreadingDepthKey                 = @"thread_comments_depth";
static NSString * const RemoteBlogCommentsPingbackOutboundKey               = @"default_pingback_flag";
static NSString * const RemoteBlogCommentsPingbackInboundKey                = @"default_ping_status";
static NSString * const RemoteBlogRelatedPostsAllowedKey                    = @"jetpack_relatedposts_allowed";
static NSString * const RemoteBlogRelatedPostsEnabledKey                    = @"jetpack_relatedposts_enabled";
static NSString * const RemoteBlogRelatedPostsShowHeadlineKey               = @"jetpack_relatedposts_show_headline";
static NSString * const RemoteBlogRelatedPostsShowThumbnailsKey             = @"jetpack_relatedposts_show_thumbnails";

#pragma mark - Keys used for Update Calls
// Note: Only god knows why these don't match the "Parsing Keys"
static NSString * const RemoteBlogNameForUpdateKey                          = @"blogname";
static NSString * const RemoteBlogTaglineForUpdateKey                       = @"blogdescription";

#pragma mark - Defaults
static NSString * const RemoteBlogDefaultPostFormat                         = @"standard";
static NSInteger const RemoteBlogUncategorizedCategory                      = 1;



@implementation BlogServiceRemoteREST

- (void)checkMultiAuthorWithSuccess:(void(^)(BOOL isMultiAuthor))success
                            failure:(void (^)(NSError *error))failure
{
    NSDictionary *parameters = @{@"authors_only":@(YES)};
    
    NSString *path = [self pathForUsers];
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

- (void)syncOptionsWithSuccess:(OptionsHandler)success
                       failure:(void (^)(NSError *))failure
{
    NSString *path = [self pathForOptions];
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

- (void)syncPostFormatsWithSuccess:(PostFormatsHandler)success
                           failure:(void (^)(NSError *))failure
{
    NSString *path = [self pathForPostFormats];
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

- (void)syncSettingsWithSuccess:(SettingsHandler)success
                        failure:(void (^)(NSError *error))failure
{
    NSString *path = [self pathForSettings];
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
              RemoteBlogSettings *remoteSettings = [self remoteBlogSettingFromJSONDictionary:responseObject];
              if (success) {
                  success(remoteSettings);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)updateBlogSettings:(RemoteBlogSettings *)settings
                   success:(SuccessHandler)success
                   failure:(void (^)(NSError *error))failure;
{
    NSParameterAssert(settings);

    NSDictionary *parameters = [self remoteSettingsToDictionary:settings];
    NSString *path = [NSString stringWithFormat:@"sites/%@/settings?context=edit", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, NSDictionary *responseDict) {
               if (![responseDict isKindOfClass:[NSDictionary class]]) {
                   if (failure) {
                       failure(nil);
                   }
                   return;
               }
               if (!responseDict[@"updated"]) {
                   if (failure) {
                       failure(nil);
                   }
               } else if (success) {
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

- (NSString *)pathForUsers
{
    return [NSString stringWithFormat:@"sites/%@/users", self.siteID];
}

- (NSString *)pathForOptions
{
    return [NSString stringWithFormat:@"sites/%@", self.siteID];
}

- (NSString *)pathForPostFormats
{
    return [NSString stringWithFormat:@"sites/%@/post-formats", self.siteID];
}

- (NSString *)pathForSettings
{
    return [NSString stringWithFormat:@"sites/%@/settings", self.siteID];
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
    NSAssert([json isKindOfClass:[NSDictionary class]], @"Invalid Settings Kind");
    
    RemoteBlogSettings *settings = [RemoteBlogSettings new];
    NSDictionary *rawSettings = [json dictionaryForKey:RemoteBlogSettingsKey];
    
    // General
    settings.name = [json stringForKey:RemoteBlogNameKey];
    settings.tagline = [json stringForKey:RemoteBlogTaglineKey];
    settings.privacy = [rawSettings numberForKey:RemoteBlogPrivacyKey];
    
    // Writing
    settings.defaultCategoryID = [rawSettings numberForKey:RemoteBlogDefaultCategoryKey] ?: @(RemoteBlogUncategorizedCategory);

    // Note: the backend might send '0' as a number, OR a string value. Ref. Issue #4187
    if ([[rawSettings numberForKey:RemoteBlogDefaultPostFormatKey] isEqualToNumber:@(0)] ||
        [[rawSettings stringForKey:RemoteBlogDefaultPostFormatKey] isEqualToString:@"0"])
    {
        settings.defaultPostFormat = RemoteBlogDefaultPostFormat;
    } else {
        settings.defaultPostFormat = [rawSettings stringForKey:RemoteBlogDefaultPostFormatKey];
    }
    
    // Discussion
    settings.commentsAllowed = [rawSettings numberForKey:RemoteBlogCommentsAllowedKey];
    settings.commentsBlacklistKeys = [rawSettings stringForKey:RemoteBlogCommentsBlacklistKeys];
    settings.commentsCloseAutomatically = [rawSettings numberForKey:RemoteBlogCommentsCloseAutomaticallyKey];
    settings.commentsCloseAutomaticallyAfterDays = [rawSettings numberForKey:RemoteBlogCommentsCloseAutomaticallyAfterDaysKey];
    settings.commentsFromKnownUsersWhitelisted = [rawSettings numberForKey:RemoteBlogCommentsKnownUsersWhitelistKey];
    settings.commentsMaximumLinks = [rawSettings numberForKey:RemoteBlogCommentsMaxLinksKey];
    settings.commentsModerationKeys = [rawSettings stringForKey:RemoteBlogCommentsModerationKeys];
    settings.commentsPagingEnabled = [rawSettings numberForKey:RemoteBlogCommentsPagingEnabledKey];
    settings.commentsPageSize = [rawSettings numberForKey:RemoteBlogCommentsPageSizeKey];
    settings.commentsRequireManualModeration = [rawSettings numberForKey:RemoteBlogCommentsRequireModerationKey];
    settings.commentsRequireNameAndEmail = [rawSettings numberForKey:RemoteBlogCommentsRequireNameAndEmailKey];
    settings.commentsRequireRegistration = [rawSettings numberForKey:RemoteBlogCommentsRequireRegistrationKey];
    settings.commentsSortOrder = [rawSettings stringForKey:RemoteBlogCommentsSortOrderKey];
    settings.commentsThreadingEnabled = [rawSettings numberForKey:RemoteBlogCommentsThreadingEnabledKey];
    settings.commentsThreadingDepth = [rawSettings numberForKey:RemoteBlogCommentsThreadingDepthKey];
    settings.pingbackOutboundEnabled = [rawSettings numberForKey:RemoteBlogCommentsPingbackOutboundKey];
    settings.pingbackInboundEnabled = [rawSettings numberForKey:RemoteBlogCommentsPingbackInboundKey];
    
    
    // Related Posts
    settings.relatedPostsAllowed = [rawSettings numberForKey:RemoteBlogRelatedPostsAllowedKey];
    settings.relatedPostsEnabled = [rawSettings numberForKey:RemoteBlogRelatedPostsEnabledKey];
    settings.relatedPostsShowHeadline = [rawSettings numberForKey:RemoteBlogRelatedPostsShowHeadlineKey];
    settings.relatedPostsShowThumbnails = [rawSettings numberForKey:RemoteBlogRelatedPostsShowThumbnailsKey];
    
    return settings;
}

- (NSDictionary *)remoteSettingsToDictionary:(RemoteBlogSettings *)settings
{
    NSParameterAssert(settings);
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [parameters setValueIfNotNil:settings.name forKey:RemoteBlogNameForUpdateKey];
    [parameters setValueIfNotNil:settings.tagline forKey:RemoteBlogTaglineForUpdateKey];
    [parameters setValueIfNotNil:settings.privacy forKey:RemoteBlogPrivacyKey];

    [parameters setValueIfNotNil:settings.defaultCategoryID forKey:RemoteBlogDefaultCategoryKey];
    [parameters setValueIfNotNil:settings.defaultPostFormat forKey:RemoteBlogDefaultPostFormatKey];
    
    [parameters setValueIfNotNil:settings.commentsAllowed forKey:RemoteBlogCommentsAllowedKey];
    [parameters setValueIfNotNil:settings.commentsBlacklistKeys forKey:RemoteBlogCommentsBlacklistKeys];
    [parameters setValueIfNotNil:settings.commentsCloseAutomatically forKey:RemoteBlogCommentsCloseAutomaticallyKey];
    [parameters setValueIfNotNil:settings.commentsCloseAutomaticallyAfterDays forKey:RemoteBlogCommentsCloseAutomaticallyAfterDaysKey];
    [parameters setValueIfNotNil:settings.commentsFromKnownUsersWhitelisted forKey:RemoteBlogCommentsKnownUsersWhitelistKey];
    [parameters setValueIfNotNil:settings.commentsMaximumLinks forKey:RemoteBlogCommentsMaxLinksKey];
    [parameters setValueIfNotNil:settings.commentsModerationKeys forKey:RemoteBlogCommentsModerationKeys];
    [parameters setValueIfNotNil:settings.commentsPagingEnabled forKey:RemoteBlogCommentsPagingEnabledKey];
    [parameters setValueIfNotNil:settings.commentsPageSize forKey:RemoteBlogCommentsPageSizeKey];
    [parameters setValueIfNotNil:settings.commentsRequireManualModeration forKey:RemoteBlogCommentsRequireModerationKey];
    [parameters setValueIfNotNil:settings.commentsRequireNameAndEmail forKey:RemoteBlogCommentsRequireNameAndEmailKey];
    [parameters setValueIfNotNil:settings.commentsRequireRegistration forKey:RemoteBlogCommentsRequireRegistrationKey];
    [parameters setValueIfNotNil:settings.commentsSortOrder forKey:RemoteBlogCommentsSortOrderKey];
    [parameters setValueIfNotNil:settings.commentsThreadingEnabled forKey:RemoteBlogCommentsThreadingEnabledKey];
    [parameters setValueIfNotNil:settings.commentsThreadingDepth forKey:RemoteBlogCommentsThreadingDepthKey];
    
    [parameters setValueIfNotNil:settings.pingbackOutboundEnabled forKey:RemoteBlogCommentsPingbackOutboundKey];
    [parameters setValueIfNotNil:settings.pingbackInboundEnabled forKey:RemoteBlogCommentsPingbackInboundKey];
    
    [parameters setValueIfNotNil:settings.relatedPostsEnabled forKey:RemoteBlogRelatedPostsEnabledKey];
    [parameters setValueIfNotNil:settings.relatedPostsShowHeadline forKey:RemoteBlogRelatedPostsShowHeadlineKey];
    [parameters setValueIfNotNil:settings.relatedPostsShowThumbnails forKey:RemoteBlogRelatedPostsShowThumbnailsKey];
    
    return parameters;
}

@end
