#import "JetpackREST.h"
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"

static NSString * const JetpackRESTEnabledKey = @"JetpackRESTEnabled";

@implementation JetpackREST

+ (BOOL)enabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:JetpackRESTEnabledKey];
}

+ (void)setEnabled:(BOOL)enabled withCompletion:(void (^)())completion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:JetpackRESTEnabledKey];

    void (^completionBlock)() = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [defaults synchronize];

            if (completion) {
                completion();
            }
        });
    };

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        if (enabled) {
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
            if (defaultAccount) {
                [blogService syncBlogsForAccount:defaultAccount success:completionBlock failure:completionBlock];
            } else {
                completionBlock();
            }
        } else {
            [blogService migrateJetpackBlogsToXMLRPCWithCompletion:completionBlock];
        }
    }];
}

@end
