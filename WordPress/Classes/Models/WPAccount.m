#import "WPAccount.h"
#import "SFHFKeychainUtils.h"
#import "WordPress-Swift.h"

static NSString * const WordPressComOAuthKeychainServiceName = @"public-api.wordpress.com";

@interface WPAccount ()

@property (nonatomic, strong, readwrite) WordPressComApi *restApi;
@property (nonatomic, strong, readwrite) WordPressComRestApi *wordPressComRestApi;


@end

@implementation WPAccount

@dynamic username;
@dynamic blogs;
@dynamic jetpackBlogs;
@dynamic defaultBlog;
@dynamic uuid;
@dynamic dateCreated;
@dynamic email;
@dynamic displayName;
@dynamic userID;
@dynamic avatarURL;
@dynamic managedSettings;
@synthesize restApi = _restApi;
@synthesize wordPressComRestApi = _wordPressComRestApi;

#pragma mark - NSManagedObject subclass methods

- (void)prepareForDeletion
{
    // Only do these deletions in the primary context (no parent)
    if (self.managedObjectContext.concurrencyType != NSMainQueueConcurrencyType) {
        return;
    }

    // Beware: Lazy getters below. Let's hit directly the ivar
    [_restApi.operationQueue cancelAllOperations];
    [_restApi reset];
    [_wordPressComRestApi invalidateAndCancelTasks];
    _wordPressComRestApi = nil;
    self.authToken = nil;
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    
    self.restApi = nil;
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
    _restApi = nil;
}

- (NSArray *)visibleBlogs
{
    NSSet *visibleBlogs = [self.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"visible = YES"]];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"settings.name"
                                                                 ascending:YES
                                                                  selector:@selector(localizedCaseInsensitiveCompare:)];

    return [visibleBlogs sortedArrayUsingDescriptors:@[descriptor]];
}

#pragma mark - API Helpers

- (WordPressComApi *)restApi
{
    if (!_restApi && self.authToken.length > 0) {
        _restApi = [[WordPressComApi alloc] initWithOAuthToken:self.authToken];
    }
    return _restApi;
}

- (WordPressComRestApi *)wordPressComRestApi
{
    if (!_wordPressComRestApi && self.authToken.length > 0) {
        _wordPressComRestApi = [[WordPressComRestApi alloc] initWithOAuthToken:self.authToken
                                                                     userAgent: [WPUserAgent wordPressUserAgent]];
    }
    return _wordPressComRestApi;

}

@end
