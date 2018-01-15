#import <Foundation/Foundation.h>
#import "BlogServiceRemoteREST.h"
#import "NSMutableDictionary+Helpers.h"
#import "RemotePostType.h"
#import "Logging.h"
#import <WordPressKit/WordPressKit-Swift.h>
@import NSObject_SafeExpectations;
@import WordPressShared;

#pragma mark - Parsing Keys
static NSString * const RemoteBlogNameKey                                   = @"name";
static NSString * const RemoteBlogTaglineKey                                = @"description";
static NSString * const RemoteBlogPrivacyKey                                = @"blog_public";
static NSString * const RemoteBlogLanguageKey                               = @"lang_id";
static NSString * const RemoteBlogIconKey                                   = @"site_icon";

static NSString * const RemoteBlogSettingsKey                               = @"settings";
static NSString * const RemoteBlogDefaultCategoryKey                        = @"default_category";
static NSString * const RemoteBlogDefaultPostFormatKey                      = @"default_post_format";
static NSString * const RemoteBlogDateFormatKey                             = @"date_format";
static NSString * const RemoteBlogTimeFormatKey                             = @"time_format";
static NSString * const RemoteBlogStartOfWeekKey                            = @"start_of_week";
static NSString * const RemoteBlogPostsPerPageKey                           = @"posts_per_page";
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
static NSString * const RemoteBlogAmpSupportedKey                           = @"amp_is_supported";
static NSString * const RemoteBlogAmpEnabledKey                             = @"amp_is_enabled";

static NSString * const RemoteBlogSharingButtonStyle                        = @"sharing_button_style";
static NSString * const RemoteBlogSharingLabel                              = @"sharing_label";
static NSString * const RemoteBlogSharingTwitterName                        = @"twitter_via";
static NSString * const RemoteBlogSharingCommentLikesEnabled                = @"jetpack_comment_likes_enabled";
static NSString * const RemoteBlogSharingDisabledLikes                      = @"disabled_likes";
static NSString * const RemoteBlogSharingDisabledReblogs                    = @"disabled_reblogs";

static NSString * const RemotePostTypesKey                                  = @"post_types";
static NSString * const RemotePostTypeNameKey                               = @"name";
static NSString * const RemotePostTypeLabelKey                              = @"label";
static NSString * const RemotePostTypeQueryableKey                          = @"api_queryable";

#pragma mark - Keys used for Update Calls
// Note: Only god knows why these don't match the "Parsing Keys"
static NSString * const RemoteBlogNameForUpdateKey                          = @"blogname";
static NSString * const RemoteBlogTaglineForUpdateKey                       = @"blogdescription";

#pragma mark - Defaults
static NSString * const RemoteBlogDefaultPostFormat                         = @"standard";
static NSInteger const RemoteBlogUncategorizedCategory                      = 1;



@implementation BlogServiceRemoteREST

- (void)getAuthorsWithSuccess:(UsersHandler)success
                      failure:(void (^)(NSError *error))failure
{
    NSDictionary *parameters = @{@"authors_only":@(YES)};

    NSString *path = [self pathForUsers];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [self.wordPressComRestApi GET:requestUrl
                       parameters:parameters
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              if (success) {
                                  NSArray *users = [self usersFromJSONArray:responseObject[@"users"]];
                                  success(users);
                              }
                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                              if (failure) {
                                  failure(error);
                              }
                          }];
}

- (void)syncPostTypesWithSuccess:(PostTypesHandler)success
                         failure:(void (^)(NSError *error))failure
{
    NSString *path = [self pathForPostTypes];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    NSDictionary *parameters = @{@"context": @"edit"};
    [self.wordPressComRestApi GET:requestUrl
       parameters:parameters
          success:^(NSDictionary *responseObject, NSHTTPURLResponse *httpResponse) {
             
              NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");
              NSArray <RemotePostType *> *postTypes = [[responseObject arrayForKey:RemotePostTypesKey] wp_map:^id(NSDictionary *json) {
                  return [self remotePostTypeWithDictionary:json];
              }];
              if (!postTypes.count) {
                  DDLogError(@"Response to %@ did not include post types for site.", requestUrl);
                  failure(nil);
                  return;
              }
              if (success) {
                  success(postTypes);
              }
          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi GET:requestUrl
       parameters:nil
          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
              NSDictionary *formats = [self mapPostFormatsFromResponse:responseObject[@"formats"]];
              if (success) {
                  success(formats);
              }
          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)syncBlogWithSuccess:(BlogDetailsHandler)success
                    failure:(void (^)(NSError *))failure
{
    NSString *path = [self pathForSite];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [self.wordPressComRestApi GET:requestUrl
                       parameters:nil
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              NSDictionary *responseDict = (NSDictionary *)responseObject;
                              RemoteBlog *remoteBlog = [[RemoteBlog alloc] initWithJSONDictionary:responseDict];
                              if (success) {
                                  success(remoteBlog);
                              }
                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                              if (failure) {
                                  failure(error);
                              }
                          }];
}

- (void)syncBlogSettingsWithSuccess:(SettingsHandler)success
                        failure:(void (^)(NSError *error))failure
{
    NSString *path = [self pathForSettings];
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi GET:requestUrl
       parameters:nil
          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
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
          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi POST:requestUrl
        parameters:parameters
           success:^(NSDictionary *responseDict, NSHTTPURLResponse *httpResponse) {
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
           failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)fetchSiteInfoForAddress:(NSString *)siteAddress
                        success:(void(^)(NSDictionary *siteInfoDict))success
                        failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@", siteAddress];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [self.wordPressComRestApi GET:requestUrl
                       parameters:nil
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              if (success) {
                                  success((NSDictionary *)responseObject);
                                  return;
                              }
                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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

- (NSString *)pathForSite
{
    return [NSString stringWithFormat:@"sites/%@", self.siteID];
}

- (NSString *)pathForPostTypes
{
    return [NSString stringWithFormat:@"sites/%@/post-types", self.siteID];
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

- (NSArray *)usersFromJSONArray:(NSArray *)jsonUsers
{
    return [jsonUsers wp_map:^RemoteUser *(NSDictionary *jsonUser) {
        return [self userFromJSONDictionary:jsonUser];
    }];
}

- (RemoteUser *)userFromJSONDictionary:(NSDictionary *)jsonUser
{
    RemoteUser *user = [RemoteUser new];
    user.userID = jsonUser[@"ID"];
    user.username = jsonUser[@"login"];
    user.email = jsonUser[@"email"];
    user.displayName = jsonUser[@"name"];
    user.primaryBlogID = jsonUser[@"site_ID"];
    user.avatarURL = jsonUser[@"avatar_URL"];
    user.linkedUserID = jsonUser[@"linked_user_ID"];
    return user;
}

- (NSDictionary *)mapPostFormatsFromResponse:(id)response
{
    if ([response isKindOfClass:[NSDictionary class]]) {
        return response;
    } else {
        return @{};
    }
}

- (RemotePostType *)remotePostTypeWithDictionary:(NSDictionary *)json
{
    RemotePostType *postType = [[RemotePostType alloc] init];
    postType.name = [json stringForKey:RemotePostTypeNameKey];
    postType.label = [json stringForKey:RemotePostTypeLabelKey];
    postType.apiQueryable = [json numberForKey:RemotePostTypeQueryableKey];
    return postType;
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
    settings.languageID = [rawSettings numberForKey:RemoteBlogLanguageKey];
    settings.iconMediaID = [rawSettings numberForKey:RemoteBlogIconKey];

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
    settings.dateFormat = [rawSettings stringForKey:RemoteBlogDateFormatKey];
    settings.timeFormat = [rawSettings stringForKey:RemoteBlogTimeFormatKey];
    settings.startOfWeek = [rawSettings stringForKey:RemoteBlogStartOfWeekKey];
    settings.postsPerPage = [rawSettings numberForKey:RemoteBlogPostsPerPageKey];

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

    // AMP
    settings.ampSupported = [rawSettings numberForKey:RemoteBlogAmpSupportedKey];
    settings.ampEnabled = [rawSettings numberForKey:RemoteBlogAmpEnabledKey];

    // Sharing
    settings.sharingButtonStyle = [rawSettings stringForKey:RemoteBlogSharingButtonStyle];
    settings.sharingLabel = [rawSettings stringForKey:RemoteBlogSharingLabel];
    settings.sharingTwitterName = [rawSettings stringForKey:RemoteBlogSharingTwitterName];
    settings.sharingCommentLikesEnabled = [rawSettings numberForKey:RemoteBlogSharingCommentLikesEnabled];
    settings.sharingDisabledLikes = [rawSettings numberForKey:RemoteBlogSharingDisabledLikes];
    settings.sharingDisabledReblogs = [rawSettings numberForKey:RemoteBlogSharingDisabledReblogs];

    return settings;
}

- (NSDictionary *)remoteSettingsToDictionary:(RemoteBlogSettings *)settings
{
    NSParameterAssert(settings);
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [parameters setValueIfNotNil:settings.name forKey:RemoteBlogNameForUpdateKey];
    [parameters setValueIfNotNil:settings.tagline forKey:RemoteBlogTaglineForUpdateKey];
    [parameters setValueIfNotNil:settings.privacy forKey:RemoteBlogPrivacyKey];
    [parameters setValueIfNotNil:settings.languageID forKey:RemoteBlogLanguageKey];
    [parameters setValueIfNotNil:settings.iconMediaID forKey:RemoteBlogIconKey];

    [parameters setValueIfNotNil:settings.defaultCategoryID forKey:RemoteBlogDefaultCategoryKey];
    [parameters setValueIfNotNil:settings.defaultPostFormat forKey:RemoteBlogDefaultPostFormatKey];
    [parameters setValueIfNotNil:settings.dateFormat forKey:RemoteBlogDateFormatKey];
    [parameters setValueIfNotNil:settings.timeFormat forKey:RemoteBlogTimeFormatKey];
    [parameters setValueIfNotNil:settings.startOfWeek forKey:RemoteBlogStartOfWeekKey];
    [parameters setValueIfNotNil:settings.postsPerPage forKey:RemoteBlogPostsPerPageKey];

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

    [parameters setValueIfNotNil:settings.ampEnabled forKey:RemoteBlogAmpEnabledKey];

    // Sharing
    [parameters setValueIfNotNil:settings.sharingButtonStyle forKey:RemoteBlogSharingButtonStyle];
    [parameters setValueIfNotNil:settings.sharingLabel forKey:RemoteBlogSharingLabel];
    [parameters setValueIfNotNil:settings.sharingTwitterName forKey:RemoteBlogSharingTwitterName];
    [parameters setValueIfNotNil:settings.sharingCommentLikesEnabled forKey:RemoteBlogSharingCommentLikesEnabled];
    [parameters setValueIfNotNil:settings.sharingDisabledLikes forKey:RemoteBlogSharingDisabledLikes];
    [parameters setValueIfNotNil:settings.sharingDisabledReblogs forKey:RemoteBlogSharingDisabledReblogs];
    
    return parameters;
}

@end
