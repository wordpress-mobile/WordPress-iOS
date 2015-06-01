#import "ReaderTopicService.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "NSString+XMLExtensions.h"
#import "ReaderTopic.h"
#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "WPAccount.h"
#import "WordPressComApi.h"
#import "ReaderPost.h"
#import "ReaderSite.h"

NSString * const ReaderTopicDidChangeViaUserInteractionNotification = @"ReaderTopicDidChangeViaUserInteractionNotification";
NSString * const ReaderTopicDidChangeNotification = @"ReaderTopicDidChangeNotification";
NSString * const ReaderTopicFreshlyPressedPathCommponent = @"freshly-pressed";
static NSString * const ReaderTopicCurrentTopicURIKey = @"ReaderTopicCurrentTopicURIKey"; // Deprecated
static NSString * const ReaderTopicCurrentTopicPathKey = @"ReaderTopicCurrentTopicPathKey";

@interface ReaderTopicService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation ReaderTopicService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

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
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithRemoteApi:api];
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

        [self mergeMenuTopics:topics forAccount:reloadedAccount];

        if (success) {
            success();
        }

    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (ReaderTopic *)currentTopic
{
    ReaderTopic *topic;
    topic = [self currentTopicFromSavedPath];

    if (!topic) {
        topic = [self currentTopicFromSavedURIString];
    }

    if (!topic) {
        topic = [self currentTopicFromDefaultTopic];
        [self setCurrentTopic:topic];
    }

    return topic;
}

- (ReaderTopic *)currentTopicFromSavedPath
{
    ReaderTopic *topic;
    NSString *topicPathString = [[NSUserDefaults standardUserDefaults] stringForKey:ReaderTopicCurrentTopicPathKey];
    if (topicPathString) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderTopic class])];
        request.predicate = [NSPredicate predicateWithFormat:@"path = %@", topicPathString];

        NSError *error;
        topic = [[self.managedObjectContext executeFetchRequest:request error:&error] firstObject];
        if (error) {
            DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
        }
    }
    return topic;
}

// Deprecated. This can be removed after the bulk of our user base has updated to 4.7 or later
- (ReaderTopic *)currentTopicFromSavedURIString
{
    ReaderTopic *topic;
    NSString *topicURIString = [[NSUserDefaults standardUserDefaults] stringForKey:ReaderTopicCurrentTopicURIKey];
    if (topicURIString) {
        NSURL *topicURI = [NSURL URLWithString:topicURIString];
        NSManagedObjectID *objectID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:topicURI];
        if (objectID) {
            NSError *error;
            topic = (ReaderTopic *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
            if (error) {
                DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
            }
        }
    }

    if (topic) {
        // transition to the new key
        [[NSUserDefaults standardUserDefaults] setObject:topic.path forKey:ReaderTopicCurrentTopicPathKey];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderTopicCurrentTopicURIKey];
        [NSUserDefaults resetStandardUserDefaults];
        [self setCurrentTopic:topic];
    }

    return topic;
}

- (ReaderTopic *)currentTopicFromDefaultTopic
{
    // Return the default topic
    ReaderTopic *topic;
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderTopic class])];
    request.predicate = [NSPredicate predicateWithFormat:@"type = %@", ReaderTopicTypeList];
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

- (void)setCurrentTopic:(ReaderTopic *)topic
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSubscribed = YES AND type = %@", ReaderTopicTypeTag];
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
    for (ReaderTopic *topic in currentTopics) {
        [self.managedObjectContext deleteObject:topic];
    }
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)deleteTopic:(ReaderTopic *)topic
{
    [self.managedObjectContext deleteObject:topic];
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)subscribeToAndMakeTopicCurrent:(ReaderTopic *)topic
{
    // Optimistically mark the topic subscribed.
    topic.isSubscribed = YES;
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
    [self setCurrentTopic:topic];

    NSString *topicName = [topic.title lowercaseString];
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [remoteService followTopicNamed:topicName withSuccess:^(NSNumber *topicID){
        // noop
    } failure:^(NSError *error) {
        DDLogError(@"%@ error following topic: %@", NSStringFromSelector(_cmd), error);
    }];

}

- (void)unfollowTopic:(ReaderTopic *)topic withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSString *slug = topic.slug;

    BOOL deletingCurrentTopic = [topic isEqual:self.currentTopic];

    // Optimistically unfollow the topic
    if (topic.isRecommended) {
        topic.isSubscribed = NO;
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
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
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
    ReaderTopic *topic = [self findTopicNamed:topicName];
    if (topic) {
        [self setCurrentTopic:topic];
        if (success) {
            success();
        }
        return;
    }

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
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

- (ReaderTopic *)topicForFollowedSites
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"path LIKE %@", @"*/read/following"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Failed to fetch topic for sites I follow: %@", error);
        return nil;
    }
    return (ReaderTopic *)[results firstObject];
}

- (ReaderTopic *)siteTopicForSite:(ReaderSite *)site
{
    // Feeds are not supported yet.
    if (site.isFeed) {
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"%@sites/%@/posts/", WordPressRestApiEndpointURL, site.siteID];;

    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"path LIKE %@", path];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Failed to fetch topic for site: %@", error);
        return nil;
    }

    ReaderTopic *topic = nil;
    if (results.count > 0) {
        topic = (ReaderTopic *)[results firstObject];
    } else {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ReaderTopic"
                                                  inManagedObjectContext:self.managedObjectContext];
        topic = [[ReaderTopic alloc] initWithEntity:entity
                     insertIntoManagedObjectContext:self.managedObjectContext];
    }

    topic.topicID = site.siteID;
    topic.type = ReaderTopicTypeSite;
    topic.title = site.name;
    topic.path = path;

    return topic;
}

- (ReaderTopic *)siteTopicForPost:(ReaderPost *)post
{
    NSString *path;
    if (post.isWPCom) {
        path = [NSString stringWithFormat:@"%@sites/%@/posts/", WordPressRestApiEndpointURL, post.siteID];
    } else {
        path = [NSString stringWithFormat:@"%@read/feed/%@/posts/", WordPressRestApiEndpointURL, post.siteID];
    }
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"path LIKE %@", path];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Failed to fetch topic for site: %@", error);
        return nil;
    }
    ReaderTopic *topic = nil;
    if (results.count > 0) {
        topic = (ReaderTopic *)[results firstObject];
    } else {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ReaderTopic"
                                                  inManagedObjectContext:self.managedObjectContext];
        topic = [[ReaderTopic alloc] initWithEntity:entity
                     insertIntoManagedObjectContext:self.managedObjectContext];
    }

    topic.topicID = post.siteID;
    topic.type = ReaderTopicTypeSite;
    topic.title = post.blogName;
    topic.topicDescription = post.blogDescription;
    topic.path = path;

    return topic;
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
    ReaderTopic *topic = [self findTopicNamed:topicName];
    [self setCurrentTopic:topic];
}

/**
 Finds an existing topic matching the specified topicID and, if found, makes it the
 selected topic.
 */
- (void)selectTopicWithID:(NSNumber *)topicID
{
    ReaderTopic *topic = [self findTopicWithID:topicID];
    [self setCurrentTopic:topic];
}

/**
 Find an existing topic with the specified title.

 @param topicName The title of the topic to find in core data.
 @return A matching `ReaderTopic` instance or nil.
 */
- (ReaderTopic *)findTopicNamed:(NSString *)topicName
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
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
 @return A matching `ReaderTopic` instance or nil.
 */
- (ReaderTopic *)findTopicWithID:(NSNumber *)topicID
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"topicID = %@", topicID];

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
 Create a new `ReaderTopic` or update an existing `ReaderTopic`.

 @param dict A `RemoteReaderTopic` object.
 @return A new or updated, but unsaved, `ReaderTopic`.
 */
- (ReaderTopic *)createOrReplaceFromRemoteTopic:(RemoteReaderTopic *)remoteTopic
{
    NSString *path = remoteTopic.path;

    if (path == nil || path.length == 0) {
        return nil;
    }

    NSString *title = remoteTopic.title;
    if (title == nil || title.length == 0) {
        return nil;
    }

    ReaderTopic *topic = [self findWithPath:path];
    if (topic == nil) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderTopic"
                                              inManagedObjectContext:self.managedObjectContext];
    }

    topic.topicID = remoteTopic.topicID;
    topic.type = remoteTopic.type;
    topic.title = [self formatTitle:title];
    topic.slug = remoteTopic.slug;
    topic.path = [path lowercaseString];
    topic.topicDescription = remoteTopic.topicDescription;
    topic.isMenuItem = remoteTopic.isMenuItem;
    topic.isSubscribed = remoteTopic.isSubscribed;
    topic.isRecommended = remoteTopic.isRecommended;

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
 Saves the specified `ReaderTopics`. Any `ReaderTopics` not included in the passed
 array are removed from Core Data.

 @param topics An array of `ReaderTopics` to save.
 */
- (void)mergeMenuTopics:(NSArray *)topics forAccount:(WPAccount *)account
{
    NSArray *currentTopics = [self allMenuTopics];
    NSMutableArray *topicsToKeep = [NSMutableArray array];

    for (RemoteReaderTopic *remoteTopic in topics) {
        ReaderTopic *newTopic = [self createOrReplaceFromRemoteTopic:remoteTopic];
        newTopic.account = account;
        if (newTopic != nil) {
            [topicsToKeep addObject:newTopic];
        } else {
            DDLogInfo(@"%@ returned a nil topic: %@", NSStringFromSelector(_cmd), remoteTopic);
        }
    }

    if ([currentTopics count] > 0) {
        for (ReaderTopic *topic in currentTopics) {
            if (![topic.type isEqualToString:ReaderTopicTypeSite] && ![topicsToKeep containsObject:topic]) {
                DDLogInfo(@"Deleting ReaderTopic: %@", topic);
                if ([topic isEqual:self.currentTopic]) {
                    self.currentTopic = nil;
                }
                [self.managedObjectContext deleteObject:topic];
            }
        }
    }

    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

/**
 Fetch all `ReaderTopics` for the menu currently in Core Data.

 @return An array of all `ReaderTopics` for the menu currently persisted in Core Data.
 */
- (NSArray *)allMenuTopics
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"isMenuItem = YES"];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    return results;
}

/**
 Fetch all `ReaderTopics` currently in Core Data.

 @return An array of all `ReaderTopics` currently persisted in Core Data.
 */
- (NSArray *)allTopics
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    return results;
}

/**
 Find a specific ReaderTopic by its `path` property.

 @param path The unique, cannonical path of the topic.
 @return A matching `ReaderTopic` or nil if there is no match.
 */
- (ReaderTopic *)findWithPath:(NSString *)path
{
    NSArray *results = [[self allTopics] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path = %@", [path lowercaseString]]];
    return [results firstObject];
}

@end
