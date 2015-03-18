//
//  AccountCreationService.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 3/18/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import "AccountCreationService.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "ContextManager.h"

@implementation AccountCreationService

- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                   authToken:(NSString *)authToken
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

    return [accountService createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];
}

- (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password
{
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

    return [accountService createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password];
}

- (void)updateEmailAndDefaultBlogForWordPressComAccount:(WPAccount *)account
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    [accountService updateEmailAndDefaultBlogForWordPressComAccount:account];
}

@end
