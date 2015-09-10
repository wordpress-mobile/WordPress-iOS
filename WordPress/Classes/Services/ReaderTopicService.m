#import "ReaderTopicService.h"

#import "AccountService.h"
#import "ContextManager.h"
#import "NSString+XMLExtensions.h"
#import "ReaderPost.h"
#import "ReaderSite.h"
#import "RemoteReaderSiteInfo.h"
#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "WordPressComApi.h"
#import "WordPress-Swift.h"
#import "WPAccount.h"

NSString * const ReaderTopicDidChangeViaUserInteractionNotification = @"ReaderTopicDidChangeViaUserInteractionNotification";
NSString * const ReaderTopicDidChangeNotification = @"ReaderTopicDidChangeNotification";
NSString * const ReaderTopicFreshlyPressedPathCommponent = @"freshly-pressed";
static NSString * const ReaderTopicCurrentTopicPathKey = @"ReaderTopicCurrentTopicPathKey";

@implementation ReaderTopicService

- (void)fetchReaderMenuWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WordPressComApi *api = [WordPressComApi anonymousApi];

    // If the account is not nil, and its api has credentials we'll use it.
    if ([[defaultAccount restApi] hasCredentials]) {
         api = [defaultAccount restApi];
    }

    // Keep a reference to the NSManagedObjectID (if it exists).
    // We'll use it to verify that the account did not change while fetching topics.
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:api];
    [remoteService fetchReaderMenuWithSuccess:^(NSArray *topics) {

        WPAccount *reloadedAccount = [accountService defaultWordPressComAccount];

        // Make sure that we have the same account now that we did when we started.
        if ((!defaultAccount && !reloadedAccount) || [defaultAccount.objectID isEqual:reloadedAccount.objectID]) {
            // If both accounts are nil, or if both accounts exist and are identical we're good to go.
        } else {
            // The account changed so our results are invalid. Fetch them anew!
            [self fetchReaderMenuWithSuccess:success failure:failure];
            return;
        }

        [self mergeMenuTopics:topics withSuccess:success];

    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (ReaderAbstractTopic *)currentTopic
{
    ReaderAbstractTopic *topic;
    topic = [self currentTopicFromSavedPath];

    if (!topic) {
        topic = [self currentTopicFromDefaultTopic];
        [self setCurrentTopic:topic];
    }

    return topic;
}

- (ReaderAbstractTopic *)currentTopicFromSavedPath
{
    ReaderAbstractTopic *topic;
    NSString *topicPathString = [[NSUserDefaults standardUserDefaults] stringForKey:ReaderTopicCurrentTopicPathKey];
    if (topicPathString) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
        request.predicate = [NSPredicate predicateWithFormat:@"path = %@", topicPathString];

        NSError *error;
        topic = [[self.managedObjectContext executeFetchRequest:request error:&error] firstObject];
        if (error) {
            DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
        }
    }
    return topic;
}

- (ReaderAbstractTopic *)currentTopicFromDefaultTopic
{
    // Return the default topic
    ReaderAbstractTopic *topic;
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderDefaultTopic classNameWithoutNamespaces]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSArray *topics = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    if ([topics count] == 0) {
        return nil;
    }

    NSArray *matches = [topics filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path CONTAINS[cd] %@", ReaderTopicFreshlyPressedPathCommponent]];
    if ([matches count]) {
        topic = matches[0];
    } else {
        topic = topics[0];
    }

    return topic;
}

- (void)setCurrentTopic:(ReaderAbstractTopic *)topic
{
    if (!topic) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderTopicCurrentTopicPathKey];
        [NSUserDefaults resetStandardUserDefaults];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:topic.path forKey:ReaderTopicCurrentTopicPathKey];
        [NSUserDefaults resetStandardUserDefaults];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeNotification object:nil]; 
        });
    }
}

- (NSUInteger)numberOfSubscribedTopics
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderTagTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"following = YES"];
    NSError *error;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error counting topics: %@", NSStringFromSelector(_cmd), error);
        return 0;
    }
    return count;
}

- (void)deleteAllTopics
{
    [self setCurrentTopic:nil];
    NSArray *currentTopics = [self allTopics];
    for (ReaderAbstractTopic *topic in currentTopics) {
        [self.managedObjectContext deleteObject:topic];
    }
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)deleteTopic:(ReaderAbstractTopic *)topic
{
    if (!topic) {
        return;
    }
    [self.managedObjectContext deleteObject:topic];
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)subscribeToAndMakeTopicCurrent:(ReaderAbstractTopic *)topic
{
    // Optimistically mark the topic subscribed.
    topic.following = YES;
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
    [self setCurrentTopic:topic];

    NSString *topicName = [topic.title lowercaseString];
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService followTopicNamed:topicName withSuccess:^(NSNumber *topicID){
        // noop
    } failure:^(NSError *error) {
        DDLogError(@"%@ error following topic: %@", NSStringFromSelector(_cmd), error);
    }];

}

- (void)unfollowTopic:(ReaderTagTopic *)topic withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSString *slug = topic.slug;

    BOOL deletingCurrentTopic = [topic isEqual:self.currentTopic];

    // Optimistically unfollow the topic
    if (topic.isRecommended) {
        topic.following = NO;
    } else {
        [self.managedObjectContext deleteObject:topic];
    }
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];

    if (deletingCurrentTopic) {
        // set the current topic to nil and call the current topic to choose a default.
        [self setCurrentTopic:nil];
        [self currentTopic];
    }
    // Now do it for realz.
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService unfollowTopicWithSlug:slug withSuccess:^(NSNumber *topicID){
        // Sync the menu for good measure.
        [self fetchReaderMenuWithSuccess:success failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error unfollowing topic: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];
}

- (void)followTopicNamed:(NSString *)topicName withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    topicName = [[topicName lowercaseString] trim];

    // If the topic already is in core data, just make it the current topic.
    ReaderAbstractTopic *topic = [self findTopicNamed:topicName];
    if (topic) {
        [self setCurrentTopic:topic];
        if (success) {
            success();
        }
        return;
    }

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService followTopicNamed:topicName withSuccess:^(NSNumber *topicID){
        __weak __typeof(self) weakSelf = self;
        [self fetchReaderMenuWithSuccess:^{
            [weakSelf selectTopicWithID:topicID];
        } failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error following topic by name: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];
}

- (ReaderAbstractTopic *)topicForFollowedSites
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"path LIKE %@", @"*/read/following"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Failed to fetch topic for sites I follow: %@", error);
        return nil;
    }
    return (ReaderAbstractTopic *)[results firstObject];
}

- (void)siteTopicForSiteWithID:(NSNumber *)siteID
                       success:(void (^)(NSManagedObjectID *objectID, BOOL isFollowing))success
                       failure:(void (^)(NSError *error))failure
{
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService fetchSiteInfoForSiteWithID:siteID success:^(RemoteReaderSiteInfo *siteInfo) {
        if (!success) {
            return;
        }

        NSEntityDescription *entity = [NSEntityDescription entityForName:[ReaderSiteTopic classNameWithoutNamespaces]
                                                  inManagedObjectContext:self.managedObjectContext];

        ReaderSiteTopic *topic = [[ReaderSiteTopic alloc] initWithEntity:entity
                     insertIntoManagedObjectContext:self.managedObjectContext];

        topic.feedID = siteInfo.feedID;
        topic.following = siteInfo.isFollowing;
        topic.isJetpack = siteInfo.isJetpack;
        topic.isPrivate = siteInfo.isPrivate;
        topic.isVisible = siteInfo.isVisible;
        topic.postCount = siteInfo.postCount;
        topic.siteBlavatar = siteInfo.siteBlavatar;
        topic.siteDescription = siteInfo.siteDescription;
        topic.siteID = siteInfo.siteID;
        topic.siteURL = siteInfo.siteURL;
        topic.subscriberCount = siteInfo.subscriberCount;
        topic.title = siteInfo.siteName;
        topic.path = [NSString stringWithFormat:@"%@read/sites/%@/posts/", WordPressRestApiEndpointURL, siteInfo.siteID];

        NSError *error;
        [self.managedObjectContext obtainPermanentIDsForObjects:@[topic] error:&error];
        if (error) {
            DDLogError(@"%@ error obtaining permanent ID for topic for site with ID %@: %@", NSStringFromSelector(_cmd), siteID, error);
        }

        [self.managedObjectContext save:&error];
        if (error) {
            DDLogError(@"%@ error saving topic for site with ID %@: %@", NSStringFromSelector(_cmd), siteID, error);
        }

        success(topic.objectID, siteInfo.isFollowing);

    } failure:^(NSError *error) {
        DDLogError(@"%@ error fetching site info for site with ID %@: %@", NSStringFromSelector(_cmd), siteID, error);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Private Methods

/**
 Get the api to use for the request.
 */
- (WordPressComApi *)apiForRequest
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WordPressComApi *api = [defaultAccount restApi];
    if (![api hasCredentials]) {
        api = [WordPressComApi anonymousApi];
    }
    return api;
}

/**
 Finds an existing topic matching the specified name and, if found, makes it the
 selected topic.
 */
- (void)selectTopicNamed:(NSString *)topicName
{
    ReaderAbstractTopic *topic = [self findTopicNamed:topicName];
    [self setCurrentTopic:topic];
}

/**
 Finds an existing topic matching the specified topicID and, if found, makes it the
 selected topic.
 */
- (void)selectTopicWithID:(NSNumber *)topicID
{
    ReaderAbstractTopic *topic = [self findTopicWithID:topicID];
    [self setCurrentTopic:topic];
}

/**
 Find an existing topic with the specified title.

 @param topicName The title of the topic to find in core data.
 @return A matching `ReaderAbstractTopic` instance or nil.
 */
- (ReaderTagTopic *)findTopicNamed:(NSString *)topicName
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderTagTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"title LIKE[c] %@", topicName];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSArray *topics = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    return [topics firstObject];
}

/**
 Find an existing topic with the specified topicID.

 @param topicID The topicID of the topic to find in core data.
 @return A matching `ReaderAbstractTopic` instance or nil.
 */
- (ReaderTagTopic *)findTopicWithID:(NSNumber *)topicID
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderTagTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"tagID = %@", topicID];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSArray *topics = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    return [topics firstObject];
}

/**
 Create a new `ReaderAbstractTopic` or update an existing `ReaderAbstractTopic`.

 @param dict A `RemoteReaderTopic` object.
 @return A new or updated, but unsaved, `ReaderAbstractTopic`.
 */
- (ReaderAbstractTopic *)createOrReplaceFromRemoteTopic:(RemoteReaderTopic *)remoteTopic
{
    NSString *path = remoteTopic.path;

    if (path == nil || path.length == 0) {
        return nil;
    }

    NSString *title = remoteTopic.title;
    if (title == nil || title.length == 0) {
        return nil;
    }

    ReaderAbstractTopic *topic = [self topicForRemoteTopic:remoteTopic];
    return topic;
}

- (ReaderAbstractTopic *)topicForRemoteTopic:(RemoteReaderTopic *)remoteTopic
{
    if ([remoteTopic.path rangeOfString:@"/tags/"].location != NSNotFound) {
        return [self tagTopicForRemoteTopic:remoteTopic];

    } else if ([remoteTopic.path rangeOfString:@"/list/"].location != NSNotFound) {
        return [self listTopicForRemoteTopic:remoteTopic];

    }

    return [self defaultTopicForRemoteTopic:remoteTopic];
}

- (ReaderTagTopic *)tagTopicForRemoteTopic:(RemoteReaderTopic *)remoteTopic
{
    ReaderTagTopic *topic = (ReaderTagTopic *)[self findWithPath:remoteTopic.path];
    if (!topic || ![topic isKindOfClass:[ReaderTagTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderTagTopic classNameWithoutNamespaces]
                                                             inManagedObjectContext:self.managedObjectContext];
    }
    topic.type = [ReaderTagTopic TopicType];
    topic.tagID = remoteTopic.topicID;
    topic.title = [self formatTitle:remoteTopic.title];
    topic.slug = remoteTopic.slug;
    topic.path = remoteTopic.path;
    topic.showInMenu = remoteTopic.isMenuItem;
    topic.following = remoteTopic.isSubscribed;

    return topic;
}

- (ReaderListTopic *)listTopicForRemoteTopic:(RemoteReaderTopic *)remoteTopic
{
    ReaderListTopic *topic = (ReaderListTopic *)[self findWithPath:remoteTopic.path];
    if (!topic || ![topic isKindOfClass:[ReaderListTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderListTopic classNameWithoutNamespaces]
                                              inManagedObjectContext:self.managedObjectContext];
    }
    topic.type = [ReaderListTopic TopicType];
    topic.listID = remoteTopic.topicID;
    topic.title = [self formatTitle:remoteTopic.title];
    topic.slug = remoteTopic.slug;
    topic.path = remoteTopic.path;
    topic.showInMenu = YES;
    topic.following = YES;

    return topic;
}

- (ReaderDefaultTopic *)defaultTopicForRemoteTopic:(RemoteReaderTopic *)remoteTopic
{
    ReaderDefaultTopic *topic = (ReaderDefaultTopic *)[self findWithPath:remoteTopic.path];
    if (!topic || ![topic isKindOfClass:[ReaderDefaultTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderDefaultTopic classNameWithoutNamespaces]
                                              inManagedObjectContext:self.managedObjectContext];
    }
    topic.type = [ReaderDefaultTopic TopicType];
    topic.title = [self formatTitle:remoteTopic.title];
    topic.path = remoteTopic.path;
    topic.showInMenu = YES;
    topic.following = YES;

    return topic;
}

- (NSString *)formatTitle:(NSString *)str
{
    NSString *title = [str stringByDecodingXMLCharacters];

    // Failsafe
    if ([title length] == 0) {
        return title;
    }

    // If already capitalized, assume the title was returned as it should be displayed.
    if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[title characterAtIndex:0]]) {
        return title;
    }

    // iPhone, ePaper, etc. assume correctly formatted
    if ([title length] > 1 &&
        [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:[title characterAtIndex:0]] &&
        [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[title characterAtIndex:1]]) {
        return title;
    }

    return [title capitalizedStringWithLocale:[NSLocale currentLocale]];
}

/**
 Saves the specified `ReaderAbstractTopics`. Any `ReaderAbstractTopics` not included in the passed
 array are removed from Core Data.

 @param topics An array of `ReaderAbstractTopics` to save.
 */
- (void)mergeMenuTopics:(NSArray *)topics withSuccess:(void (^)())success
{
    [self.managedObjectContext performBlock:^{
        NSArray *currentTopics = [self allMenuTopics];
        NSMutableArray *topicsToKeep = [NSMutableArray array];

        for (RemoteReaderTopic *remoteTopic in topics) {
            ReaderAbstractTopic *newTopic = [self createOrReplaceFromRemoteTopic:remoteTopic];
            if (newTopic != nil) {
                [topicsToKeep addObject:newTopic];
            } else {
                DDLogInfo(@"%@ returned a nil topic: %@", NSStringFromSelector(_cmd), remoteTopic);
            }
        }

        if ([currentTopics count] > 0) {
            for (ReaderAbstractTopic *topic in currentTopics) {
                if (![topic isKindOfClass:[ReaderSiteTopic class]] && ![topicsToKeep containsObject:topic]) {
                    DDLogInfo(@"Deleting Reader Topic: %@", topic);
                    if ([topic isEqual:self.currentTopic]) {
                        self.currentTopic = nil;
                    }
                    [self.managedObjectContext deleteObject:topic];
                }
            }
        }

        [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
            if (success) {
                success();
            }
        }];

    }];
}

/**
 Fetch all `ReaderAbstractTopics` for the menu currently in Core Data.

 @return An array of all `ReaderAbstractTopics` for the menu currently persisted in Core Data.
 */
- (NSArray *)allMenuTopics
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"showInMenu = YES"];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    return results;
}

/**
 Fetch all `ReaderAbstractTopics` currently in Core Data.

 @return An array of all `ReaderAbstractTopics` currently persisted in Core Data.
 */
- (NSArray *)allTopics
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    return results;
}

/**
 Find a specific ReaderAbstractTopic by its `path` property.

 @param path The unique, cannonical path of the topic.
 @return A matching `ReaderAbstractTopic` or nil if there is no match.
 */
- (ReaderAbstractTopic *)findWithPath:(NSString *)path
{
    NSArray *results = [[self allTopics] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path = %@", [path lowercaseString]]];
    return [results firstObject];
}

@end
