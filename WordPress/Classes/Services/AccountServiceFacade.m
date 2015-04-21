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

- (void)updateUserDetailsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    [accountService updateUserDetailsForAccount:account success:success failure:failure];
}

-(void)removeLegacyAccount:(NSString *)newUsername
{
    NSParameterAssert(newUsername);
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    
    if (![accountService.defaultWordPressComAccount.username isEqual:newUsername]) {
        [accountService removeDefaultWordPressComAccount];
    }
}

@end
