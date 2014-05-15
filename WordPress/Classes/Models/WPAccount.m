#import "WPAccount.h"
#import "SFHFKeychainUtils.h"
#import "WordPressComOAuthClient.h"


@implementation WPAccount {
    WordPressComApi *_restApi;
    WordPressXMLRPCApi *_xmlrpcApi;
}

@dynamic xmlrpc;
@dynamic username;
@dynamic isWpcom;
@dynamic blogs;
@dynamic jetpackBlogs;


#pragma mark - NSManagedObject subclass methods

- (void)prepareForDeletion {
    // Only do these deletions in the primary context (no parent)
    if (self.managedObjectContext.parentContext) {
        return;
    }
    
	[[[self restApi] operationQueue] cancelAllOperations];
    [[self restApi] reset];

    // Clear keychain entries
    NSError *error;
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:@"WordPress.com" error:&error];
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:WordPressComOAuthKeychainServiceName error:&error];
    self.password = nil;
    self.authToken = nil;
}

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
    
    _restApi = nil;
    _xmlrpcApi = nil;
}


#pragma mark - Custom accessors

- (NSString *)password {
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:self.xmlrpc error:nil];
}

- (void)setPassword:(NSString *)password {
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

- (NSString *)authToken {
    NSError *error = nil;
    NSString *authToken = [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:WordPressComOAuthKeychainServiceName error:&error];

    if (error) {
        DDLogError(@"Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error);
    }

    return authToken;
}

- (void)setAuthToken:(NSString *)authToken {
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
            DDLogError(@"Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error);
        }
    }
}

- (NSArray *)visibleBlogs {
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

- (WordPressXMLRPCApi *)xmlrpcApi {
    if (!_xmlrpcApi) {
        _xmlrpcApi = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:[NSURL URLWithString:self.xmlrpc] username:self.username password:self.password];
    }
    return _xmlrpcApi;
}

@end
