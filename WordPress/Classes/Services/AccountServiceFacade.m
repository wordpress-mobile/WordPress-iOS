#import "AccountServiceFacade.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "ContextManager.h"

@implementation AccountServiceFacade

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

-(void)removeLegacyAccountIfNeeded:(NSString *)newUsername
{
    NSParameterAssert(newUsername);
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    
    if (![accountService.defaultWordPressComAccount.username isEqual:newUsername]) {
        [accountService removeDefaultWordPressComAccount];
    }
}

@end
