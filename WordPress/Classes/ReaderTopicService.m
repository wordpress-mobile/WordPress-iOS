#import "ReaderTopicService.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "ReaderTopic.h"
#import "ReaderTopicServiceRemote.h"
#import "WPAccount.h"
#import "WordPressComApi.h"

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
        [self.managedObjectContext performBlockAndWait:^{
            [self mergeTopics:topics];
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

#pragma mark - Private Methods

/**
 Create a new ReaderTopic or update an existing ReaderTopic.
 
 @param dict A dictionary representing a ReaderTopic. Expects the following keys:
 `ID`, `title`, `URL`, `isSubscribed`, `isRecommended`.
 @return A new or updated, but unsaved, ReaderTopic.
 */
- (ReaderTopic *)createOrReplaceFromDictionary:(NSDictionary *)dict {
    NSString *path = [dict stringForKey:@"URL"];
    
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
    
    topic.topicID = [dict numberForKey:@"ID"];
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
- (void)mergeTopics:(NSArray *)topics {
    NSArray *currentTopics = [self allTopics];
    NSMutableArray *topicsToKeep = [NSMutableArray array];
    
    for (NSDictionary *dict in topics) {
        ReaderTopic *newTopic = [self createOrReplaceFromDictionary:dict];
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

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
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
