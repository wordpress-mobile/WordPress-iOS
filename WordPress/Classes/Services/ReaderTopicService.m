#import "ReaderTopicService.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "NSString+XMLExtensions.h"
#import "ReaderTopic.h"
#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "WPAccount.h"
#import "WordPressComApi.h"

NSString *const ReaderTopicCurrentTopicURIKey = @"ReaderTopicCurrentTopicURIKey";

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
    WordPressComApi *api = [defaultAccount restApi];
    if (![api hasCredentials]) {
        api = [WordPressComApi anonymousApi];
    }
    
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithRemoteApi:api];
    [remoteService fetchReaderMenuWithSuccess:^(NSArray *topics) {
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
            if (topic.type == ReaderTopicTypeTag && topic.isSubscribed == NO) {
                topic = nil;
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

- (void)setCurrentTopic:(ReaderTopic *)topic {
    if (!topic) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderTopicCurrentTopicURIKey];
    } else {
        if ([topic.objectID isTemporaryID]) {
            NSError *error;
            if (![self.managedObjectContext obtainPermanentIDsForObjects:@[topic] error:&error]) {
                DDLogError(@"Error obtaining permanent object ID for topic %@, %@", topic, error);
            }
        }
        NSURL *topicURI = topic.objectID.URIRepresentation;
        [[NSUserDefaults standardUserDefaults] setObject:[topicURI absoluteString] forKey:ReaderTopicCurrentTopicURIKey];
    }
    [NSUserDefaults resetStandardUserDefaults];

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

#pragma mark - Private Methods

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

@end
