//
//  WPAccount.m
//  WordPress
//
//  Created by Jorge Bernal on 4/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPAccount.h"
#import "Blog.h"
#import "NSString+XMLExtensions.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "SFHFKeychainUtils.h"
#import "ContextManager.h"
#import <SFHFKeychainUtils.h>
#import "NotificationsManager.h"
#import "WordPressComOAuthClient.h"

static NSString * const DefaultDotcomAccountDefaultsKey = @"AccountDefaultDotcom";
static NSString * const WordPressDotcomXMLRPCKey = @"https://wordpress.com/xmlrpc.php";

static WPAccount *__defaultDotcomAccount = nil;

NSString * const WPAccountDefaultWordPressComAccountChangedNotification = @"WPAccountDefaultWordPressComAccountChangedNotification";


@interface WPAccount ()
@property (nonatomic, retain) NSString *xmlrpc;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *authToken;
@property (nonatomic) BOOL isWpcom;
@end

@implementation WPAccount {
    WordPressComApi *_restApi;
    WordPressXMLRPCApi *_xmlrpcApi;
}

@dynamic xmlrpc;
@dynamic username;
@dynamic isWpcom;
@dynamic blogs;
@dynamic jetpackBlogs;

#pragma mark - Default WordPress.com account

+ (WPAccount *)defaultWordPressComAccount {
    if (__defaultDotcomAccount) {
        return __defaultDotcomAccount;
    }
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    NSURL *accountURL = [[NSUserDefaults standardUserDefaults] URLForKey:DefaultDotcomAccountDefaultsKey];
    if (!accountURL) {
        return nil;
    }
    NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:accountURL];
    if (!objectID) {
        return nil;
    }

    WPAccount *account = (WPAccount *)[context existingObjectWithID:objectID error:nil];
    if (account) {
        __defaultDotcomAccount = account;
    } else {
        // The stored Account reference is invalid, so let's remove it to avoid wasting time querying for it
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
    }

    return __defaultDotcomAccount;
}

+ (void)setDefaultWordPressComAccount:(WPAccount *)account {
    NSAssert(account.isWpcom, @"account should be a wordpress.com account");
    NSAssert(account.authToken.length > 0, @"Account should have an authToken for WP.com");
    
    // Make sure the account is on the main context
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    [context performBlockAndWait:^{
        __defaultDotcomAccount = (WPAccount *)[context existingObjectWithID:account.objectID error:nil];
        // When the account object hasn't been saved yet, its objectID is temporary
        // If we store a reference to that objectID it will be invalid the next time we launch
        if ([[account objectID] isTemporaryID]) {
            [account.managedObjectContext obtainPermanentIDsForObjects:@[account] error:nil];
        }
        NSURL *accountURL = [[account objectID] URIRepresentation];
        [[NSUserDefaults standardUserDefaults] setURL:accountURL forKey:DefaultDotcomAccountDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:account];

        [NotificationsManager registerForPushNotifications];
    }];
}

+ (void)removeDefaultWordPressComAccount {
    [self removeDefaultWordPressComAccountWithContext:[ContextManager sharedInstance].backgroundContext];
}

+ (void)removeDefaultWordPressComAccountWithContext:(NSManagedObjectContext *)context {
    if (!__defaultDotcomAccount) {
        return;
    }
    
    [NotificationsManager unregisterDeviceToken];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
    NSManagedObjectID *accountObjectID = __defaultDotcomAccount.objectID;
    __defaultDotcomAccount = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
    });

    [context performBlock:^{
        WPAccount *account = (WPAccount *)[context objectWithID:accountObjectID];
        [context deleteObject:account];
        [[ContextManager sharedInstance] saveContext:context];
    }];
}

#pragma mark - NSManagedObject subclass methods

- (void)prepareForDeletion {
    // Only do these deletions in the primary context (no parent)
    if (self.managedObjectContext.parentContext) {
        return;
    }
    
    [[self restApi] cancelAllHTTPOperationsWithMethod:nil path:nil];
    [[self restApi] reset];

    // Clear keychain entries
    NSError *error;
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:@"WordPress.com" error:&error];
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:WordPressComOAuthKeychainServiceName error:&error];
    self.password = nil;
    self.authToken = nil;
}

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
    
    _restApi = nil;
    _xmlrpcApi = nil;
}

#pragma mark - Account creation

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username password:(NSString *)password authToken:(NSString *)authToken {
    return [WPAccount createOrUpdateWordPressComAccountWithUsername:username password:password authToken:authToken context:[[ContextManager sharedInstance] backgroundContext]];
}

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username password:(NSString *)password authToken:(NSString *)authToken context:(NSManagedObjectContext *)context {
    __block WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:WordPressDotcomXMLRPCKey username:username andPassword:password withContext:context];
    [context performBlockAndWait:^{
        account.authToken = authToken;
        account.isWpcom = YES;
        [[ContextManager sharedInstance] saveContext:context];
    }];
    return account;
}

+ (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc username:(NSString *)username andPassword:(NSString *)password withContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@ AND username like %@", xmlrpc, username]];
    [request setIncludesPendingChanges:YES];
    
    __block WPAccount *account;
    [context performBlockAndWait:^{
        NSArray *results = [context executeFetchRequest:request error:nil];
        if ([results count] > 0) {
            account = [results objectAtIndex:0];
        } else {
            account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
            account.xmlrpc = xmlrpc;
            account.username = username;
        }
        account.password = password;
        
        [[ContextManager sharedInstance] saveContext:context];
    }];
    return account;
}

#pragma mark - Blog creation

- (Blog *)findOrCreateBlogFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext*)context {
    __block Blog *blog;
    [context performBlockAndWait:^{
        WPAccount *contextAccount = (WPAccount *)[context existingObjectWithID:self.objectID error:nil];
        NSSet *foundBlogs = [contextAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@", [blogInfo stringForKey:@"xmlrpc"]]];
        if ([foundBlogs count] == 1) {
            blog = [foundBlogs anyObject];
            return;
        }
        
        // If more than one blog matches, return the first and delete the rest
        if ([foundBlogs count] > 1) {
            Blog *blogToReturn = [foundBlogs anyObject];
            for (Blog *b in foundBlogs) {
                // Choose blogs with URL not starting with https to account for a glitch in the API in early 2014
                if (!([b.url hasPrefix:@"https://"])) {
                    blogToReturn = b;
                    break;
                }
            }
            
            for (Blog *b in foundBlogs) {
                if (!([b isEqual:blogToReturn])) {
                    [context deleteObject:b];
                }
            }
            
            blog = blogToReturn;
            return;
        }
        
        blog = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Blog class]) inManagedObjectContext:context];
        blog.account = contextAccount;
        blog.url = [blogInfo stringForKey:@"url"];
        blog.blogID = [NSNumber numberWithInt:[[blogInfo objectForKey:@"blogid"] intValue]];
        blog.blogName = [[blogInfo objectForKey:@"blogName"] stringByDecodingXMLCharacters];
        blog.xmlrpc = [blogInfo objectForKey:@"xmlrpc"];

        DDLogInfo(@"Created blog: %@", blog);
    }];
    
    return blog;
}

- (void)syncBlogsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    DDLogMethod();
    [self.xmlrpcApi getBlogsWithSuccess:^(NSArray *blogs) {
        [self mergeBlogs:blogs withCompletion:success];
    } failure:^(NSError *error) {
        DDLogError(@"Error syncing blogs: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)mergeBlogs:(NSArray *)blogs withCompletion:(void (^)())completion {
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] backgroundContext];

    NSManagedObjectID *accountID = self.objectID;
    [backgroundMOC performBlock:^{
        WPAccount *account = (WPAccount *)[backgroundMOC objectWithID:accountID];

        NSSet *remoteSet = [NSSet setWithArray:[blogs valueForKey:@"xmlrpc"]];
        NSSet *localSet = [account.blogs valueForKey:@"xmlrpc"];
        NSMutableSet *toDelete = [localSet mutableCopy];
        [toDelete minusSet:remoteSet];

        if ([toDelete count] > 0) {
            for (Blog *blog in account.blogs) {
                if ([toDelete containsObject:blog.xmlrpc]) {
                    [backgroundMOC deleteObject:blog];
                }
            }
        }
        
        // Go through each remote incoming blog and make sure we're up to date with titles, etc.
        // Also adds any blogs we don't have
        for (NSDictionary *blog in blogs) {
            [account findOrCreateBlogFromDictionary:blog withContext:backgroundMOC];
        }
        
        [[ContextManager sharedInstance] saveContext:backgroundMOC];
        
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    }];
}

#pragma mark - Custom accessors

- (NSString *)password {
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:self.xmlrpc error:nil];
}

- (void)setPassword:(NSString *)password {
    if (password) {
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:password
                          forServiceName:self.xmlrpc
                          updateExisting:YES
                                   error:nil];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:self.xmlrpc
                                           error:nil];
    }
}

- (NSString *)authToken {
    NSError *error = nil;
    NSString *authToken = [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:WordPressComOAuthKeychainServiceName error:&error];

    if (error) {
        DDLogError(@"Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error);
    }

    return authToken;
}

- (void)setAuthToken:(NSString *)authToken {
    if (authToken) {
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:authToken
                          forServiceName:WordPressComOAuthKeychainServiceName
                          updateExisting:YES
                                   error:&error];
        if (error) {
            DDLogError(@"Error while updating WordPressComOAuthKeychainServiceName token: %@", error);
        }

    } else {
        NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:WordPressComOAuthKeychainServiceName
                                           error:&error];
        if (error) {
            DDLogError(@"Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error);
        }
    }
}

- (NSArray *)visibleBlogs {
    NSSet *visibleBlogs = [self.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"visible = YES"]];
    NSArray *sortedBlogs = [visibleBlogs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    return sortedBlogs;
}

#pragma mark - API Helpers

- (WordPressComApi *)restApi
{
    if (!self.isWpcom) {
        return nil;
    }

    if (!_restApi) {
        _restApi = [[WordPressComApi alloc] initWithOAuthToken:self.authToken];
    }
    return _restApi;
}

- (WordPressXMLRPCApi *)xmlrpcApi {
    if (!_xmlrpcApi) {
        _xmlrpcApi = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:[NSURL URLWithString:self.xmlrpc] username:self.username password:self.password];
    }
    return _xmlrpcApi;
}

@end
