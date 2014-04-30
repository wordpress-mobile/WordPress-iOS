#import "ReaderTopicService.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "ReaderTopic.h"
#import "ReaderTopicServiceRemote.h"
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
    NSString *topicURIString = [[NSUserDefaults standardUserDefaults] stringForKey:ReaderTopicCurrentTopicURIKey];
    if (topicURIString) {
        NSURL *topicURI = [NSURL URLWithString:topicURIString];
        NSManagedObjectID *objectID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:topicURI];
        if (objectID) {
            topic = (ReaderTopic *)[self.managedObjectContext objectRegisteredForID:objectID];
        }
    }

    if (topic == nil) {
        [self setCurrentTopic:nil];
        // Return a default topic
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
        request.predicate = [NSPredicate predicateWithFormat:@"type == %@", ReaderTopicTypeList];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        request.sortDescriptors = @[sortDescriptor];
        NSError *error;
        NSArray *topics = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"-[ReaderTopicService currentTopic] error fetching topic: %@", error);
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (!topic) {
        [defaults removeObjectForKey:ReaderTopicCurrentTopicURIKey];
        [defaults synchronize];
        return;
    }

    NSURL *topicURI = topic.objectID.URIRepresentation;
    [[NSUserDefaults standardUserDefaults] setObject:[topicURI absoluteString] forKey:ReaderTopicCurrentTopicURIKey];
    [NSUserDefaults resetStandardUserDefaults];
}

- (NSUInteger)numberOfSubscribedTopics {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES AND type == %@", ReaderTopicTypeTag];
    NSError *error;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"-[ReaderTopicService numberOfSubscribedTopics] error counting topics: %@", error);
        return 0;
    }
    return count;
}


#pragma mark - Private Methods

/**
 Create a new ReaderTopic or update an existing ReaderTopic.
 
 @param dict A dictionary representing a ReaderTopic. Expects the following keys:
 `ID`, `title`, `URL`, `isSubscribed`, `isRecommended`.
 @return A new or updated, but unsaved, ReaderTopic.
 */
- (ReaderTopic *)createOrReplaceFromDictionary:(NSDictionary *)dict {
    NSString *path = [dict stringForKey:@"path"];
    
    if (path == nil) {
        return nil;
    }

    NSString *title = [dict stringForKey:@"title"];
    if (title == nil) {
        return nil;
    }
    
    ReaderTopic *topic = [self findWithPath:path];
    if (topic == nil) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderTopic"
                                              inManagedObjectContext:self.managedObjectContext];
    }
    
    topic.topicID = [dict numberForKey:@"topicID"];
    topic.type = ([topic.topicID integerValue] == 0) ? ReaderTopicTypeList : ReaderTopicTypeTag;
    topic.title = title;
    topic.path = [path lowercaseString];
    topic.isSubscribed = [[dict numberForKey:@"isSubscribed"] boolValue];
    topic.isRecommended = [[dict numberForKey:@"isRecommended"] boolValue];
    
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
    
    for (NSDictionary *dict in topics) {
        ReaderTopic *newTopic = [self createOrReplaceFromDictionary:dict];
        newTopic.account = account;
        if (newTopic != nil) {
            [topicsToKeep addObject:newTopic];
        } else {
            DDLogInfo(@"-[ReaderTopic createOrReplaceFromDictionary:] returned a nil topic: %@", dict);
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
        DDLogError(@"-[ReaderTopic allTopics] error executing fetch request: %@", error);
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
    if (results && [results count] > 0) {
        return [results objectAtIndex:0];
    }
    return nil;
}

@end
