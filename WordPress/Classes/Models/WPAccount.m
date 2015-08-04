#import "WPAccount.h"
#import "SFHFKeychainUtils.h"
#import "WordPressComOAuthClient.h"

@interface WPAccount ()
@property (nonatomic, strong, readwrite) WordPressComApi *restApi;
@property (nonatomic, strong, readwrite) WordPressXMLRPCApi *xmlrpcApi;
@end

@implementation WPAccount

@dynamic username;
@dynamic blogs;
@dynamic jetpackBlogs;
@dynamic defaultBlog;
@dynamic uuid;
@dynamic email;
@dynamic displayName;
@dynamic userID;
@dynamic avatarURL;
@synthesize restApi = _restApi;
@synthesize xmlrpcApi = _xmlrpcApi;

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

    [_xmlrpcApi.operationQueue cancelAllOperations];
    
    self.authToken = nil;
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    
    self.restApi = nil;
    self.xmlrpcApi = nil;
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
        
        _restApi = [[WordPressComApi alloc] initWithOAuthToken:authToken];
    } else {
        NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:WordPressComOAuthKeychainServiceName
                                           error:&error];
        if (error) {
            DDLogError(@"Error while deleting WordPressComOAuthKeychainServiceName token: %@", error);
        }
        
        _restApi = nil;
    }
}

- (NSArray *)visibleBlogs
{
    NSSet *visibleBlogs = [self.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"visible = YES"]];
    NSArray *sortedBlogs = [visibleBlogs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    return sortedBlogs;
}

#pragma mark - WordPress.com support methods

- (BOOL)isWPComAccount
{
    return self.restApi != nil;
}

@end
