#import <objc/runtime.h>

#import "Blog+Jetpack.h"
#import "WPAccount.h"
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "WordPressComOAuthClient.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPUserAgent.h"

NSString * const BlogJetpackErrorDomain = @"BlogJetpackError";
NSString * const BlogJetpackApiBaseUrl = @"https://public-api.wordpress.com/";
NSString * const BlogJetpackApiPath = @"get-user-blogs/1.0";

@implementation Blog (Jetpack)

- (BOOL)hasJetpack
{
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return (nil != [self jetpackVersion]);
}

- (BOOL)hasJetpackAndIsConnectedToWPCom
{
    BOOL hasJetpack = [self hasJetpack];
    BOOL connectedToWPCom = [[self jetpackBlogID] doubleValue] > 0.0;

    return hasJetpack && connectedToWPCom;
}

- (NSString *)jetpackVersion
{
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return [self.options stringForKeyPath:@"jetpack_version.value"];
}

- (NSNumber *)jetpackBlogID
{
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return [self.options numberForKeyPath:@"jetpack_client_id.value"];
}

- (NSString *)jetpackUsername
{
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return self.jetpackAccount.username;
}

- (NSString *)jetpackPassword
{
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return self.jetpackAccount.password;
}

- (void)validateJetpackUsername:(NSString *)username
                       password:(NSString *)password
                multifactorCode:(NSString *)multifactorCode
                        success:(void (^)())success
                        failure:(void (^)(NSError *))failure
{
    NSAssert(![self isWPcom], @"Can't validate credentials for a WordPress.com site");
    NSAssert(username != nil, @"Can't validate with a nil username");
    NSAssert(password != nil, @"Can't validate with a nil password");

    if ([self isWPcom]) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:BlogJetpackErrorDomain code:BlogJetpackErrorCodeInvalidBlog userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Can't validate credentials for a WordPress.com blog", @"")}];
            failure(error);
            return;
        }
    }

    AFHTTPRequestOperationManager* operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:BlogJetpackApiBaseUrl]];

    NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent currentUserAgent];

    operationManager.requestSerializer = [[AFJSONRequestSerializer alloc] init];
    [operationManager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
    [operationManager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];

    [operationManager GET:BlogJetpackApiPath
               parameters:@{@"f": @"json"}
                  success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSArray *blogs = [responseObject arrayForKeyPath:@"userinfo.blog"];
        NSNumber *searchID = [self jetpackBlogID];
        NSString *searchURL = self.url;
        DDLogInfo(@"Available wp.com/jetpack sites for %@: %@", username, blogs);
        NSArray *foundBlogs = [blogs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            BOOL valid = NO;
            if (searchID && [[evaluatedObject numberForKey:@"id"] isEqualToNumber:searchID]) {
                valid = YES;
            } else if ([[evaluatedObject stringForKey:@"url"] isEqualToString:searchURL]) {
                valid = YES;
            }
            if (valid) {
                DDLogInfo(@"Found blog: %@", evaluatedObject);
            }
            return valid;
        }]];

        if ([foundBlogs count] > 0) {
            [self saveJetpackUsername:username andPassword:password multifactorCode:multifactorCode success:success failure:failure];
        } else {
            NSError *error = [NSError errorWithDomain:BlogJetpackErrorDomain
                                                 code:BlogJetpackErrorCodeNoRecordForBlog
                                             userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"This site is not connected to that WordPress.com username", @"")}];
            if (failure) {
                failure(error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        if (failure) {
            NSError *jetpackError = error;
            if (operation.response.statusCode == 401) {
                jetpackError = [NSError errorWithDomain:BlogJetpackErrorDomain
                                                   code:BlogJetpackErrorCodeInvalidCredentials
                                               userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid username or password", @""), NSUnderlyingErrorKey: error}];
            }
            failure(jetpackError);
        }
    }];
}

- (void)removeJetpackCredentials
{
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    // If the associated jetpack account is not used for anything else, remove it
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WPAccount *jetpackAccount = self.jetpackAccount;
    if (jetpackAccount
        && [jetpackAccount.jetpackBlogs count] == 1
        && [[jetpackAccount.jetpackBlogs anyObject] isEqual:self]
        && [jetpackAccount.visibleBlogs count] == 0
        && ![defaultAccount isEqual:jetpackAccount]) {
        DDLogWarn(@"Removing jetpack account %@ since the last blog using it is being removed", jetpackAccount.username);
        [self.managedObjectContext deleteObject:jetpackAccount];
    }
}

#pragma mark - Private methods

- (void)saveJetpackUsername:(NSString *)username
                andPassword:(NSString *)password
            multifactorCode:(NSString *)multifactorCode
                    success:(void (^)())success
                    failure:(void (^)(NSError *))failure
{
    NSAssert(!self.isWPcom, @"Blog+Jetpack doesn't support WordPress.com blogs");

    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client authenticateWithUsername:username
                            password:password
                     multifactorCode:multifactorCode
                             success:^(NSString *authToken) {
                                 AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                 WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];
                                 self.jetpackAccount = account;
                                 [account addJetpackBlogsObject:self];
                                 [self dataSave];

                                 // Sadly we don't care if this succeeds or not
                                 BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                 [blogService syncBlogsForAccount:account success:nil failure:nil];

                                 if (success) {
                                     success();
                                 }
                             } failure:^(NSError *error) {
                                 DDLogError(@"Error while obtaining OAuth2 token after enabling JetPack: %@", error);

                                 /*
                                  If we're using a WordPress.com account that was already set up in the app
                                  and authenticated, we can use that one. Otherwise, we fail.
                                  */
                                 AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                 WPAccount *account = [accountService findWordPressComAccountWithUsername:username];

                                 if (account) {
                                     self.jetpackAccount = account;
                                     [self dataSave];
                                     if (success) {
                                         success();
                                     }
                                 } else {
                                     if (failure) {
                                         failure(error);
                                     }
                                 }
                             }];
}

/*
 Replacement method for `-[Blog remove]`

 @warning Don't call this directly
 */
- (void)removeWithoutJetpack
{
    if (![self isWPcom]) {
        [self removeJetpackCredentials];
    }

    // Since we exchanged implementations, this actually calls `-[Blog remove]`
    [self removeWithoutJetpack];
}

- (NSNumber *)jetpackDotComID
{
    // For WordPress.com blogs, don't override the blog ID
    if ([self isWPcom]) {
        return [self jetpackDotComID];
    }

    // For self hosted, return the jetpackBlogID, which will be nil if there's no Jetpack
    return [self jetpackBlogID];
}

+ (void)load
{
    Method originalRemove = class_getInstanceMethod(self, @selector(remove));
    Method customRemove = class_getInstanceMethod(self, @selector(removeWithoutJetpack));
    method_exchangeImplementations(originalRemove, customRemove);
    Method originalDotcomId = class_getInstanceMethod(self, @selector(dotComID));
    Method customDotcomId = class_getInstanceMethod(self, @selector(jetpackDotComID));
    method_exchangeImplementations(originalDotcomId, customDotcomId);
}

@end
