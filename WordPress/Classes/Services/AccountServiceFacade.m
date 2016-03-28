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

    WPAccount *account = [accountService createOrUpdateAccountWithUsername:username authToken:authToken];
    if (![accountService.defaultWordPressComAccount.uuid isEqualToString:account.uuid]) {
        [accountService removeDefaultWordPressComAccount];
        [accountService setDefaultWordPressComAccount:account];
    }
    
    return account;
}

- (void)updateUserDetailsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    [accountService updateUserDetailsForAccount:account success:success failure:failure];
}

@end
