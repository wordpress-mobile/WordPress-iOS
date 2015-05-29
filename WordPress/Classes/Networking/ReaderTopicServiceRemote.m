#import "ReaderTopicServiceRemote.h"
#import "WordPressComApi.h"
#import "RemoteReaderTopic.h"
#import "ReaderTopic.h"

static NSString * const TopicMenuSectionDefaultKey = @"default";
static NSString * const TopicMenuSectionSubscribedKey = @"subscribed";
static NSString * const TopicMenuSectionRecommendedKey = @"recommended";
static NSString * const TopicDictionaryIDKey = @"ID";
static NSString * const TopicDictionarySlugKey = @"slug";
static NSString * const TopicDictionaryTitleKey = @"title";
static NSString * const TopicDictionaryURLKey = @"URL";
static NSString * const TopicNotFoundMarker = @"-notfound-";

@interface ReaderTopicServiceRemote ()
@property (nonatomic, strong) WordPressComApi *api;
@end

@implementation ReaderTopicServiceRemote

- (id)initWithRemoteApi:(WordPressComApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)fetchReaderMenuWithSuccess:(void (^)(NSArray *topics))success failure:(void (^)(NSError *error))failure
{

    NSString *path = @"read/menu";

    [self.api GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

        if (!success) {
            return;
        }

        // Normalize and flatten the results.
        // A topic can appear in both recommended and subscribed dictionaries,
        // so filter appropriately.

        NSDictionary *response = (NSDictionary *)responseObject;
        NSMutableArray *topics = [NSMutableArray array];

        NSDictionary *defaults = [response dictionaryForKey:TopicMenuSectionDefaultKey];
        NSMutableDictionary *subscribed = [[response dictionaryForKey:TopicMenuSectionSubscribedKey] mutableCopy];
        NSMutableDictionary *recommended = [[response dictionaryForKey:TopicMenuSectionRecommendedKey] mutableCopy];
        NSArray *subscribedAndRecommended;

        NSSet *subscribedSet = [NSSet setWithArray:[subscribed allKeys]];
        NSSet *recommendedSet = [NSSet setWithArray:[recommended allKeys]];
        [subscribedSet intersectsSet:recommendedSet];
        NSArray *sharedkeys = [subscribedSet allObjects];

        if (sharedkeys) {
            subscribedAndRecommended = [subscribed objectsForKeys:sharedkeys notFoundMarker:TopicNotFoundMarker];
            [subscribed removeObjectsForKeys:sharedkeys];
            [recommended removeObjectsForKeys:sharedkeys];
        }

        for (NSString *key in defaults) {
            [topics addObject:[self normalizeMenuTopicDictionary:[defaults objectForKey:key] subscribed:NO recommended:NO]];
        }

        for (NSString *key in subscribed) {
            [topics addObject:[self normalizeMenuTopicDictionary:[subscribed objectForKey:key] subscribed:YES recommended:NO]];
        }

        for (NSString *key in recommended) {
            [topics addObject:[self normalizeMenuTopicDictionary:[recommended objectForKey:key] subscribed:NO recommended:YES]];
        }

        for (id topic in subscribedAndRecommended) {
            // We should never encounter our not found marker, but just in case.
            if ([topic isKindOfClass:[NSString class]]) {
                continue;
            }
            [topics addObject:[self normalizeMenuTopicDictionary:(NSDictionary *)topic subscribed:YES recommended:YES]];
        }

        success(topics);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

}

- (void)unfollowTopicNamed:(NSString *)topicName withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    topicName = [self sanitizeTopicNameForAPI:topicName];
    NSString *path =[NSString stringWithFormat:@"read/tags/%@/mine/delete", topicName];

    [self.api POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }
        success();

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followTopicNamed:(NSString *)topicName withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    topicName = [self sanitizeTopicNameForAPI:topicName];
    NSString *path =[NSString stringWithFormat:@"read/tags/%@/mine/new", topicName];

    [self.api POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }
        success();

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
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
- (NSString *)sanitizeTopicNameForAPI:(NSString *)topicName
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

    return topicName;
}

- (RemoteReaderTopic *)normalizeMenuTopicDictionary:(NSDictionary *)topicDict subscribed:(BOOL)subscribed recommended:(BOOL)recommended
{
    RemoteReaderTopic *topic = [self normalizeTopicDictionary:topicDict subscribed:subscribed recommended:recommended];
    topic.isMenuItem = YES;
    topic.type = ([topic.topicID integerValue] == 0) ? ReaderTopicTypeList : ReaderTopicTypeTag;
    return topic;
}

/**
 Normalizes the supplied topics dictionary, ensuring expected keys are always present.

 @param topicDict The topic `NSDictionary` to normalize.
 @param subscribed Whether the current account subscribes to the topic.
 @param recommended Whether the topic is recommended.
 @return A RemoteReaderTopic instance.
 */
- (RemoteReaderTopic *)normalizeTopicDictionary:(NSDictionary *)topicDict subscribed:(BOOL)subscribed recommended:(BOOL)recommended
{
    NSNumber *topicID = [topicDict numberForKey:TopicDictionaryIDKey];
    if (topicID == nil) {
        topicID = @0;
    }

    RemoteReaderTopic *topic = [[RemoteReaderTopic alloc] init];
    topic.topicID = topicID;
    topic.isSubscribed = subscribed;
    topic.isRecommended = recommended;
    topic.path = [topicDict stringForKey:TopicDictionaryURLKey];
    topic.slug = [topicDict stringForKey:TopicDictionarySlugKey];
    topic.title = [topicDict stringForKey:TopicDictionaryTitleKey];

    return topic;
}

@end
