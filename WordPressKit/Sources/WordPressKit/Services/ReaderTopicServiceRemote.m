#import "ReaderTopicServiceRemote.h"
#import "WPKit-Swift.h"
@import NSObject_SafeExpectations;
@import WordPressShared;

static NSString * const TopicMenuSectionDefaultKey = @"default";
static NSString * const TopicMenuSectionSubscribedKey = @"subscribed";
static NSString * const TopicMenuSectionRecommendedKey = @"recommended";
static NSString * const TopicRemovedTagKey = @"removed_tag";
static NSString * const TopicAddedTagKey = @"added_tag";
static NSString * const TopicDictionaryTagKey = @"tag";
static NSString * const TopicNotFoundMarker = @"-notfound-";

@implementation ReaderTopicServiceRemote

- (void)fetchReaderMenuWithSuccess:(void (^)(NSArray *topics))success failure:(void (^)(NSError *error))failure
{
    NSString *path = @"read/menu";
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_3];

    [self.wordPressComRESTAPI get:requestUrl parameters:nil success:^(NSDictionary *response, NSHTTPURLResponse *httpResponse) {
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

    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)fetchFollowedSitesWithSuccess:(void(^)(NSArray *sites))success failure:(void(^)(NSError *error))failure
{
    void (^wrappedSuccess)(NSNumber *, NSArray<RemoteReaderSiteInfo *> *) = ^(NSNumber *totalSites, NSArray<RemoteReaderSiteInfo *> *sites) {
        if (success) {
            success(sites);
        }
    };

    [self fetchFollowedSitesForPage:0 number:0 success:wrappedSuccess failure:failure];
}

- (void)fetchFollowedSitesForPage:(NSUInteger)page
                           number:(NSUInteger)number
                          success:(void(^)(NSNumber *totalSites, NSArray<RemoteReaderSiteInfo *> *sites))success
                          failure:(void(^)(NSError *error))failure
{
    NSString *path = [self pathForFollowedSitesWithPage:page number:number];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_2];

    [self.wordPressComRESTAPI get:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (!success) {
            return;
        }
        NSDictionary *response = (NSDictionary *)responseObject;
        NSNumber *totalSites = [response numberForKey:@"total_subscriptions"];
        NSArray *subscriptions = [response arrayForKey:@"subscriptions"];
        NSMutableArray *sites = [NSMutableArray array];
        for (NSDictionary *dict in subscriptions) {
            RemoteReaderSiteInfo *siteInfo = [self siteInfoFromFollowedSiteDictionary:dict];
            [sites addObject:siteInfo];
        }
        success(totalSites, sites);
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    [self.wordPressComRESTAPI post:requestUrl parameters:nil success:^(NSDictionary *responseObject, NSHTTPURLResponse *httpResponse) {
        if (!success) {
            return;
        }
        NSNumber *unfollowedTag = [responseObject numberForKey:TopicRemovedTagKey];
        success(unfollowedTag);

    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
    path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    [self.wordPressComRESTAPI post:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (!success) {
            return;
        }
        NSNumber *followedTag = [responseObject numberForKey:TopicAddedTagKey];
        success(followedTag);

    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                                     withVersion:WordPressComRESTAPIVersion_1_2];

    [self.wordPressComRESTAPI get:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (!success) {
            return;
        }

        NSDictionary *response = (NSDictionary *)responseObject;
        NSDictionary *topicDict = [response dictionaryForKey:TopicDictionaryTagKey];
        RemoteReaderTopic *remoteTopic = [self normalizeMenuTopicDictionary:topicDict subscribed:NO recommended:NO];
        remoteTopic.isMenuItem = NO;
        success(remoteTopic);

    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                               withVersion:WordPressComRESTAPIVersion_1_1];
    } else {
        NSString *path = [NSString stringWithFormat:@"read/sites/%@", siteID];
        requestUrl = [self pathForEndpoint:path
                               withVersion:WordPressComRESTAPIVersion_1_2];
    }
    
    [self.wordPressComRESTAPI get:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (!success) {
            return;
        }


        NSDictionary *response = (NSDictionary *)responseObject;
        RemoteReaderSiteInfo *siteInfo = [RemoteReaderSiteInfo siteInfoForSiteResponse:response
                                                                                isFeed:isFeed];

        siteInfo.postsEndpoint = [self endpointUrlForPath:siteInfo.endpointPath];

        success(siteInfo);

    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

- (RemoteReaderSiteInfo *)siteInfoFromFollowedSiteDictionary:(NSDictionary *)dict
{
    NSDictionary *meta = [dict dictionaryForKeyPath:@"meta.data.site"];
    RemoteReaderSiteInfo *siteInfo;

    if (meta) {
        siteInfo = [RemoteReaderSiteInfo siteInfoForSiteResponse:meta isFeed:NO];
    } else {
        meta = [dict dictionaryForKeyPath:@"meta.data.feed"];
        siteInfo = [RemoteReaderSiteInfo siteInfoForSiteResponse:meta isFeed:YES];
    }

    siteInfo.postsEndpoint = [self endpointUrlForPath:siteInfo.endpointPath];
    
    return siteInfo;
}

- (NSString *)endpointUrlForPath:(NSString *)endpoint
{
    NSString *absolutePath = [self pathForEndpoint:endpoint withVersion:WordPressComRESTAPIVersion_1_2];
    NSURL *url = [NSURL URLWithString:absolutePath relativeToURL:self.wordPressComRESTAPI.baseURL];
    return [url absoluteString];
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
    RemoteReaderTopic *topic = [[RemoteReaderTopic alloc] initWithDictionary:topicDict subscribed:subscribed recommended:recommended];
    topic.isMenuItem = YES;
    return topic;
}

- (NSString *)pathForFollowedSitesWithPage:(NSUInteger)page number:(NSUInteger)number
{
    NSString *path = @"read/following/mine?meta=site,feed";
    if (page > 0) {
        path = [path stringByAppendingFormat:@"&page=%lu", (unsigned long)page];
    }
    if (number > 0) {
        path = [path stringByAppendingFormat:@"&number=%lu", (unsigned long)number];
    }

    return path;
}

@end
