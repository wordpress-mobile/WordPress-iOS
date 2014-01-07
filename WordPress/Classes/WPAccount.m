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
    __defaultDotcomAccount = (WPAccount *)[[[ContextManager sharedInstance] mainContext] existingObjectWithID:account.objectID error:nil];
    // When the account object hasn't been saved yet, its objectID is temporary
    // If we store a reference to that objectID it will be invalid the next time we launch
    if ([[account objectID] isTemporaryID]) {
        [account.managedObjectContext obtainPermanentIDsForObjects:@[account] error:nil];
    }
    NSURL *accountURL = [[account objectID] URIRepresentation];
    [[NSUserDefaults standardUserDefaults] setURL:accountURL forKey:DefaultDotcomAccountDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:account];
    
    [SFHFKeychainUtils storeUsername:account.username andPassword:account.authToken forServiceName:WordPressComOAuthKeychainServiceName updateExisting:YES error:nil];
    
    [NotificationsManager registerForPushNotifications];
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
    
    [context performBlock:^{
        WPAccount *account = (WPAccount *)[context objectWithID:accountObjectID];
        [context deleteObject:account];
        [[ContextManager sharedInstance] saveContext:context];
    }];
}

- (void)prepareForDeletion {
    [[self restApi] cancelAllHTTPOperationsWithMethod:nil path:nil];
    [[self restApi] reset];

    // Clear keychain entries
    NSError *error;
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:@"WordPress.com" error:&error];
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:WordPressComOAuthKeychainServiceName error:&error];
    self.password = nil;
    self.authToken = nil;

    [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = NO;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
    });
}


#pragma mark - Account creation

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username password:(NSString *)password authToken:(NSString *)authToken {
    return [WPAccount createOrUpdateWordPressComAccountWithUsername:username password:password authToken:authToken context:[[ContextManager sharedInstance] backgroundContext]];
}

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username password:(NSString *)password authToken:(NSString *)authToken context:(NSManagedObjectContext *)context {
    WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:WordPressDotcomXMLRPCKey username:username andPassword:password withContext:context];
    [account.managedObjectContext performBlockAndWait:^{
        account.isWpcom = YES;
        account.authToken = authToken;
    }];
    return account;
}

+ (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc username:(NSString *)username andPassword:(NSString *)password {
    return [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password withContext:[[ContextManager sharedInstance] backgroundContext]];
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
    NSString *blogUrl = [[blogInfo objectForKey:@"url"] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	if ([blogUrl hasSuffix:@"/"]) {
		blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
    }
	blogUrl = [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    __block Blog *blog;
    [context performBlockAndWait:^{
        WPAccount *contextAccount = (WPAccount *)[context existingObjectWithID:self.objectID error:nil];
        NSSet *foundBlogs = [contextAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"url like %@", blogUrl]];
        if ([foundBlogs count]) {
            blog = [foundBlogs anyObject];
            return;
        }
        
        blog = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Blog class]) inManagedObjectContext:context];
        blog.account = contextAccount;
        blog.url = blogUrl;
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
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:WordPressComOAuthKeychainServiceName error:nil];
}

- (void)setAuthToken:(NSString *)authToken {
    if (authToken) {
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:authToken
                          forServiceName:WordPressComOAuthKeychainServiceName
                          updateExisting:YES
                                   error:nil];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:WordPressComOAuthKeychainServiceName
                                           error:nil];
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
