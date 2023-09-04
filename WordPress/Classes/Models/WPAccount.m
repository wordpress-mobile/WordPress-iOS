#import "WPAccount.h"
#import "WordPress-Swift.h"

@interface WPAccount ()

@property (nonatomic, strong, readwrite) WordPressComRestApi *wordPressComRestApi;


@end

@implementation WPAccount

@dynamic username;
@dynamic blogs;
@dynamic defaultBlog;
@dynamic primaryBlogID;
@dynamic uuid;
@dynamic dateCreated;
@dynamic email;
@dynamic emailVerified;
@dynamic displayName;
@dynamic userID;
@dynamic avatarURL;
@dynamic settings;
@synthesize wordPressComRestApi = _wordPressComRestApi;

#pragma mark - NSManagedObject subclass methods

- (void)prepareForDeletion
{
    // Only do these deletions in the primary context (no parent)
    if (self.managedObjectContext.concurrencyType != NSMainQueueConcurrencyType) {
        return;
    }

    [_wordPressComRestApi invalidateAndCancelTasks];
    _wordPressComRestApi = nil;
    self.authToken = nil;
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    _wordPressComRestApi = nil;
}

+ (NSString *)entityName
{
    return @"Account";
}

#pragma mark - Custom accessors

- (void)setUsername:(NSString *)username
{
    NSString *previousUsername = self.username;

    BOOL usernameChanged = ![previousUsername isEqualToString:username];
    NSString *authToken = nil;

    if (usernameChanged) {
        authToken = self.authToken;
        self.authToken = nil;
    }

    [self willChangeValueForKey:@"username"];
    [self setPrimitiveValue:username forKey:@"username"];
    [self didChangeValueForKey:@"username"];

    if (usernameChanged) {
        self.authToken = authToken;
    }
}

- (NSString *)authToken
{
    return [WPAccount tokenForUsername:self.username];
}

- (void)setAuthToken:(NSString *)authToken
{
    if (authToken) {
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:authToken
                          forServiceName:[WPAccount authKeychainServiceName]
                             accessGroup:nil
                          updateExisting:YES
                                   error:&error];

        if (error) {
            DDLogError(@"Error while updating WordPressComOAuthKeychainServiceName token: %@", error);
        }

    } else {
        NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:[WPAccount authKeychainServiceName]
                                     accessGroup:nil
                                           error:&error];
        if (error) {
            DDLogError(@"Error while deleting WordPressComOAuthKeychainServiceName token: %@", error);
        }
    }

    // Make sure to release any RestAPI alloc'ed, since it might have an invalid token
    _wordPressComRestApi = nil;
}

- (NSArray *)visibleBlogs
{
    NSSet *visibleBlogs = [self.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"visible = YES"]];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"settings.name"
                                                                 ascending:YES
                                                                  selector:@selector(localizedCaseInsensitiveCompare:)];

    return [visibleBlogs sortedArrayUsingDescriptors:@[descriptor]];
}

- (BOOL)hasAtomicSite {
    for (Blog *blog in self.blogs) {
        if ([blog isAtomic]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Static methods

+ (NSString *)tokenForUsername:(NSString *)username
{
    NSError *error = nil;
    [WPAccount migrateAuthKeyForUsername:username];
    NSString *authToken = [SFHFKeychainUtils getPasswordForUsername:username
                                                     andServiceName:[WPAccount authKeychainServiceName]
                                                        accessGroup:nil
                                                              error:&error];
    if (error) {
        DDLogError(@"Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error);
    }

    return authToken;
}

+ (void)migrateAuthKeyForUsername:(NSString *)username
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([AppConfiguration isJetpack]) {
            SharedDataIssueSolver *sharedDataIssueSolver = [SharedDataIssueSolver instance];
            [sharedDataIssueSolver migrateAuthKeyFor:username];
        }
    });
}

+ (NSString *)authKeychainServiceName
{
    return [AppConstants authKeychainServiceName];
}

#pragma mark - API Helpers

- (WordPressComRestApi *)wordPressComRestApi
{
    if (!_wordPressComRestApi) {
        if (self.authToken.length > 0) {
            __weak __typeof(self) weakSelf = self;
            _wordPressComRestApi = [WordPressComRestApi defaultApiWithOAuthToken:self.authToken
                                                                       userAgent:[WPUserAgent wordPressUserAgent]
                                                                       localeKey:[WordPressComRestApi LocaleKeyDefault]];
            [_wordPressComRestApi setInvalidTokenHandler:^{
                [weakSelf setAuthToken:nil];
                [WordPressAuthenticationManager showSigninForWPComFixingAuthToken];
                if (weakSelf.isDefaultWordPressComAccount) {
                    // At the time of writing, there is an implicit assumption on what the object parameter value means.
                    // For example, the WordPressAppDelegate.handleDefaultAccountChangedNotification(_:) subscriber inspects the object parameter to decide whether the notification was sent as a result of a login.
                    // If the object is non-nil, then the method considers the source a login.
                    //
                    // The code path in which we are is that of an invalid token, and that's neither a login nor a logout, it's more appropriate to consider it a logout.
                    // That's because if the token is invalid the app will soon received errors from the API and it's therefore better to force the user to login again.
                    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [WordPressAuthenticationManager showSigninForWPComFixingAuthToken];
            });
        }
    }
    return _wordPressComRestApi;

}

@end
