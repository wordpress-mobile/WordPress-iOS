#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "RemoteReaderSiteInfo.h"
#import "WordPressComApi.h"
#import "WordPress-Swift.h"

static NSString * const TopicMenuSectionDefaultKey = @"default";
static NSString * const TopicMenuSectionSubscribedKey = @"subscribed";
static NSString * const TopicMenuSectionRecommendedKey = @"recommended";
static NSString * const TopicRemovedTagKey = @"removed_tag";
static NSString * const TopicAddedTagKey = @"added_tag";
static NSString * const TopicDictionaryIDKey = @"ID";
static NSString * const TopicDictionaryOwnerKey = @"owner";
static NSString * const TopicDictionarySlugKey = @"slug";
static NSString * const TopicDictionaryTagKey = @"tag";
static NSString * const TopicDictionaryTitleKey = @"title";
static NSString * const TopicDictionaryURLKey = @"URL";
static NSString * const TopicNotFoundMarker = @"-notfound-";

// Site Topic Keys
static NSString * const SiteDictionaryFeedIDKey = @"feed_ID";
static NSString * const SiteDictionaryFollowingKey = @"is_following";
static NSString * const SiteDictionaryJetpackKey = @"is_jetpack";
static NSString * const SiteDictionaryPrivateKey = @"is_private";
static NSString * const SiteDictionaryVisibleKey = @"visible";
static NSString * const SiteDictionaryPostCountKey = @"post_count";
static NSString * const SiteDictionaryIconPathKey = @"icon.img";
static NSString * const SiteDictionaryDescriptionKey = @"description";
static NSString * const SiteDictionaryIDKey = @"ID";
static NSString * const SiteDictionaryNameKey = @"name";
static NSString * const SiteDictionaryURLKey = @"URL";
static NSString * const SiteDictionarySubscriptionsKey = @"subscribers_count";


@implementation ReaderTopicServiceRemote

- (void)fetchReaderMenuWithSuccess:(void (^)(NSArray *topics))success failure:(void (^)(NSError *error))failure
{
    NSString *path = @"read/menu";
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_2];

    [self.api GET:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        if (!success) {
            return;
        }

        // Normalize and flatten the results.
        // A topic can appear in both recommended and subscribed dictionaries,
        // so filter appropriately.
        NSMutableArray *topics = [NSMutableArray array];

        NSDictionary *defaults = [response dictionaryForKey:TopicMenuSectionDefaultKey];
        NSMutableDictionary *subscribed = [[response dictionaryForKey:TopicMenuSectionSubscribedKey] mutableCopy];
        NSMutableDictionary *recommended = [[response dictionaryForKey:TopicMenuSectionRecommendedKey] mutableCopy];
        NSArray *subscribedAndRecommended;

        NSMutableSet *subscribedSet = [NSMutableSet setWithArray:[subscribed allKeys]];
        NSSet *recommendedSet = [NSSet setWithArray:[recommended allKeys]];
        [subscribedSet intersectSet:recommendedSet];
        NSArray *sharedkeys = [subscribedSet allObjects];

        if (sharedkeys) {
            subscribedAndRecommended = [subscribed objectsForKeys:sharedkeys notFoundMarker:TopicNotFoundMarker];
            [subscribed removeObjectsForKeys:sharedkeys];
            [recommended removeObjectsForKeys:sharedkeys];
        }

        [topics addObjectsFromArray:[self normalizeMenuTopicsList:[defaults allValues] subscribed:NO recommended:NO]];
        [topics addObjectsFromArray:[self normalizeMenuTopicsList:[subscribed allValues] subscribed:YES recommended:NO]];
        [topics addObjectsFromArray:[self normalizeMenuTopicsList:[recommended allValues] subscribed:NO recommended:YES]];
        [topics addObjectsFromArray:[self normalizeMenuTopicsList:subscribedAndRecommended subscribed:YES recommended:YES]];

        success(topics);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowTopicWithSlug:(NSString *)slug
                  withSuccess:(void (^)(NSNumber *topicID))success
                      failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"read/tags/%@/mine/delete", slug];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];

    [self.api POST:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        if (!success) {
            return;
        }
        NSNumber *unfollowedTag = [responseObject numberForKey:TopicRemovedTagKey];
        success(unfollowedTag);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followTopicNamed:(NSString *)topicName
             withSuccess:(void (^)(NSNumber *topicID))success
                 failure:(void (^)(NSError *error))failure
{
    NSString *slug = [self slugForTopicName:topicName];
    [self followTopicWithSlug:slug withSuccess:success failure:failure];
}

- (void)followTopicWithSlug:(NSString *)slug
             withSuccess:(void (^)(NSNumber *topicID))success
                 failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"read/tags/%@/mine/new", slug];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];

    [self.api POST:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }
        NSNumber *followedTag = [responseObject numberForKey:TopicAddedTagKey];
        success(followedTag);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)fetchTagInfoForTagWithSlug:(NSString *)slug
                           success:(void (^)(RemoteReaderTopic *remoteTopic))success
                           failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"read/tags/%@", slug];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];

    [self.api GET:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }

        NSDictionary *response = (NSDictionary *)responseObject;
        NSDictionary *topicDict = [response dictionaryForKey:TopicDictionaryTagKey];
        RemoteReaderTopic *remoteTopic = [self normalizeMenuTopicDictionary:topicDict subscribed:NO recommended:NO];
        remoteTopic.isMenuItem = NO;
        success(remoteTopic);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)fetchSiteInfoForSiteWithID:(NSNumber *)siteID
                            isFeed:(BOOL)isFeed
                           success:(void (^)(RemoteReaderSiteInfo *siteInfo))success
                           failure:(void (^)(NSError *error))failure
{
    NSString *requestUrl;
    if (isFeed) {
        NSString *path = [NSString stringWithFormat:@"read/feed/%@", siteID];
        requestUrl = [self pathForEndpoint:path
                               withVersion:ServiceRemoteRESTApiVersion_1_1];
    } else {
        NSString *path = [NSString stringWithFormat:@"read/sites/%@", siteID];
        requestUrl = [self pathForEndpoint:path
                               withVersion:ServiceRemoteRESTApiVersion_1_2];
    }
    
    [self.api GET:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }

        RemoteReaderSiteInfo *siteInfo;
        NSDictionary *response = (NSDictionary *)responseObject;
        if (isFeed) {
            siteInfo = [self siteInfoForFeedResponse:response];
        } else {
            siteInfo = [self siteInfoForSiteResponse:response];
        }
        success(siteInfo);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (RemoteReaderSiteInfo *)siteInfoForSiteResponse:(NSDictionary *)response
{
    RemoteReaderSiteInfo *siteInfo = [RemoteReaderSiteInfo new];
    siteInfo.feedID = [response numberForKey:SiteDictionaryFeedIDKey];
    siteInfo.isFollowing = [[response numberForKey:SiteDictionaryFollowingKey] boolValue];
    siteInfo.isJetpack = [[response numberForKey:SiteDictionaryJetpackKey] boolValue];
    siteInfo.isPrivate = [[response numberForKey:SiteDictionaryPrivateKey] boolValue];
    siteInfo.isVisible = [[response numberForKey:SiteDictionaryVisibleKey] boolValue];
    siteInfo.postCount = [response numberForKey:SiteDictionaryPostCountKey];
    siteInfo.siteBlavatar = [response stringForKeyPath:SiteDictionaryIconPathKey];
    siteInfo.siteDescription = [response stringForKey:SiteDictionaryDescriptionKey];
    siteInfo.siteID = [response numberForKey:SiteDictionaryIDKey];
    siteInfo.siteName = [response stringForKey:SiteDictionaryNameKey];
    siteInfo.siteURL = [response stringForKey:SiteDictionaryURLKey];
    siteInfo.subscriberCount = [response numberForKey:SiteDictionarySubscriptionsKey] ?: @0;
    if (![siteInfo.siteName length] && [siteInfo.siteURL length] > 0) {
        siteInfo.siteName = [[NSURL URLWithString:siteInfo.siteURL] host];
    }
    return siteInfo;
}

- (RemoteReaderSiteInfo *)siteInfoForFeedResponse:(NSDictionary *)response
{
    RemoteReaderSiteInfo *siteInfo = [RemoteReaderSiteInfo new];
    siteInfo.feedID = [response numberForKey:SiteDictionaryFeedIDKey];
    siteInfo.isFollowing = [[response numberForKey:SiteDictionaryFollowingKey] boolValue];
    siteInfo.isJetpack = NO;
    siteInfo.isPrivate = NO;
    siteInfo.isVisible = YES;
    siteInfo.postCount = @0;
    siteInfo.siteBlavatar = @"";
    siteInfo.siteDescription = @"";
    siteInfo.siteID = @0;
    siteInfo.siteName = [response stringForKey:SiteDictionaryNameKey];
    siteInfo.siteURL = [response stringForKey:SiteDictionaryURLKey];
    siteInfo.subscriberCount = [response numberForKey:SiteDictionarySubscriptionsKey] ?: @0;
    if (![siteInfo.siteName length] && [siteInfo.siteURL length] > 0) {
        siteInfo.siteName = [[NSURL URLWithString:siteInfo.siteURL] host];
    }
    return siteInfo;
}


#pragma mark - Private Methods

/**
 Formats the specified string for use as part of the URL path for the tags endpoints
 in the REST API. Spaces and periods are converted to dashes, ampersands and hashes are
 removed.
 See https://github.com/WordPress/WordPress/blob/master/wp-includes/formatting.php#L1258

 @param topicName The string to be formatted.
 @return The formatted string.
 */
- (NSString *)slugForTopicName:(NSString *)topicName
{
    if (!topicName || [topicName length] == 0) {
        return @"";
    }

    static NSRegularExpression *regexHtmlEntities;
    static NSRegularExpression *regexPeriodsWhitespace;
    static NSRegularExpression *regexNonAlphaNumNonDash;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regexHtmlEntities = [NSRegularExpression regularExpressionWithPattern:@"&[^\\s]*;" options:NSRegularExpressionCaseInsensitive error:&error];
        regexPeriodsWhitespace = [NSRegularExpression regularExpressionWithPattern:@"[\\.\\s]+" options:NSRegularExpressionCaseInsensitive error:&error];
        regexNonAlphaNumNonDash = [NSRegularExpression regularExpressionWithPattern:@"[^\\p{L}\\p{Nd}\\-]+" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    topicName = [[topicName lowercaseString] trim];

    // remove html entities
    topicName = [regexHtmlEntities stringByReplacingMatchesInString:topicName
                                                            options:NSMatchingReportProgress
                                                              range:NSMakeRange(0, [topicName length])
                                                       withTemplate:@""];

    // replace periods and whitespace with a dash
    topicName = [regexPeriodsWhitespace stringByReplacingMatchesInString:topicName
                                                                 options:NSMatchingReportProgress
                                                                   range:NSMakeRange(0, [topicName length])
                                                            withTemplate:@"-"];

    // remove remaining non-alphanum/non-dash chars
    topicName = [regexNonAlphaNumNonDash stringByReplacingMatchesInString:topicName
                                                                  options:NSMatchingReportProgress
                                                                    range:NSMakeRange(0, [topicName length])
                                                             withTemplate:@""];

    // reduce double dashes potentially added above
    while ([topicName rangeOfString:@"--"].location != NSNotFound) {
        topicName = [topicName stringByReplacingOccurrencesOfString:@"--" withString:@"-"];
    }

    topicName = [topicName stringByRemovingPercentEncoding];

    return topicName;
}

- (NSArray *)normalizeMenuTopicsList:(NSArray *)rawTopics subscribed:(BOOL)subscribed recommended:(BOOL)recommended
{
    return [[rawTopics wp_filter:^BOOL(id obj) {
        return [obj isKindOfClass:[NSDictionary class]];
    }] wp_map:^id(NSDictionary *topic) {
        return [self normalizeMenuTopicDictionary:topic subscribed:subscribed recommended:recommended];
    }];
}

- (RemoteReaderTopic *)normalizeMenuTopicDictionary:(NSDictionary *)topicDict subscribed:(BOOL)subscribed recommended:(BOOL)recommended
{
    RemoteReaderTopic *topic = [self normalizeTopicDictionary:topicDict subscribed:subscribed recommended:recommended];
    topic.isMenuItem = YES;
    return topic;
}

/**
 Normalizes the supplied topics dictionary, ensuring expected keys are always present.

 @param topicDict The topic `NSDictionary` to normalize.
 @param subscribed Whether the current account subscribes to the topic.
 @param recommended Whether the topic is recommended.
 @return A RemoteReaderTopic instance.
 */
- (RemoteReaderTopic *)normalizeTopicDictionary:(NSDictionary *)topicDict
                                     subscribed:(BOOL)subscribed
                                    recommended:(BOOL)recommended
{
    NSNumber *topicID = [topicDict numberForKey:TopicDictionaryIDKey];
    if (topicID == nil) {
        topicID = @0;
    }

    RemoteReaderTopic *topic = [[RemoteReaderTopic alloc] init];
    topic.topicID = topicID;
    topic.isSubscribed = subscribed;
    topic.isRecommended = recommended;
    topic.owner = [topicDict stringForKey:TopicDictionaryOwnerKey];
    topic.path = [[topicDict stringForKey:TopicDictionaryURLKey] lowercaseString];
    topic.slug = [topicDict stringForKey:TopicDictionarySlugKey];
    topic.title = [topicDict stringForKey:TopicDictionaryTitleKey];

    return topic;
}

@end
