#import "WPAccount.h"
#import "WordPress-Swift.h"

static NSString * const WordPressComOAuthKeychainServiceName = @"public-api.wordpress.com";

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
        [KeychainUtils.shared storeUsername:self.username
                                   password:authToken
                                serviceName:WordPressComOAuthKeychainServiceName
                                accessGroup:nil
                             updateExisting:YES
                                      error:&error];

        if (error) {
            DDLogError(@"Error while updating WordPressComOAuthKeychainServiceName token: %@", error);
        }

    } else {
        NSError *error = nil;
        [KeychainUtils.shared deleteItemWithUsername:self.username
                                         serviceName:WordPressComOAuthKeychainServiceName
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
    NSString *authToken = [KeychainUtils.shared getPasswordForUsername:username
                                                           serviceName:WordPressComOAuthKeychainServiceName
                                                           accessGroup:nil
                                                                 error:&error];
    if (error) {
        DDLogError(@"Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error);
    }

    return authToken;
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
                    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:weakSelf];
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
