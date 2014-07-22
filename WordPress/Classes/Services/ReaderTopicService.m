#import "ReaderTopicService.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "NSString+XMLExtensions.h"
#import "ReaderTopic.h"
#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "WPAccount.h"
#import "WordPressComApi.h"

NSString * const ReaderTopicDidChangeViaUserInteractionNotification = @"ReaderTopicDidChangeViaUserInteractionNotification";
NSString * const ReaderTopicDidChangeNotification = @"ReaderTopicDidChangeNotification";
NSString * const ReaderTopicServiceErrorDomain = @"ReaderTopicServiceErrorDomain";
static NSString *const ReaderTopicCurrentTopicURIKey = @"ReaderTopicCurrentTopicURIKey";

@interface ReaderTopicService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation ReaderTopicService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    
    return self;
}

- (void)fetchReaderMenuWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    if (!defaultAccount) {
        failure([self errorForMissingAccount]);
        return;
    }

    WordPressComApi *api = [defaultAccount restApi];
    if (![api hasCredentials]) {
        api = [WordPressComApi anonymousApi];
    }
    
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithRemoteApi:api];
    [remoteService fetchReaderMenuWithSuccess:^(NSArray *topics) {
        if (defaultAccount.isDeleted) {
            failure([self errorForMissingAccount]);
            return;
        }
        [self mergeTopics:topics forAccount:defaultAccount];
        [self.managedObjectContext performBlockAndWait:^{
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }];
        
        if (success) {
            success();
        }
        
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (ReaderTopic *)currentTopic {
    ReaderTopic *topic;
    NSError *error;
    NSString *topicURIString = [[NSUserDefaults standardUserDefaults] stringForKey:ReaderTopicCurrentTopicURIKey];
    if (topicURIString) {
        NSURL *topicURI = [NSURL URLWithString:topicURIString];
        NSManagedObjectID *objectID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:topicURI];
        if (objectID) {
            topic = (ReaderTopic *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
            if (error) {
                DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
            }
        }
    }

    if (topic == nil) {
        [self setCurrentTopic:nil];
        // Return a default topic
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
        request.predicate = [NSPredicate predicateWithFormat:@"type == %@", ReaderTopicTypeList];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        request.sortDescriptors = @[sortDescriptor];
        NSArray *topics = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
			return nil;
        }
        if ([topics count] > 0) {
            topic = [topics objectAtIndex:0];
            [self setCurrentTopic:topic];
        }
    }

    return topic;
}

- (void)setCurrentTopic:(ReaderTopic *)topic
{
    if (!topic) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderTopicCurrentTopicURIKey];
        [NSUserDefaults resetStandardUserDefaults];
    } else {
        if ([topic.objectID isTemporaryID]) {
            [[ContextManager sharedInstance] obtainPermanentIDForObject:topic];
        }
        NSURL *topicURI = topic.objectID.URIRepresentation;
        [[NSUserDefaults standardUserDefaults] setObject:[topicURI absoluteString] forKey:ReaderTopicCurrentTopicURIKey];
        [NSUserDefaults resetStandardUserDefaults];
        [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeNotification object:nil];
    }
}

- (NSUInteger)numberOfSubscribedTopics {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES AND type == %@", ReaderTopicTypeTag];
    NSError *error;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error counting topics: %@", NSStringFromSelector(_cmd), error);
        return 0;
    }
    return count;
}

- (void)deleteAllTopics {
    [self setCurrentTopic:nil];
    NSArray *currentTopics = [self allTopics];
    for (ReaderTopic *topic in currentTopics) {
        [self.managedObjectContext deleteObject:topic];
    }
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
    [remoteService followTopicNamed:topicName withSuccess:^{
        // noop
    } failure:^(NSError *error) {
        DDLogError(@"%@ error following topic: %@", NSStringFromSelector(_cmd), error);
    }];

}

- (void)unfollowTopic:(ReaderTopic *)topic withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSString *topicName = [topic.title trim];

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
    [remoteService unfollowTopicNamed:topicName withSuccess:^{
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
    [remoteService followTopicNamed:topicName withSuccess:^{
        [self fetchReaderMenuWithSuccess:^{
            [self selectTopicNamed:topicName];
        } failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error following topic by name: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];
}


#pragma mark - Private Methods

/**
 Get the api to use for the request.
 */
- (WordPressComApi *)apiForRequest {
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
 Find an existing topic with the specified title. 
 
 @param topicName The title of the topic to find in core data. 
 @return A matching `ReaderTopic` instance or nil.
 */
- (ReaderTopic *)findTopicNamed:(NSString *)topicName
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] %@", topicName];

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
    return [topics objectAtIndex:0];
}

/**
 Create a new `ReaderTopic` or update an existing `ReaderTopic`.
 
 @param dict A `RemoteReaderTopic` object.
 @return A new or updated, but unsaved, `ReaderTopic`.
 */
- (ReaderTopic *)createOrReplaceFromRemoteTopic:(RemoteReaderTopic *)remoteTopic {
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
    topic.type = ([topic.topicID integerValue] == 0) ? ReaderTopicTypeList : ReaderTopicTypeTag;
    topic.title = [title stringByDecodingXMLCharacters];
    topic.path = [path lowercaseString];
    topic.isSubscribed = remoteTopic.isSubscribed;
    topic.isRecommended = remoteTopic.isRecommended;
    
    return topic;
}

/**
 Saves the specified `ReaderTopics`. Any `ReaderTopics` not included in the passed
 array are removed from Core Data.
 
 @param topics An array of `ReaderTopics` to save.
 */
- (void)mergeTopics:(NSArray *)topics forAccount:(WPAccount *)account {
    NSArray *currentTopics = [self allTopics];
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
    
    if (currentTopics && [currentTopics count] > 0) {
        for (ReaderTopic *topic in currentTopics) {
            if (![topicsToKeep containsObject:topic]) {
                DDLogInfo(@"Deleting ReaderTopic: %@", topic);
                if ([topic isEqual:self.currentTopic]) {
                    self.currentTopic = nil;
                }
                [self.managedObjectContext deleteObject:topic];
            }
        }
    }
}

/**
 Fetch all `ReaderTopics` currently in Core Data.
 
 @return An array of all `ReaderTopics` currently persisted in Core Data.
 */
- (NSArray *)allTopics {
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
- (ReaderTopic *)findWithPath:(NSString *)path {
    NSArray *results = [[self allTopics] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path == %@", [path lowercaseString]]];
    return [results firstObject];
}

/**
 Standard error message for when syncing the menu when an account is missing or deleted.
 */
- (NSError *)errorForMissingAccount
{
    NSString *description = NSLocalizedString(@"Unable to fetch a list of topics because the default account was nil or deleted.", @"A message describing an error occuring when syncing the reader menu when the default WordPress.com account is missing or deleted.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description};
    NSError *error = [NSError errorWithDomain:ReaderTopicServiceErrorDomain code:ReaderTopicServiceErrorNoAccount userInfo:userInfo];
    return error;
}

@end
