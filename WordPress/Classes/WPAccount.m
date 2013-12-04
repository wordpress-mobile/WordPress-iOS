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


static NSString * const DefaultDotcomAccountDefaultsKey = @"AccountDefaultDotcom";
static NSString * const DotcomXmlrpcKey = @"https://wordpress.com/xmlrpc.php";
static WPAccount *__defaultDotcomAccount = nil;
NSString * const WPAccountDefaultWordPressComAccountChangedNotification = @"WPAccountDefaultWordPressComAccountChangedNotification";


@interface WPAccount ()
@property (nonatomic, retain) NSString *xmlrpc;
@property (nonatomic, retain) NSString *username;
@property (nonatomic) BOOL isWpcom;
@end

@implementation WPAccount

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
}

+ (void)removeDefaultWordPressComAccount {
    WPAccount *defaultAccount = __defaultDotcomAccount;
    if (!defaultAccount) {
        return;
    }
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] backgroundContext];
    [backgroundMOC performBlock:^{
        WPAccount *account = (WPAccount *)[backgroundMOC objectWithID:defaultAccount.objectID];
        [backgroundMOC deleteObject:account];
        [[ContextManager sharedInstance] saveContext:backgroundMOC];
    }];
    __defaultDotcomAccount = nil;
}

- (void)prepareForDeletion {
    // Invoked automatically by the Core Data framework when the receiver is about to be deleted.
    if (__defaultDotcomAccount == self) {
        [[WordPressComApi sharedApi] cancelAllHTTPOperationsWithMethod:nil path:nil];
        __defaultDotcomAccount = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
    }
}

#pragma mark - Account creation

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username andPassword:(NSString *)password {
    return [WPAccount createOrUpdateWordPressComAccountWithUsername:username andPassword:password withContext:[[ContextManager sharedInstance] backgroundContext]];
}

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username andPassword:(NSString *)password withContext:(NSManagedObjectContext *)context {
    WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:DotcomXmlrpcKey username:username andPassword:password withContext:context];
    account.isWpcom = YES;
    if (__defaultDotcomAccount == nil) {
        [self setDefaultWordPressComAccount:account];
    }
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
        blog.isAdmin = [NSNumber numberWithInt:[[blogInfo objectForKey:@"isAdmin"] intValue]];
    }];
    
    return blog;
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
    }
}

@end
