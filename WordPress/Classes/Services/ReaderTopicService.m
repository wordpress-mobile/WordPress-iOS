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
#import <WordPressApi/WordPressApi.h>

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

- (void)deleteNonMenuTopics
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"showInMenu = false"];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderAbstractTopic *topic in results) {
        [self.managedObjectContext deleteObject:topic];
    }
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
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

- (void)unfollowAndRefreshCurrentTopicForTag:(ReaderTagTopic *)topic withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    BOOL deletingCurrentTopic = [topic isEqual:self.currentTopic];
    [self unfollowTag:topic withSuccess:^{
        if (deletingCurrentTopic) {
            [self setCurrentTopic:nil];
            [self currentTopic];
        }
        if (success) {
            success();
        }
    } failure:failure];

}

- (void)unfollowTag:(ReaderTagTopic *)topic withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    // Optimistically unfollow the topic
    topic.following = NO;
    if (!topic.isRecommended) {
        topic.showInMenu = NO;
    }
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    NSString *slug = topic.slug;
    if (!slug) {
        // Fallback. It *shouldn't* happen, but we've had a couple of crash reports
        // indicating a topic slug was nil.
        // Theory is the slug is missing from the REST API resutls for some reason.
        // Create a slug from the topic title as a fallback.
        slug = [remoteService slugForTopicName:topic.title];
    }

    // Now do it for realz.
    NSDictionary *properties = @{@"tag":slug};

    [remoteService unfollowTopicWithSlug:slug withSuccess:^(NSNumber *topicID) {
        [WPAnalytics track:WPAnalyticsStatReaderTagUnfollowed withProperties:properties];
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error unfollowing topic: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];
}

- (void)followTagNamed:(NSString *)topicName withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    topicName = [[topicName lowercaseString] trim];

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService followTopicNamed:topicName withSuccess:^(NSNumber *topicID) {
        [self fetchReaderMenuWithSuccess:^{
            [WPAnalytics track:WPAnalyticsStatReaderTagFollowed];
            [self selectTopicWithID:topicID];
            if (success) {
                success();
            }
        } failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error following topic by name: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];
}

- (void)followTagWithSlug:(NSString *)slug withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService followTopicWithSlug:slug withSuccess:^(NSNumber *topicID) {
        [WPAnalytics track:WPAnalyticsStatReaderTagFollowed];
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error following topic by name: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];

}

- (void)toggleFollowingForTag:(ReaderTagTopic *)tagTopic success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSError *error;
    ReaderTagTopic *topic = (ReaderTagTopic *)[self.managedObjectContext existingObjectWithID:tagTopic.objectID error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        if (failure) {
            failure(error);
        }
        return;
    }

    // Keep previous values in case of failure
    BOOL oldFollowingValue = topic.following;
    BOOL oldShowInMenuValue = topic.showInMenu;

    // Optimistically update and save
    topic.following = !topic.following;
    if (topic.following) {
        topic.showInMenu = YES;
    }
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        // Revert changes on failure
        topic.following = oldFollowingValue;
        topic.showInMenu = oldShowInMenuValue;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        if (failure) {
            failure(error);
        }
    };

    if (topic.following) {
        [self followTagWithSlug:topic.slug withSuccess:success failure:failureBlock];
    } else {
        [self unfollowTag:topic withSuccess:success failure:failureBlock];
    }
}

- (void)tagTopicForTagWithSlug:(NSString *)slug success:(void(^)(NSManagedObjectID *objectID))success failure:(void (^)(NSError *error))failure
{
    if (!success) {
        return;
    }

    // Find existing tag by slug
    ReaderTagTopic *existingTopic = [self findTagWithSlug:slug];
    if (existingTopic) {
        dispatch_async(dispatch_get_main_queue(), ^{
            success(existingTopic.objectID);
        });
        return;
    }

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService fetchTagInfoForTagWithSlug:slug success:^(RemoteReaderTopic *remoteTopic) {
        ReaderTagTopic *topic = [self tagTopicForRemoteTopic:remoteTopic];
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
            success(topic.objectID);
        }];
    } failure:^(NSError *error) {
        DDLogError(@"%@ error fetching site info for site with ID %@: %@", NSStringFromSelector(_cmd), slug, error);
        if (failure) {
            failure(error);
        }
    }];
}


- (void)toggleFollowingForSite:(ReaderSiteTopic *)siteTopic success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSError *error;
    ReaderSiteTopic *topic = (ReaderSiteTopic *)[self.managedObjectContext existingObjectWithID:siteTopic.objectID error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        if (failure) {
            failure(error);
        }
        return;
    }

    // Keep previous values in case of failure
    BOOL oldFollowValue = topic.following;
    BOOL newFollowValue = !oldFollowValue;

    NSNumber *siteIDForPostService = topic.isExternal ? topic.feedID : topic.siteID;
    NSString *siteURLForPostService = topic.siteURL;

    // Optimistically update
    topic.following = newFollowValue;
    ReaderPostService *postService = [[ReaderPostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [postService setFollowing:newFollowValue forPostsFromSiteWithID:siteIDForPostService andURL:siteURLForPostService];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        // Revert changes on failure
        topic.following = oldFollowValue;
        [postService setFollowing:oldFollowValue forPostsFromSiteWithID:siteIDForPostService andURL:siteURLForPostService];
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

        if (failure) {
            failure(error);
        }
    };

    ReaderSiteService *siteService = [[ReaderSiteService alloc] initWithManagedObjectContext:self.managedObjectContext];
    if (topic.isExternal) {
        if (newFollowValue) {
            [siteService followSiteAtURL:topic.siteURL success:success failure:failureBlock];
        } else {
            [siteService unfollowSiteAtURL:topic.siteURL success:success failure:failureBlock];
        }
    } else {
        if (newFollowValue) {
            [siteService followSiteWithID:[topic.siteID integerValue] success:success failure:failureBlock];
        } else {
            [siteService unfollowSiteWithID:[topic.siteID integerValue] success:success failure:failureBlock];
        }
    }
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
                        isFeed:(BOOL)isFeed
                       success:(void (^)(NSManagedObjectID *objectID, BOOL isFollowing))success
                       failure:(void (^)(NSError *error))failure
{
    ReaderSiteTopic *siteTopic = [self findSiteTopicWithSiteID:siteID];
    if (siteTopic) {
        if (success) {
            success(siteTopic.objectID, siteTopic.following);
        }
        return;
    }

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService fetchSiteInfoForSiteWithID:siteID isFeed:isFeed success:^(RemoteReaderSiteInfo *siteInfo) {
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
        topic.showInMenu = NO;
        topic.siteBlavatar = siteInfo.siteBlavatar;
        topic.siteDescription = siteInfo.siteDescription;
        topic.siteID = siteInfo.siteID;
        topic.siteURL = siteInfo.siteURL;
        topic.subscriberCount = siteInfo.subscriberCount;
        topic.title = siteInfo.siteName;
        topic.type = ReaderSiteTopic.TopicType;
        if (isFeed) {
            topic.path = [NSString stringWithFormat:@"%@read/feed/%@/posts/", WordPressRestApiEndpointURL, siteInfo.feedID];
        } else {
            topic.path = [NSString stringWithFormat:@"%@read/sites/%@/posts/", WordPressRestApiEndpointURL, siteInfo.siteID];
        }

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
 @return A matching `ReaderTagTopic` instance or nil.
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
 Find an existing topic with the specified slug.

 @param slug The slug of the topic to find in core data.
 @return A matching `ReaderTagTopic` instance or nil.
 */
- (ReaderTagTopic *)findTagWithSlug:(NSString *)slug
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderTagTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"slug = %@", slug];

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
 @return A matching `ReaderTagTopic` instance or nil.
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
    topic.owner = remoteTopic.owner;
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

- (ReaderSiteTopic *)findSiteTopicWithSiteID:(NSNumber *)siteID
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderSiteTopic classNameWithoutNamespaces]];
    request.predicate = [NSPredicate predicateWithFormat:@"siteID = %@", siteID];
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    return (ReaderSiteTopic *)[results firstObject];
}


@end
