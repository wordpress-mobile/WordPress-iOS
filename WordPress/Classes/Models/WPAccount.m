#import "WPAccount.h"
#import "SFHFKeychainUtils.h"
#import "WordPressComOAuthClient.h"

@interface WPAccount ()
@property (nonatomic, strong, readwrite) WordPressComApi *restApi;
@property (nonatomic, strong, readwrite) WordPressXMLRPCApi *xmlrpcApi;
@end

@implementation WPAccount

@dynamic xmlrpc;
@dynamic username;
@dynamic isWpcom;
@dynamic blogs;
@dynamic jetpackBlogs;
@dynamic defaultBlog;
@dynamic uuid;
@dynamic email;
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
    
    self.password = nil;
    
    // Fix: Let's make sure we only nuke the authToken when needed. That is, if the deleted account is dotcom.
    // Otherwise, removing a self hosted account with the same username as a dotcom account might end up nuking the token.
    if (self.isWpcom) {
        self.authToken = nil;
    }
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    
    self.restApi = nil;
    self.xmlrpcApi = nil;
}

#pragma mark - Custom accessors

- (NSString *)password
{
    if (self.isWpcom) {
        return nil;
    }
    
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:self.xmlrpc error:nil];
}

- (void)setPassword:(NSString *)password
{
    if (password) {
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:password
                          forServiceName:self.xmlrpc
                          updateExisting:YES
                                   error:nil];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:self.xmlrpc
                                           error:nil];
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
    NSArray *sortedBlogs = [visibleBlogs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    return sortedBlogs;
}

#pragma mark - API Helpers

- (WordPressComApi *)restApi
{
    if (!self.isWpcom) {
        return nil;
    }

    if (!_restApi) {
        _restApi = [[WordPressComApi alloc] initWithOAuthToken:self.authToken];
    }
    return _restApi;
}

- (WordPressXMLRPCApi *)xmlrpcApi
{
    if (!_xmlrpcApi) {
        _xmlrpcApi = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:[NSURL URLWithString:self.xmlrpc] username:self.username password:self.password];
    }
    return _xmlrpcApi;
}

@end
