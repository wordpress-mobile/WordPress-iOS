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

#import <SFHFKeychainUtils/SFHFKeychainUtils.h>

static NSString * const DefaultDotcomAccountDefaultsKey = @"AccountDefaultDotcom";
static NSString * const DotcomXmlrpcKey = @"https://wordpress.com/xmlrpc.php";
static WPAccount *__defaultDotcomAccount = nil;

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
    NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];

    NSURL *accountURL = [[NSUserDefaults standardUserDefaults] URLForKey:DefaultDotcomAccountDefaultsKey];
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
    NSURL *accountURL = [[account objectID] URIRepresentation];
    [[NSUserDefaults standardUserDefaults] setURL:accountURL forKey:DefaultDotcomAccountDefaultsKey];
}

+ (void)removeDefaultWordPressComAccount {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
    __defaultDotcomAccount = nil;
}

- (void)prepareForDeletion {
    // Invoked automatically by the Core Data framework when the receiver is about to be deleted.
    if (__defaultDotcomAccount == self) {
        [WPAccount removeDefaultWordPressComAccount];
    }
}

#pragma mark - Account creation

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username andPassword:(NSString *)password {
    WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:DotcomXmlrpcKey username:username andPassword:password];
    account.isWpcom = YES;
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

- (Blog *)findOrCreateBlogFromDictionary:(NSDictionary *)blogInfo {
    NSString *blogUrl = [[blogInfo objectForKey:@"url"] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	if([blogUrl hasSuffix:@"/"])
		blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
	blogUrl= [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSSet *foundBlogs = [self.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"url like %@", blogUrl]];
    if ([foundBlogs count]) {
        return [foundBlogs anyObject];
    }

    Blog *blog = [[Blog alloc] initWithEntity:[NSEntityDescription entityForName:@"Blog"
                                                          inManagedObjectContext:self.managedObjectContext]
               insertIntoManagedObjectContext:self.managedObjectContext];
    blog.account = self;

    blog.url = blogUrl;
    blog.blogID = [NSNumber numberWithInt:[[blogInfo objectForKey:@"blogid"] intValue]];
    blog.blogName = [[blogInfo objectForKey:@"blogName"] stringByDecodingXMLCharacters];
    blog.xmlrpc = [blogInfo objectForKey:@"xmlrpc"];
    blog.isAdmin = [NSNumber numberWithInt:[[blogInfo objectForKey:@"isAdmin"] intValue]];

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
