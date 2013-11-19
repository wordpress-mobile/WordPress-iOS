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

static NSString * const DefaultDotcomAccountDefaultsKey = @"AccountDefaultDotcom";
static NSString * const DotcomXmlrpcKey = @"https://wordpress.com/xmlrpc.php";
static NSString * const OauthTokenServiceName = @"public-api.wordpress.com";
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
    NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];

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
    __defaultDotcomAccount = account;
    // When the account object hasn't been saved yet, its objectID is temporary
    // If we store a reference to that objectID it will be invalid the next time we launch
    if ([[account objectID] isTemporaryID]) {
        [account.managedObjectContext obtainPermanentIDsForObjects:@[account] error:nil];
    }
    NSURL *accountURL = [[account objectID] URIRepresentation];
    [[NSUserDefaults standardUserDefaults] setURL:accountURL forKey:DefaultDotcomAccountDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:account];
}

+ (void)removeDefaultWordPressComAccount {
    WPAccount *defaultAccount = __defaultDotcomAccount;
    [defaultAccount.managedObjectContext deleteObject:defaultAccount];
    __defaultDotcomAccount = nil;
}

- (void)prepareForDeletion {
    // Invoked automatically by the Core Data framework when the receiver is about to be deleted.
    if (__defaultDotcomAccount == self) {
        [[self restApi] cancelAllHTTPOperationsWithMethod:nil path:nil];
        // FIXME: this is temporary until we move all the cleanup out of WordPressComApi
        [[self restApi] signOut];
        __defaultDotcomAccount = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
    }
}

#pragma mark - Account creation

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username password:(NSString *)password authToken:(NSString *)authToken {
    WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:DotcomXmlrpcKey username:username andPassword:password];
    account.isWpcom = YES;
    account.authToken = authToken;
    if (__defaultDotcomAccount == nil) {
        [self setDefaultWordPressComAccount:account];
    }
    return account;
}

+ (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc username:(NSString *)username andPassword:(NSString *)password {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@ AND username like %@", xmlrpc, username]];
    [request setIncludesPendingChanges:YES];
    NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
    NSArray *results = [context executeFetchRequest:request error:nil];
    WPAccount *account = nil;
    if ([results count] > 0) {
        account = [results objectAtIndex:0];
    } else {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
        account.xmlrpc = xmlrpc;
        account.username = username;
    }
    account.password = password;
    return account;
}

#pragma mark - Blog creation

- (Blog *)findOrCreateBlogFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext*)context {
    NSError *error;
    WPAccount *contextAccount = (WPAccount *)[context existingObjectWithID:self.objectID error:&error];
    if (error) {
        DDLogError(@"Unable to get WPAccount for context %@: %@", context, error);
        
        // If we continue, then on a context save the app will crash: the account relationship cannot be nil
        #if DEBUG
        abort();
        #endif
    }
    
    NSString *blogUrl = [[blogInfo objectForKey:@"url"] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	if([blogUrl hasSuffix:@"/"])
		blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
    
	blogUrl = [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSSet *foundBlogs = [contextAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"url like %@", blogUrl]];
    if ([foundBlogs count]) {
        return [foundBlogs anyObject];
    }

    Blog *blog = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Blog class]) inManagedObjectContext:context];
    blog.account = contextAccount;
    blog.url = blogUrl;
    blog.blogID = [NSNumber numberWithInt:[[blogInfo objectForKey:@"blogid"] intValue]];
    blog.blogName = [[blogInfo objectForKey:@"blogName"] stringByDecodingXMLCharacters];
    blog.xmlrpc = [blogInfo objectForKey:@"xmlrpc"];
    blog.isAdmin = [NSNumber numberWithInt:[[blogInfo objectForKey:@"isAdmin"] intValue]];

    return blog;
}

- (void)syncBlogsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [self.xmlrpcApi getBlogsWithSuccess:^(NSArray *blogs) {
        [self mergeBlogs:blogs withCompletion:success];
    } failure:failure];
}

- (void)mergeBlogs:(NSArray *)blogs withCompletion:(void (^)())completion {
    NSManagedObjectContext *backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundMOC.parentContext = self.managedObjectContext;

    NSManagedObjectID *accountID = self.objectID;
    [backgroundMOC performBlock:^{
        WPAccount *account = (WPAccount *)[backgroundMOC objectWithID:accountID];
        for (NSDictionary *blog in blogs) {
            [account findOrCreateBlogFromDictionary:blog withContext:backgroundMOC];
        }
        NSError *error;
        if (![backgroundMOC save:&error]) {
            DDLogError(@"Unresolved core data save error: %@", error);
        }

        dispatch_async(dispatch_get_main_queue(), completion);
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
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:OauthTokenServiceName error:nil];
}

- (void)setAuthToken:(NSString *)authToken {
    if (authToken) {
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:authToken
                          forServiceName:OauthTokenServiceName
                          updateExisting:YES
                                   error:nil];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:OauthTokenServiceName
                                           error:nil];
    }
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
