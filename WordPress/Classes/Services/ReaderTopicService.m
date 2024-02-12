#import "ReaderTopicService.h"

#import "AccountService.h"
#import "CoreDataStack.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "WPAccount.h"
#import <WordPressShared/NSString+XMLExtensions.h>
#import "WordPress-Swift.h"
@import WordPressKit;


NSString * const ReaderTopicFreshlyPressedPathCommponent = @"freshly-pressed";
static NSString * const ReaderTopicCurrentTopicPathKey = @"ReaderTopicCurrentTopicPathKey";

@implementation ReaderTopicService

- (void)fetchReaderMenuWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        WPAccount *defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext: context];

        // Keep a reference to the NSManagedObjectID (if it exists).
        // We'll use it to verify that the account did not change while fetching topics.
        ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequestInContext:context]];
        [remoteService fetchReaderMenuWithSuccess:^(NSArray *topics) {

            NSAssert(NSThread.isMainThread, @"This callback must be dispatched on the main thread");
            WPAccount *reloadedAccount = [WPAccount lookupDefaultWordPressComAccountInContext:self.coreDataStack.mainContext];

            // Make sure that we have the same account now that we did when we started.
            if ((!defaultAccount && !reloadedAccount) || [defaultAccount.objectID isEqual:reloadedAccount.objectID]) {
                // If both accounts are nil, or if both accounts exist and are identical we're good to go.
            } else {
                // The account changed so our results are invalid. Fetch them anew!
                [self fetchReaderMenuWithSuccess:success failure:failure];
                return;
            }

            [self mergeMenuTopics:topics withSuccess:success];

        } failure:failure];
    } completion:nil onQueue:dispatch_get_main_queue()];
}

- (void)fetchFollowedSitesWithSuccess:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    ReaderTopicServiceRemote *service = [[ReaderTopicServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [service fetchFollowedSitesWithSuccess:^(NSArray *sites) {
        [WPAnalytics setSubscriptionCount: sites.count];
        [self mergeFollowedSites:sites withSuccess:success];
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (ReaderAbstractTopic *)currentTopicInContext:(NSManagedObjectContext *)context
{
    ReaderAbstractTopic *topic;
    topic = [self currentTopicFromSavedPathInContext:context];

    if (!topic) {
        topic = [self currentTopicFromDefaultTopicInContext:context];
        [self setCurrentTopic:topic];
    }

    return topic;
}

- (ReaderAbstractTopic *)currentTopicFromSavedPathInContext:(NSManagedObjectContext *)context
{
    ReaderAbstractTopic *topic;
    NSString *topicPathString = [[UserPersistentStoreFactory userDefaultsInstance] stringForKey:ReaderTopicCurrentTopicPathKey];
    if (topicPathString) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
        request.predicate = [NSPredicate predicateWithFormat:@"path = %@", topicPathString];

        NSError *error;
        topic = [[context executeFetchRequest:request error:&error] firstObject];
        if (error) {
            DDLogError(@"%@ error fetching topic: %@", NSStringFromSelector(_cmd), error);
        }
    }
    return topic;
}

- (ReaderAbstractTopic *)currentTopicFromDefaultTopicInContext:(NSManagedObjectContext *)context
{
    // Return the default topic
    ReaderAbstractTopic *topic;
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderDefaultTopic classNameWithoutNamespaces]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSArray *topics = [context executeFetchRequest:request error:&error];
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
        [[UserPersistentStoreFactory userDefaultsInstance] removeObjectForKey:ReaderTopicCurrentTopicPathKey];
    } else {
        [[UserPersistentStoreFactory userDefaultsInstance] setObject:topic.path forKey:ReaderTopicCurrentTopicPathKey];
    }
}

- (void)deleteAllSearchTopics
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderSearchTopic classNameWithoutNamespaces]];

        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
            return;
        }

        for (ReaderAbstractTopic *topic in results) {
            DDLogInfo(@"Deleting topic: %@", topic.title);
            [self preserveSavedPostsFromTopic:topic];
            [context deleteObject:topic];
        }
    }];
}

- (void)deleteNonMenuTopics
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
        request.predicate = [NSPredicate predicateWithFormat:@"showInMenu = false AND inUse = false"];

        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
            return;
        }

        for (ReaderAbstractTopic *topic in results) {
            // Do not purge site topics that are followed. We want these to stay so they appear immediately when managing followed sites.
            if ([topic isKindOfClass:[ReaderSiteTopic class]] && topic.following) {
                continue;
            }
            DDLogInfo(@"Deleting topic: %@", topic.title);
            [self preserveSavedPostsFromTopic:topic];
            [context deleteObject:topic];
        }
    }];
}

- (void)clearInUseFlags
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[ReaderAbstractTopic classNameWithoutNamespaces]];
        request.predicate = [NSPredicate predicateWithFormat:@"inUse = true"];
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"%@, marking topic not in use.: %@", NSStringFromSelector(_cmd), error);
            return;
        }

        for (ReaderAbstractTopic *topic in results) {
            topic.inUse = NO;
        }
    }];
}

- (void)deleteAllTopics
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        [self setCurrentTopic:nil];
        NSArray *currentTopics = [ReaderAbstractTopic lookupAllInContext:context error:nil];
        for (ReaderAbstractTopic *topic in currentTopics) {
            DDLogInfo(@"Deleting topic: %@", topic.title);
            [self preserveSavedPostsFromTopic:topic];
            [context deleteObject:topic];
        }
    }];
}

- (void)deleteTopic:(ReaderAbstractTopic *)topic
{
    if (!topic) {
        return;
    }
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderAbstractTopic *topicInContext = [context existingObjectWithID:topic.objectID error:nil];
        if (topicInContext == nil) {
            return;
        }
        [self preserveSavedPostsFromTopic:topicInContext];
        [context deleteObject:topicInContext];
    }];
}

- (void)preserveSavedPostsFromTopic:(ReaderAbstractTopic *)topic
{
    // Copy posts so that `post.topic = nil` doesn't mutate `topic.posts` collection.
    NSMutableArray *posts = [[NSMutableArray alloc] initWithCapacity:topic.posts.count];
    for (id post in topic.posts) {
        [posts addObject:post];
    }

    // Now it's safe to update `post.topic`.
    [posts enumerateObjectsUsingBlock:^(ReaderPost * _Nonnull post, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
        if (post.isSavedForLater) {
            DDLogInfo(@"Preserving saved post: %@", post.titleForDisplay);
            post.topic = nil;
        }
    }];
}

- (void)createSearchTopicForSearchPhrase:(NSString *)phrase completion:(void (^)(NSManagedObjectID *))completion
{
    NSAssert([phrase length] > 0, @"A search phrase is required.");

    NSManagedObjectID * __block topicObjectID = nil;

    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        WordPressComRestApi *api = [WordPressComRestApi defaultApiWithOAuthToken:nil userAgent:[WPUserAgent wordPressUserAgent] localeKey:[WordPressComRestApi LocaleKeyDefault]];
        ReaderPostServiceRemote *remote = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:api];

        NSString *path = [remote endpointUrlForSearchPhrase:[phrase lowercaseString]];
        ReaderSearchTopic *topic = (ReaderSearchTopic *)[ReaderAbstractTopic lookupWithPath:path inContext:context];
        if (!topic || ![topic isKindOfClass:[ReaderSearchTopic class]]) {
            topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderSearchTopic classNameWithoutNamespaces]
                                                  inManagedObjectContext:context];
        }
        topic.type = [ReaderSearchTopic TopicType];
        topic.title = phrase;
        topic.path = path;
        topic.showInMenu = NO;
        topic.following = NO;

        [context obtainPermanentIDsForObjects:@[topic] error:nil];
        topicObjectID = topic.objectID;
    } completion:^{
        // Save / update the search phrase to use it as a suggestion later.
        ReaderSearchSuggestionService *suggestionService = [[ReaderSearchSuggestionService alloc] initWithCoreDataStack:self.coreDataStack];
        [suggestionService createOrUpdateSuggestionForPhrase:phrase];

        if (completion) {
            completion(topicObjectID);
        }
    } onQueue:dispatch_get_main_queue()];
}

- (void)unfollowTag:(ReaderTagTopic *)topic withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    // Optimistically unfollow the topic
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderTagTopic *topicInContext = [context existingObjectWithID:topic.objectID error:nil];
        topicInContext.following = NO;
        if (!topicInContext.isRecommended) {
            topicInContext.showInMenu = NO;
        }
    }];

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
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

    void (^successBlock)(void) = ^{
        [WPAnalytics trackReaderStat:WPAnalyticsStatReaderTagUnfollowed properties:properties];
        if (success) {
            success();
        }
    };

    if (!ReaderHelpers.isLoggedIn) {
        successBlock();
        return;
    }

    [remoteService unfollowTopicWithSlug:slug withSuccess:^(NSNumber * __unused topicID) {
        successBlock();
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error unfollowing topic: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];
}

- (void)followTagNamed:(NSString *)topicName
           withSuccess:(void (^)(void))success
               failure:(void (^)(NSError *error))failure
                source:(NSString *)source
{
    topicName = [[topicName lowercaseString] trim];

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService followTopicNamed:topicName withSuccess:^(NSNumber *topicID) {
        [self fetchReaderMenuWithSuccess:^{
            NSDictionary *properties = @{@"tag":topicName, @"source":source};
            [WPAnalytics trackReaderStat:WPAnalyticsStatReaderTagFollowed properties:properties];
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                [self selectTopicWithID:topicID inContext:context];
            } completion:success onQueue:dispatch_get_main_queue()];
        } failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error following topic by name: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];
}

- (void)followTagWithSlug:(NSString *)slug withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    void (^successBlock)(void) = ^{
        NSDictionary *properties = @{@"tag":slug};
        [WPAnalytics trackReaderStat:WPAnalyticsStatReaderTagFollowed properties:properties];
        if (success) {
            success();
        }
    };

    if (!ReaderHelpers.isLoggedIn) {
        successBlock();
        return;
    }

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService followTopicWithSlug:slug withSuccess:^(NSNumber * __unused topicID) {
        successBlock();
    } failure:^(NSError *error) {
        if (failure) {
            DDLogError(@"%@ error following topic by name: %@", NSStringFromSelector(_cmd), error);
            failure(error);
        }
    }];

}

- (void)toggleFollowingForTag:(ReaderTagTopic *)tagTopic success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    NSAssert(NSThread.isMainThread, @"%s must be called from the main thread", __FUNCTION__);

    NSError *error;
    ReaderTagTopic *topic = (ReaderTagTopic *)[self.coreDataStack.mainContext existingObjectWithID:tagTopic.objectID error:&error];
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
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext * __unused context) {
        ReaderTagTopic *topicInContext = (ReaderTagTopic *)[self.coreDataStack.mainContext existingObjectWithID:tagTopic.objectID error:nil];
        topicInContext.following = !oldFollowingValue;
        if (topicInContext.following) {
            topicInContext.showInMenu = YES;
        }
    }];

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        // Revert changes on failure
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext * __unused context) {
            ReaderTagTopic *topicInContext = (ReaderTagTopic *)[self.coreDataStack.mainContext existingObjectWithID:tagTopic.objectID error:nil];
            topicInContext.following = oldFollowingValue;
            topicInContext.showInMenu = oldShowInMenuValue;
        } completion:^{
            if (failure) {
                failure(error);
            }
        } onQueue:dispatch_get_main_queue()];
    };

    if (!oldFollowingValue) {
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
    NSManagedObjectID * __block existingTopic = nil;
    [self.coreDataStack.mainContext performBlockAndWait:^{
        existingTopic = [[ReaderTagTopic lookupWithSlug:slug inContext:self.coreDataStack.mainContext] objectID];
    }];
    if (existingTopic) {
        dispatch_async(dispatch_get_main_queue(), ^{
            success(existingTopic);
        });
        return;
    }

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService fetchTagInfoForTagWithSlug:slug success:^(RemoteReaderTopic *remoteTopic) {
        NSManagedObjectID * __block topicObjectID = nil;
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            ReaderTagTopic *topic = [self tagTopicForRemoteTopic:remoteTopic inContext:context];
            [context obtainPermanentIDsForObjects:@[topic] error:nil];
            topicObjectID = topic.objectID;
        } completion:^{
            success(topicObjectID);
        } onQueue:dispatch_get_main_queue()];
    } failure:^(NSError *error) {
        DDLogError(@"%@ error fetching site info for site with ID %@: %@", NSStringFromSelector(_cmd), slug, error);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)toggleFollowingForSite:(ReaderSiteTopic *)siteTopic
                       success:(void (^)(BOOL follow))success
                       failure:(void (^)(BOOL follow, NSError *error))failure
{
    NSAssert(NSThread.isMainThread, @"%s must be called from the main thread", __FUNCTION__);

    NSError *error;
    ReaderSiteTopic *topic = (ReaderSiteTopic *)[self.coreDataStack.mainContext existingObjectWithID:siteTopic.objectID error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        if (failure) {
            failure(true, error);
        }
        return;
    }

    // Keep previous values in case of failure
    BOOL oldFollowValue = topic.following;
    BOOL newFollowValue = !oldFollowValue;

    NSNumber *siteIDForPostService = topic.isExternal ? topic.feedID : topic.siteID;
    NSString *siteURLForPostService = topic.siteURL;

    // Optimistically update
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderSiteTopic *topicInContext = (ReaderSiteTopic *)[context existingObjectWithID:siteTopic.objectID error:nil];
        topicInContext.following = newFollowValue;
    }];

    ReaderPostService *postService = [[ReaderPostService alloc] initWithCoreDataStack:self.coreDataStack];
    [postService setFollowing:newFollowValue forPostsFromSiteWithID:siteIDForPostService andURL:siteURLForPostService];

    // Define success block
    void (^successBlock)(void) = ^void() {
        
        // Update subscription count
        NSInteger oldSubscriptionCount = [WPAnalytics subscriptionCount];
        NSInteger newSubscriptionCount = newFollowValue ? oldSubscriptionCount + 1 : oldSubscriptionCount - 1;
        [WPAnalytics setSubscriptionCount:newSubscriptionCount];
        
        [self refreshPostsForFollowedTopic];
        
        if (success) {
            success(newFollowValue);
        }
    };

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        BOOL alreadyFollowing = newFollowValue && error.domain == ReaderSiteServiceErrorDomain && error.code == ReaderSiteServiceErrorAlreadyFollowingSite;
        BOOL alreadyUnsubscribed = !newFollowValue && [error.userInfo[WordPressComRestApi.ErrorKeyErrorCode] isEqual:@"are_not_subscribed"];
        BOOL successWithoutChanges = alreadyFollowing || alreadyUnsubscribed;
            
        if (successWithoutChanges) {
            successBlock();
            return;
        }
     
        // Revert changes on failure, unless the error is that we're already following
        // a site.
        [postService setFollowing:oldFollowValue forPostsFromSiteWithID:siteIDForPostService andURL:siteURLForPostService];
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            ReaderSiteTopic *topicInContext = (ReaderSiteTopic *)[context existingObjectWithID:siteTopic.objectID error:nil];
            topicInContext.following = oldFollowValue;
        } completion:^{
            if (failure) {
                failure(newFollowValue, error);
            }
        } onQueue:dispatch_get_main_queue()];
    };

    ReaderSiteService *siteService = [[ReaderSiteService alloc] initWithCoreDataStack:self.coreDataStack];
    if (topic.isExternal) {
        if (newFollowValue) {
            [siteService followSiteAtURL:topic.feedURL success:successBlock failure:failureBlock];
        } else {
            [siteService unfollowSiteAtURL:topic.feedURL success:successBlock failure:failureBlock];
        }
    } else {
        if (newFollowValue) {
            [siteService followSiteWithID:[topic.siteID integerValue] success:successBlock failure:failureBlock];
        } else {
            // Try to unfollow by ID as its the most reliable method.
            // Note that if the site has been deleted, attempting to unfollow by ID
            // results in an HTTP 403 on the v1.1 endpoint.  If this happens try
            // unfollowing via the less reliable URL method.
            [siteService unfollowSiteWithID:[topic.siteID integerValue] success:successBlock failure:^(NSError *error) {
                if (error.code == WordPressComRestApiErrorCodeAuthorizationRequired) {
                    [siteService unfollowSiteAtURL:topic.siteURL success:successBlock failure:failureBlock];
                    return;
                }
                failureBlock(error);
            }];
        }
    }
}

- (void)refreshPostsForFollowedTopic
{
    ReaderPostService *postService = [[ReaderPostService alloc] initWithCoreDataStack:self.coreDataStack];
    [postService refreshPostsForFollowedTopic];
}

- (void)siteTopicForSiteWithID:(NSNumber *)siteID
                        isFeed:(BOOL)isFeed
                       success:(void (^)(NSManagedObjectID *objectID, BOOL isFollowing))success
                       failure:(void (^)(NSError *error))failure
{
    ReaderSiteTopic * __block siteTopic = nil;

    [self.coreDataStack.mainContext performBlockAndWait:^{
        if (isFeed) {
            siteTopic = [ReaderSiteTopic lookupWithFeedID:siteID inContext:self.coreDataStack.mainContext];
        } else {
            siteTopic = [ReaderSiteTopic lookupWithSiteID:siteID inContext:self.coreDataStack.mainContext];
        }
    }];

    if (siteTopic) {
        if (success) {
            success(siteTopic.objectID, siteTopic.following);
        }
        return;
    }

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService fetchSiteInfoForSiteWithID:siteID isFeed:isFeed success:^(RemoteReaderSiteInfo *siteInfo) {
        if (!success) {
            return;
        }

        NSManagedObjectID * __block topicObjectID = nil;
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            ReaderSiteTopic *topic = [self siteTopicForRemoteSiteInfo:siteInfo inContext:context];
            [context obtainPermanentIDsForObjects:@[topic] error:nil];
            topicObjectID = topic.objectID;
        } completion:^{
            success(topicObjectID, siteInfo.isFollowing);
        } onQueue:dispatch_get_main_queue()];
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
- (WordPressComRestApi *)apiForRequestInContext:(NSManagedObjectContext *)context
{
    WPAccount *defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:context];
    WordPressComRestApi *api = [defaultAccount wordPressComRestApi];
    if (![api hasCredentials]) {
        api = [WordPressComRestApi defaultApiWithOAuthToken:nil userAgent:[WPUserAgent wordPressUserAgent] localeKey:[WordPressComRestApi LocaleKeyDefault]];
    }
    return api;
}

- (WordPressComRestApi *)apiForRequest
{
    WordPressComRestApi * __block api = nil;
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        api = [self apiForRequestInContext:context];
    }];
    return api;
}

/**
 Finds an existing topic matching the specified topicID and, if found, makes it the
 selected topic.
 */
- (void)selectTopicWithID:(NSNumber *)topicID inContext:(NSManagedObjectContext *)context
{
    ReaderAbstractTopic *topic = [ReaderTagTopic lookupWithTagID:topicID inContext:context];
    [self setCurrentTopic:topic];
}

/**
 Create a new `ReaderAbstractTopic` or update an existing `ReaderAbstractTopic`.

 @param dict A `RemoteReaderTopic` object.
 @return A new or updated, but unsaved, `ReaderAbstractTopic`.
 */
- (ReaderAbstractTopic *)createOrReplaceFromRemoteTopic:(RemoteReaderTopic *)remoteTopic inContext:(NSManagedObjectContext *)context
{
    NSString *path = remoteTopic.path;

    if (path == nil || path.length == 0) {
        return nil;
    }

    NSString *title = remoteTopic.title;
    if (title == nil || title.length == 0) {
        return nil;
    }

    ReaderAbstractTopic *topic = [self topicForRemoteTopic:remoteTopic inContext:context];
    return topic;
}

- (ReaderAbstractTopic *)topicForRemoteTopic:(RemoteReaderTopic *)remoteTopic inContext:(NSManagedObjectContext *)context
{
    if ([remoteTopic.path rangeOfString:@"/tags/"].location != NSNotFound) {
        return [self tagTopicForRemoteTopic:remoteTopic inContext:context];
    }

    if ([remoteTopic.path rangeOfString:@"/list/"].location != NSNotFound) {
        return [self listTopicForRemoteTopic:remoteTopic inContext:context];
    }

    if ([remoteTopic.type isEqualToString:@"organization"]) {
        return [self teamTopicForRemoteTopic:remoteTopic inContext:context];
    }

    return [self defaultTopicForRemoteTopic:remoteTopic inContext:context];
}

- (ReaderTagTopic *)tagTopicForRemoteTopic:(RemoteReaderTopic *)remoteTopic inContext:(NSManagedObjectContext *)context
{
    ReaderTagTopic *topic = (ReaderTagTopic *)[ReaderAbstractTopic lookupWithPath:remoteTopic.path inContext:context];
    if (!topic || ![topic isKindOfClass:[ReaderTagTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderTagTopic classNameWithoutNamespaces]
                                                             inManagedObjectContext:context];
    }
    topic.type = [ReaderTagTopic TopicType];
    topic.tagID = remoteTopic.topicID;
    topic.title = remoteTopic.title;
    topic.slug = remoteTopic.slug;
    topic.path = remoteTopic.path;
    topic.showInMenu = remoteTopic.isMenuItem;
    topic.following = remoteTopic.isSubscribed;

    return topic;
}

- (ReaderListTopic *)listTopicForRemoteTopic:(RemoteReaderTopic *)remoteTopic inContext:(NSManagedObjectContext *)context
{
    ReaderListTopic *topic = (ReaderListTopic *)[ReaderAbstractTopic lookupWithPath:remoteTopic.path inContext:context];
    if (!topic || ![topic isKindOfClass:[ReaderListTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderListTopic classNameWithoutNamespaces]
                                              inManagedObjectContext:context];
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

- (ReaderDefaultTopic *)defaultTopicForRemoteTopic:(RemoteReaderTopic *)remoteTopic inContext:(NSManagedObjectContext *)context
{
    ReaderDefaultTopic *topic = (ReaderDefaultTopic *)[ReaderAbstractTopic lookupWithPath:remoteTopic.path inContext:context];
    if (!topic || ![topic isKindOfClass:[ReaderDefaultTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderDefaultTopic classNameWithoutNamespaces]
                                              inManagedObjectContext:context];
    }
    topic.type = [ReaderDefaultTopic TopicType];
    topic.title = [self formatTitle:remoteTopic.title];
    topic.path = remoteTopic.path;
    topic.showInMenu = YES;
    topic.following = YES;

    return topic;
}

- (ReaderTeamTopic *)teamTopicForRemoteTopic:(RemoteReaderTopic *)remoteTopic inContext:(NSManagedObjectContext *)context
{
    ReaderTeamTopic *topic = (ReaderTeamTopic *)[ReaderAbstractTopic lookupWithPath:remoteTopic.path inContext:context];
    if (!topic || ![topic isKindOfClass:[ReaderTeamTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderTeamTopic classNameWithoutNamespaces]
                                              inManagedObjectContext:context];
    }
    topic.type = [ReaderTeamTopic TopicType];
    topic.title = [self formatTitle:remoteTopic.title];
    topic.slug = remoteTopic.slug;
    topic.path = remoteTopic.path;
    topic.showInMenu = YES;
    topic.following = YES;
    topic.organizationID = [remoteTopic.organizationID integerValue];

    return topic;
}

- (ReaderSiteTopic *)siteTopicForRemoteSiteInfo:(RemoteReaderSiteInfo *)siteInfo inContext:(NSManagedObjectContext *)context
{
    ReaderSiteTopic *topic = (ReaderSiteTopic *)[ReaderAbstractTopic lookupWithPath:siteInfo.postsEndpoint inContext:context];
    if (!topic || ![topic isKindOfClass:[ReaderSiteTopic class]]) {
        topic = [NSEntityDescription insertNewObjectForEntityForName:[ReaderSiteTopic classNameWithoutNamespaces]
                                              inManagedObjectContext:context];
    }

    topic.feedID = siteInfo.feedID;
    topic.feedURL = siteInfo.feedURL;
    topic.following = siteInfo.isFollowing;
    topic.isJetpack = siteInfo.isJetpack;
    topic.isPrivate = siteInfo.isPrivate;
    topic.isVisible = siteInfo.isVisible;
    topic.organizationID = [siteInfo.organizationID integerValue];
    topic.path = siteInfo.postsEndpoint;
    topic.postCount = siteInfo.postCount;
    topic.showInMenu = NO;
    topic.siteBlavatar = siteInfo.siteBlavatar;
    topic.siteDescription = siteInfo.siteDescription;
    topic.siteID = siteInfo.siteID;
    topic.siteURL = siteInfo.siteURL;
    topic.subscriberCount = siteInfo.subscriberCount;
    topic.title = siteInfo.siteName;
    topic.type = ReaderSiteTopic.TopicType;
    topic.unseenCount = [siteInfo.unseenCount integerValue];
    
    topic.postSubscription = [self postSubscriptionFor:siteInfo topic:topic inContext:context];
    topic.emailSubscription = [self emailSubscriptionFor:siteInfo topic:topic inContext:context];

    return topic;
}

- (ReaderSiteInfoSubscriptionPost *)postSubscriptionFor:(RemoteReaderSiteInfo *)siteInfo topic:(ReaderSiteTopic *)topic inContext:(NSManagedObjectContext *)context
{
    if (![siteInfo.postSubscription wp_isValidObject]) {
        return nil;
    }
    
    ReaderSiteInfoSubscriptionPost *postSubscription = topic.postSubscription;
    
    if (![postSubscription wp_isValidObject]) {
        postSubscription = [NSEntityDescription insertNewObjectForEntityForName:[ReaderSiteInfoSubscriptionPost classNameWithoutNamespaces]
                                                         inManagedObjectContext:context];
    }
    postSubscription.siteTopic = topic;
    return postSubscription;
}

- (ReaderSiteInfoSubscriptionEmail *)emailSubscriptionFor:(RemoteReaderSiteInfo *)siteInfo topic:(ReaderSiteTopic *)topic inContext:(NSManagedObjectContext *)context
{
    if (![siteInfo.emailSubscription wp_isValidObject]) {
        return nil;
    }
    
    ReaderSiteInfoSubscriptionEmail *emailSubscription = topic.emailSubscription;
    if (![emailSubscription wp_isValidObject]) {
        emailSubscription = [NSEntityDescription insertNewObjectForEntityForName:[ReaderSiteInfoSubscriptionEmail classNameWithoutNamespaces]
                                                          inManagedObjectContext:context];
    }
    emailSubscription.sendPosts = siteInfo.emailSubscription.sendPosts;
    emailSubscription.sendComments = siteInfo.emailSubscription.sendComments;
    emailSubscription.postDeliveryFrequency = siteInfo.emailSubscription.postDeliveryFrequency;
    return emailSubscription;
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
Saves the specified `ReaderSiteTopics`. Any `ReaderSiteTopics` not included in the passed
array are marked as being unfollowed in Core Data.

@param topics An array of `ReaderSiteTopics` to save.
*/
- (void)mergeFollowedSites:(NSArray *)sites withSuccess:(void (^)(void))success
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSArray *currentSiteTopics = [ReaderAbstractTopic lookupAllSitesInContext:context error:nil];
        NSMutableArray *remoteFeedIds = [NSMutableArray array];

        for (RemoteReaderSiteInfo *siteInfo in sites) {
            if (siteInfo.feedID) {
                [remoteFeedIds addObject:siteInfo.feedID];
            }

            [self siteTopicForRemoteSiteInfo:siteInfo inContext:context];
        }

        for (ReaderSiteTopic *siteTopic in currentSiteTopics) {
            // If a site fetched from Core Data isn't included in the list of sites
            // fetched from remote, that means it's no longer being followed.
            if (![remoteFeedIds containsObject:siteTopic.feedID]) {
                siteTopic.following = NO;
            }
        }
    } completion:success onQueue:dispatch_get_main_queue()];
}

/**
 Saves the specified `ReaderAbstractTopics`. Any `ReaderAbstractTopics` not included in the passed
 array are removed from Core Data.

 @param topics An array of `ReaderAbstractTopics` to save.
 */
- (void)mergeMenuTopics:(NSArray *)topics isLoggedIn:(BOOL)isLoggedIn withSuccess:(void (^)(void))success
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSArray *currentTopics = [ReaderAbstractTopic lookupAllMenusInContext:context error:nil];
        NSMutableArray *topicsToKeep = [NSMutableArray array];

        for (RemoteReaderTopic *remoteTopic in topics) {
            ReaderAbstractTopic *newTopic = [self createOrReplaceFromRemoteTopic:remoteTopic inContext:context];
            if (newTopic != nil) {
                [topicsToKeep addObject:newTopic];
            } else {
                DDLogInfo(@"%@ returned a nil topic: %@", NSStringFromSelector(_cmd), remoteTopic);
            }
        }

        if ([currentTopics count] > 0) {
            for (ReaderAbstractTopic *topic in currentTopics) {
                if (![topic isKindOfClass:[ReaderSiteTopic class]] && ![topicsToKeep containsObject:topic]) {
                    
                    if ([topic isEqual:[self currentTopicInContext:context]]) {
                        self.currentTopic = nil;
                    }
                    if (topic.inUse) {
                        if (!ReaderHelpers.isLoggedIn && [topic isKindOfClass:ReaderTagTopic.class]) {
                            DDLogInfo(@"Not unfollowing a locally saved topic: %@", topic.title);
                            continue;
                        }

                        // If the topic is in use just set showInMenu to false
                        // and let it be cleaned up like any other non-menu topic.
                        DDLogInfo(@"Removing topic from menu: %@", topic.title);
                        topic.showInMenu = NO;
                        // Followed topics are always in the menu, so if we're
                        // removing the topic, if it was once followed its not now.
                        topic.following = NO;
                    } else {
                        // If the user adds a locally saved tag/interest prevent it from being deleted
                        // while the user is logged out.
                        ReaderTagTopic *tagTopic = (ReaderTagTopic *)topic;

                        if (!isLoggedIn && [topic isKindOfClass:ReaderTagTopic.class]) {
                            DDLogInfo(@"Not deleting a locally saved topic: %@", topic.title);
                            continue;
                        }

                        if ([topic isKindOfClass:ReaderTagTopic.class] && tagTopic.cards.count > 0) {
                            DDLogInfo(@"Not deleting a topic related to a card: %@", topic.title);
                            continue;
                        }

                        DDLogInfo(@"Deleting topic: %@", topic.title);
                        [self preserveSavedPostsFromTopic:topic];
                        [context deleteObject:topic];
                    }
                }
            }
        }
    } completion:success onQueue:dispatch_get_main_queue()];
}

- (void)mergeMenuTopics:(NSArray *)topics withSuccess:(void (^)(void))success
{
    [self mergeMenuTopics:topics
               isLoggedIn:ReaderHelpers.isLoggedIn
              withSuccess:success];
}

@end
