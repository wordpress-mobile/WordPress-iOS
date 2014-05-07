#import <objc/runtime.h>

#import "Blog+Jetpack.h"
#import "WPAccount.h"
#import "Note.h"
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "WordPressComOAuthClient.h"
#import "AccountService.h"

NSString * const BlogJetpackErrorDomain = @"BlogJetpackError";
NSString * const BlogJetpackApiBaseUrl = @"https://public-api.wordpress.com/";
NSString * const BlogJetpackApiPath = @"get-user-blogs/1.0";

// AFJSONRequestOperation requires that a URI end with .json in order to match
// This will make any request to be processed as JSON
@interface BlogJetpackJSONRequestOperation : AFJSONRequestOperation
@end
@implementation BlogJetpackJSONRequestOperation
+(BOOL)canProcessRequest:(NSURLRequest *)urlRequest {
    return YES;
}
@end


@implementation Blog (Jetpack)

- (BOOL)hasJetpack {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return (nil != [self jetpackVersion]);
}

- (BOOL)hasJetpackAndIsConnectedToWPCom
{
    BOOL hasJetpack = [self hasJetpack];
    BOOL connectedToWPCom = [[self jetpackBlogID] doubleValue] > 0.0;
    
    return hasJetpack && connectedToWPCom;
}

- (NSString *)jetpackVersion {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return [self.options stringForKeyPath:@"jetpack_version.value"];
}

- (NSNumber *)jetpackBlogID {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

	return [self.options numberForKeyPath:@"jetpack_client_id.value"];
}

- (NSString *)jetpackUsername {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return self.jetpackAccount.username;
}

- (NSString *)jetpackPassword {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return self.jetpackAccount.password;
}

- (void)validateJetpackUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *))failure {
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

    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:BlogJetpackApiBaseUrl]];
    [client registerHTTPOperationClass:[BlogJetpackJSONRequestOperation class]];
    [client setDefaultHeader:@"User-Agent" value:[[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationUserAgent]];
    [client setAuthorizationHeaderWithUsername:username password:password];
    [client getPath:BlogJetpackApiPath
         parameters:@{@"f": @"json"}
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                
                if (foundBlogs && [foundBlogs count] > 0) {
                    [self saveJetpackUsername:username andPassword:password success:success failure:failure];
                } else {
                    NSError *error = [NSError errorWithDomain:BlogJetpackErrorDomain
                                                         code:BlogJetpackErrorCodeNoRecordForBlog
                                                     userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"This site is not connected to that WordPress.com username", @"")}];
                    if (failure) failure(error);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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

- (void)removeJetpackCredentials {
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

- (void)saveJetpackUsername:(NSString *)username andPassword:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *))failure {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");
    
    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client authenticateWithUsername:username
                            password:password
                             success:^(NSString *authToken) {
                                 AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                 WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:username password:password authToken:authToken];
                                 self.jetpackAccount = account;
                                 [account addJetpackBlogsObject:self];
                                 [self dataSave];

                                 // If there is no WP.com account on the device, make this the default
                                 if ([accountService defaultWordPressComAccount] == nil) {
                                     [accountService setDefaultWordPressComAccount:account];
                                     [self dataSave];
                                     
                                     // Sadly we don't care if this succeeds or not
                                     [accountService syncBlogsForAccount:account success:nil failure:nil];
                                 }
                                 
                                 if (success) {
                                     success();
                                 }
                             } failure:^(NSError *error) {
                                 DDLogError(@"Error while obtaining OAuth2 token after enabling JetPack: %@", error);
                                 
                                 // OAuth2 login failed - we can still create the WPAccount without the token
                                 // TODO: This is the behavior prior to 3.9 and could get removed
                                 AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
                                 WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:username password:password authToken:nil];
                                 self.jetpackAccount = account;
                                 [self dataSave];
                                 
                                 // If the default 3.9 behavior is removed above, this should call the failure block, not success
                                 if (success) {
                                     success();
                                 }
                             }];
}

/*
 Replacement method for `-[Blog remove]`
 
 @warning Don't call this directly
 */
- (void)removeWithoutJetpack {
    if (![self isWPcom]) {
        [self removeJetpackCredentials];
    }

    // Since we exchanged implementations, this actually calls `-[Blog remove]`
    [self removeWithoutJetpack];
}

+ (void)load {
    Method originalRemove = class_getInstanceMethod(self, @selector(remove));
    Method customRemove = class_getInstanceMethod(self, @selector(removeWithoutJetpack));
    method_exchangeImplementations(originalRemove, customRemove);
}

@end
