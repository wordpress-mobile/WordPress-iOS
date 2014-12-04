#import "JetpackService.h"
#import "AccountService.h"
#import "BlogService.h"
#import "JetpackServiceRemote.h"
#import "WordPressComOAuthClient.h"
#import "WPAccount.h"

@interface JetpackService ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@implementation JetpackService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    return self;
}

- (void)validateAndLoginWithUsername:(NSString *)username
                            password:(NSString *)password
                              siteID:(NSNumber *)siteID
                             success:(void (^)(WPAccount *account))success
                             failure:(void (^)(NSError *error))failure
{
    void (^successBlock)(WPAccount *) = ^(WPAccount *account) {
        if (success) {
            [self.managedObjectContext performBlock:^{
                success(account);
            }];
        }
    };

    void (^failureBlock)(NSError *) = ^(NSError *error) {
        if (failure) {
            [self.managedObjectContext performBlock:^{
                failure(error);
            }];
        }
    };

    JetpackServiceRemote *remote = [JetpackServiceRemote new];
    [remote validateJetpackUsername:username
                           password:password
                          forSiteID:siteID
                            success:^{
                                [self loginWithUsername:username
                                               password:password
                                                 siteID:siteID
                                                success:successBlock
                                                failure:failureBlock];
                            }
                            failure:failureBlock];
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                   siteID:(NSNumber *)siteID
                  success:(void (^)(WPAccount *account))success
                  failure:(void (^)(NSError *error))failure
{
    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client authenticateWithUsername:username
                            password:password
                             success:^(NSString *authToken) {
                                 [self.managedObjectContext performBlock:^{
                                     AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                     WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:username password:password authToken:authToken];
                                     BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                     [blogService syncBlogsForAccount:account success:^{
                                         success(account);
                                     } failure:failure];
                                 }];
                             }
                             failure:failure];
}

@end
