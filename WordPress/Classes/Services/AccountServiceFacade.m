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

    return [accountService createOrUpdateAccountWithUsername:username authToken:authToken];
}

- (void)updateUserDetailsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    [accountService updateUserDetailsForAccount:account success:success failure:failure];
}

-(void)setDefaultWordPressComAccount:(WPAccount *)account
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    if ([defaultAccount isEqual:account]) {
        // No update needed.
        return;
    } else if (defaultAccount) {
        // Remove the current unrelated account.
        [accountService removeDefaultWordPressComAccount];
    }
    [accountService setDefaultWordPressComAccount:account];
}

@end
