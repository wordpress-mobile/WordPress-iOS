#import "JetpackService.h"
#import "AccountService.h"
#import "BlogService.h"
#import "JetpackServiceRemote.h"
#import "WordPressComOAuthClient.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "Blog.h"
#import "Blog+Jetpack.h"

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
                                blog:(Blog *)blog
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

    NSManagedObjectID *blogObjectID = [blog objectID];
    JetpackServiceRemote *remote = [JetpackServiceRemote new];
    [remote validateJetpackUsername:username
                           password:password
                          forSiteID:blog.jetpackBlogID
                            success:^{
                                [self loginWithUsername:username
                                               password:password
                                           blogObejctID:blogObjectID
                                                success:successBlock
                                                failure:failureBlock];
                            }
                            failure:failureBlock];
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
             blogObejctID:(NSManagedObjectID *)blogObjectID
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
                                     Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:nil];
                                     if (blogInContext) {
                                         blogInContext.jetpackAccount = account;
                                     }
                                     BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                     [blogService syncBlogsForAccount:account success:^{
                                         success(account);
                                     } failure:failure];
                                 }];
                             }
                             failure:failure];
}

@end
