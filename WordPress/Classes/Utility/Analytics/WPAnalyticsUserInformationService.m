#import "WPAnalyticsUserInformationService.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "WPAccount.h"

@implementation WPAnalyticsUserInformationService

NSString *const EmailAddressRetrievedKey = @"email_address_retrieved";

+ (void)retrieveAndRegisterEmailAddressIfApplicable
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:EmailAddressRetrievedKey]) {
        return;
    }
    
    DDLogInfo(@"Retrieving /me endpoint");
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    [[defaultAccount restApi] getUserDetailsWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        if ([[response stringForKey:@"email"] length] > 0) {
            [WPAnalyticsTrackerMixpanel registerEmailAddress:[response stringForKey:@"email"]];
            [userDefaults setBool:YES forKey:EmailAddressRetrievedKey];
            [userDefaults synchronize];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Failed to retrieve /me endpoint");
    }];
}

+ (void)resetEmailRetrievalCheck
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:EmailAddressRetrievedKey];
}

@end
