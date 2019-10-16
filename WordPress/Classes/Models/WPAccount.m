#import "WPAccount.h"
#import "SFHFKeychainUtils.h"
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
    NSError *error = nil;
    NSString *authToken = [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:WordPressComOAuthKeychainServiceName error:&error];
    
    if (error) {
        DDLogError(@"Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error);
    }

    return authToken;
}

- (void)setAuthToken:(NSString *)authToken
{
    if (authToken) {
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:authToken
                          forServiceName:WordPressComOAuthKeychainServiceName
                          updateExisting:YES
                                   error:&error];
        
        if (error) {
            DDLogError(@"Error while updating WordPressComOAuthKeychainServiceName token: %@", error);
        }

    } else {
        NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:WordPressComOAuthKeychainServiceName
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

- (BOOL)isDefault {
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [service defaultWordPressComAccount];
    return [defaultAccount isEqual:self];
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
                if (weakSelf.isDefault) {
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
