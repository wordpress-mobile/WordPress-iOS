#import "ReaderTopicServiceRemote.h"
#import "WordPressComApi.h"
#import "RemoteReaderTopic.h"

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

        NSDictionary *defaults = [response dictionaryForKey:@"default"];
        NSMutableDictionary *subscribed = [[response dictionaryForKey:@"subscribed"] mutableCopy];
        NSMutableDictionary *recommended = [[response dictionaryForKey:@"recommended"] mutableCopy];
        NSArray *subscribedAndRecommended;

        NSSet *subscribedSet = [NSSet setWithArray:[subscribed allKeys]];
        NSSet *recommendedSet = [NSSet setWithArray:[recommended allKeys]];
        [subscribedSet intersectsSet:recommendedSet];
        NSArray *sharedkeys = [subscribedSet allObjects];

        if (sharedkeys) {
            subscribedAndRecommended = [subscribed objectsForKeys:sharedkeys notFoundMarker:@"-notfound-"];
            [subscribed removeObjectsForKeys:sharedkeys];
            [recommended removeObjectsForKeys:sharedkeys];
        }

        for (NSString *key in defaults) {
            [topics addObject:[self normalizeTopicDictionary:[defaults objectForKey:key] subscribed:NO recommended:NO]];
        }

        for (NSString *key in subscribed) {
            [topics addObject:[self normalizeTopicDictionary:[subscribed objectForKey:key] subscribed:YES recommended:NO]];
        }

        for (NSString *key in recommended) {
            [topics addObject:[self normalizeTopicDictionary:[recommended objectForKey:key] subscribed:NO recommended:YES]];
        }

        for (id topic in subscribedAndRecommended) {
            // We should never encounter our not found marker, but just in case.
            if ([topic isKindOfClass:[NSString class]]) {
                continue;
            }
            [topics addObject:[self normalizeTopicDictionary:(NSDictionary *)topic subscribed:YES recommended:YES]];
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

 @param topicName The string to be formatted.
 @return The formatted string.
 */
- (NSString *)sanitizeTopicNameForAPI:(NSString *)topicName
{
    if (!topicName || [topicName length] == 0) {
        return @"";
    }
    topicName = [[topicName lowercaseString] trim];
    topicName = [topicName stringByReplacingOccurrencesOfString:@"&" withString:@""];
    topicName = [topicName stringByReplacingOccurrencesOfString:@"#" withString:@""];
    topicName = [topicName stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    topicName = [topicName stringByReplacingOccurrencesOfString:@"." withString:@"-"];

    while ([topicName rangeOfString:@"--"].location != NSNotFound) {
        topicName = [topicName stringByReplacingOccurrencesOfString:@"--" withString:@"-"];
    }

    topicName = [topicName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];

    return topicName;
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
    NSNumber *topicID = [topicDict numberForKey:@"ID"];
    if (topicID == nil) {
        topicID = @0;
    }
    NSString *title = [topicDict stringForKey:@"title"];
    NSString *url = [topicDict stringForKey:@"URL"];

    RemoteReaderTopic *topic = [[RemoteReaderTopic alloc] init];
    topic.topicID = topicID;
    topic.title = title;
    topic.path = url;
    topic.isSubscribed = subscribed;
    topic.isRecommended = recommended;
    return topic;
}

@end
