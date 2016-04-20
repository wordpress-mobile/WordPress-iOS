#import "SharingAuthorizationHelper.h"

#import "Blog.h"
#import "BlogService.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationWebViewController.h"
#import "WordPress-Swift.h"

@interface SharingAuthorizationHelper() <SharingAuthorizationDelegate, SharingAccountSelectionDelegate>
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) PublicizeService *publicizeService;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic) BOOL reconnecting;
@end

@implementation SharingAuthorizationHelper

#pragma mark - Lifecycle Methods

- (instancetype)initWithViewController:(UIViewController *)viewController blog:(Blog *)blog publicizeService:(PublicizeService *)publicizeService
{
    self = [self init];
    if (self) {
        _blog = blog;
        _publicizeService = publicizeService;
        _viewController = viewController;
    }
    return self;
}


#pragma mark - Instance Methods

- (NSArray *)connectionsForService
{
    // TODO: Make a blog extension to get connections for a specific publicize service.
    // Use it where ever this method was duplicated.
    NSMutableArray *connections = [NSMutableArray array];
    for (PublicizeConnection *pubConn in self.blog.connections) {
        if ([pubConn.service isEqualToString:self.publicizeService.serviceID]) {
            [connections addObject:pubConn];
        }
    }
    return [NSArray arrayWithArray:connections];
}

/**
 Dismisses the curently presented modal view controller.
 */
- (void)dismissNavViewController
{
    [self.navController dismissViewControllerAnimated:YES completion:nil];
}

/**
 Dismisses the modal and informs the user that a reconnect attempt was successful.
 */
- (void)handleReconnectSucceeded
{
    [self dismissNavViewController];
    NSString *message = NSLocalizedString(@"%@ was reconnected.", @"Let's the user know that a third party sharing service was reconnected. The %@ is a placeholder for the service naem.");
    message = [NSString stringWithFormat:message, self.publicizeService.label];
    [SVProgressHUD showSuccessWithStatus:message];
}


#pragma mark - Authorization Methods

- (void)connectPublicizeService
{
    self.reconnecting = NO;
    [self authorizeWithConnectionURL:[NSURL URLWithString:self.publicizeService.connectURL]];
}

- (void)reconnectPublicizeConnection:(PublicizeConnection *)publicizeConnection
{
    self.reconnecting = YES;
    [self authorizeWithConnectionURL:[NSURL URLWithString:publicizeConnection.refreshURL]];
}

/**
 A helper method for presenting an instance of the `SharingAuthorizationWebViewController`
 
 @param connectionURL: The URL to pass to the SharingAuthorizationWebViewController's constructor. 
 It should be the REST API URL to either connect or refresh a publicize service connection.
 */
- (void)authorizeWithConnectionURL:(NSURL *)connectionURL
{
    SharingAuthorizationWebViewController *webViewController = [SharingAuthorizationWebViewController controllerWithPublicizer:self.publicizeService
                                                                                                                 connectionURL:connectionURL
                                                                                                                       forBlog:self.blog];
    webViewController.delegate = self;

    self.navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    self.navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.viewController presentViewController:self.navController animated:YES completion:nil];
}


#pragma mark - Authorization Delegate Methods

- (void)authorizeDidSucceed:(PublicizeService *)publicizer
{
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:authorizationSucceededForService:)]) {
        [self.delegate sharingAuthorizationHelper:self authorizationSucceededForService:self.publicizeService];
    }

    if (self.reconnecting) {
        // Resync publicize connections.
        SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self.blog managedObjectContext]];
        [sharingService syncPublicizeConnectionsForBlog:self.blog success:^{
            [self handleReconnectSucceeded];
        } failure:^(NSError *error) {
            DDLogError([error description]);
            // Even if there is an error syncing the reconnect attempt still succeeded.
            [self handleReconnectSucceeded];
        }];

    } else {
        [self fetchKeyringConnectionsForService:publicizer];
    }

}

/**
 Dismisses the modal view controller prompting the user the connection failed.
 
 @param publicizer: The publicize service that failed to connect.
 @param error: An error with details regarding the connection failure.
 */
- (void)authorize:(PublicizeService *)publicizer didFailWithError:(NSError *)error
{
    DDLogError([error description]);
    [self dismissNavViewController];

    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:authorizationFailedForService:)]) {
        [self.delegate sharingAuthorizationHelper:self authorizationFailedForService:self.publicizeService];
        return;
    }

    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection failed", @"Message to show when Publicize authorization failed")];
}

/**
 Dismisses the modal view controller prompting the user the connection was cancelled.

 @param publicizer: The publicize service that failed to connect.
 */
- (void)authorizeDidCancel:(PublicizeService *)publicizer
{
    [self dismissNavViewController];

    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:authorizationCancelledForService:)]) {
        [self.delegate sharingAuthorizationHelper:self authorizationCancelledForService:self.publicizeService];
        return;
    }

    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection cancelled", @"Message to show when Publicize authorization is cancelled")];
}


#pragma mark - Keyring Account Selection Methods

/**
 Fetches keyring connections for the specified service. Once keyring connections have been
 fetched `showAccountSelectorForKeyrings:` is called.
 
 @param pubServ: The publicize service for the fetched keyring connections.
 */
- (void)fetchKeyringConnectionsForService:(PublicizeService *)pubServ
{
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:willFetchKeyringsForService:)]) {
        [self.delegate sharingAuthorizationHelper:self willFetchKeyringsForService:self.publicizeService];
    }

    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self.blog managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService fetchKeyringConnectionsForBlog:self.blog success:^(NSArray *keyringConnections) {
        if ([weakSelf.delegate respondsToSelector:@selector(sharingAuthorizationHelper:didFetchKeyringsForService:)]) {
            [weakSelf.delegate sharingAuthorizationHelper:weakSelf didFetchKeyringsForService:weakSelf.publicizeService];
        }

        // Fiter matches
        NSMutableArray *marr = [NSMutableArray array];
        for (KeyringConnection *keyConn in keyringConnections) {
            if ([keyConn.service isEqualToString:pubServ.serviceID]) {
                [marr addObject:keyConn];
            }
        }

        if ([marr count] == 0) {
            DDLogDebug(@"No keyring connections matched serviceID: %@, Returned connections: %@", pubServ.serviceID, keyringConnections);
            if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:keyringFetchFailedForService:)]) {
                [self.delegate sharingAuthorizationHelper:self keyringFetchFailedForService:self.publicizeService];
                return;
            }
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"No keychain connections found", @"Message to show when Keyring connection synchronization succeeded but no matching connections were found.")];
            return;
        }

        [weakSelf showAccountSelectorForKeyrings:marr];

    } failure:^(NSError *error) {
        if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:keyringFetchFailedForService:)]) {
            [self.delegate sharingAuthorizationHelper:self keyringFetchFailedForService:self.publicizeService];
            return;
        }

        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Keychain connection fetch failed", @"Message to show when Keyring connection synchronization failed")];
    }];
}

/**
 Presents a modal `SharingAccountViewController` to let the user confirm the third party 
 account to use for the publicize connection.
 
 @param keyringConnections: An array of `KeyringConnection` instances.
 */
- (void)showAccountSelectorForKeyrings:(NSArray *)keyringConnections
{
    NSParameterAssert([[keyringConnections firstObject] isKindOfClass:[KeyringConnection class]]);

    SharingAccountViewController *controller = [[SharingAccountViewController alloc] initWithService:self.publicizeService
                                                                           connections:keyringConnections
                                                                   existingConnections:[self connectionsForService]];
    controller.delegate = self;

    // Set the view controller stack vs push so there is no back button to contend with.
    // There should be no reason for the user to click back to the authorization vc.
    [self.navController setViewControllers:@[controller] animated:YES];
}


#pragma mark - SharingAccountSelection Methods

/**
 Returns one or more existing `PublicizeConnections` derived from the specified 
 keyringConnection.

 @param keyringConnections: An array of `KeyringConnection` instances.
 */
- (PublicizeConnection *)publicizeConnectionUsingKeyringConnection:(KeyringConnection *)keyringConnection
{
    for (PublicizeConnection *connection in self.blog.connections) {
        // If the publicize connection is using the keyring connection, and the publicize connection's externalID is either the
        if ([connection.keyringConnectionID isEqualToNumber:keyringConnection.keyringID]) {
            return connection;
        }
    }
    return nil;
}

/**
 Checks if the specified publicize connection is derived form the specified 
 keyring connection, and uses the supplied external ID. Returns true if there
 is a match.

 @param connection: A `PublicizeConnection` instance.
 @param keyringConnections: An array of `KeyringConnection` instances.
 @param externalID: The external id of keyring connection, or one of its additional external accounts.
 */
- (BOOL)publicizeConnection:(PublicizeConnection *)connection usesKeyringConnection:(KeyringConnection *)keyringConnection withExternalID:(NSString *)externalID
{
    // if the specified externalUserID matches the connection's externalID,
    // or if the externalUserID is nil, and the connection's externalID is equal to the keyring connections externalID
    // then the user choose an already connected account.
    if ([externalID isEqualToString:connection.externalID] ||
        (externalID == nil && [connection.externalID isEqualToString:keyringConnection.externalID])) {
        return YES;
    }
    return NO;
}

/**
 Some KeyringConnections that have addtional external accounts. PublicizeConnections 
 derived from such a keyring connection can be connected to only one of the keyring
 connection's accounts at a time (either the main one or one of the additional ones).
 Before updating the external ID of such a PublicizeConnection, prompt the user and 
 inform them the connection to their curret account will be replaced by their selection.
 
 @param keyringConnection: The keyring connection in question
 @param externalID: The external ID on the keyring connection or one of its additional accounts. 
 @param currentPublicizeConnection: The existing publicize connection derived from the keyring connection.
 */
- (void)confirmNewConnection:(KeyringConnection *)keyringConnection withExternalID:(NSString *)externalID disconnectsCurrentConnection:(PublicizeConnection *)currentPublicizeConnection
{
    NSString *accountName = keyringConnection.externalDisplay;
    if (![keyringConnection.externalID isEqualToString:externalID]) {
        for (KeyringConnectionExternalUser *externalUser in keyringConnection.additionalExternalUsers) {
            if ([externalUser.externalID isEqualToString:externalID]) {
                accountName = externalUser.externalName;
                break;
            }
        }
    }

    NSString *title = NSLocalizedString(@"Connecting %@", @"Connecting is a verb. Title of Publicize account selection. The %@ is a placeholder for the service's name.");
    NSString *message = NSLocalizedString(@"Connecting %@ will replace the existing connection to %@.", @"Informs the user of consequences of chooseing a new account to connect to publicize.  The %@ characters are placeholders for account names.");
    NSString *cancel = NSLocalizedString(@"Cancel", @"Verb. Tapping cancels the publicize account selection.");
    NSString *connect = NSLocalizedString(@"Connect", @"Verb. Tapping connects an account to Publicize.");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:title, self.publicizeService.label]
                                                                             message:[NSString stringWithFormat:message, accountName, currentPublicizeConnection.externalDisplay]
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addCancelActionWithTitle:cancel handler:nil];

    [alertController addDefaultActionWithTitle:connect handler:^(UIAlertAction *action) {
        [self updateConnection:currentPublicizeConnection forKeyringConnection:keyringConnection withExternalID:externalID];
    }];

    [alertController presentFromRootViewController];
}

/**
 Updates an existing publicize connection to use the specified external ID. 
 
 @param publicizeConnection: The publicize connection to be modified. 
 @param keyringConnection: The keyring connection from which the publicize connection is derived
 @param externalID: The external id of the keyring connection or one of its additional external accounts.
 */
- (void)updateConnection:(PublicizeConnection *)publicizeConnection forKeyringConnection:(KeyringConnection *)keyringConnection withExternalID:(NSString *)externalID
{
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:willConnectToService:usingKeyringConnection:)]) {
        [self.delegate sharingAuthorizationHelper:self willConnectToService:self.publicizeService usingKeyringConnection:keyringConnection];
    }

    [self dismissNavViewController];

    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self.blog managedObjectContext]];

    [sharingService updateExternalID:externalID forBlog:self.blog forPublicizeConnection:publicizeConnection success:^{
        if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:didConnectToService:withPublicizeConnection:)]) {
            [self.delegate sharingAuthorizationHelper:self didConnectToService:self.publicizeService withPublicizeConnection:publicizeConnection];
        }
    } failure:^(NSError *error) {
        [self connectionFailedWithError:error];
    }];
}

/**
 Forges a publicize connection between the blog and publicize servcie with which
 the `SharingAuthorizationHelper` was initialized.
 
 @param keyConn: The keyring connection from which to create a publicize connection
 @param externalUserID: The external ID of one of the keyring connection's additional external accounts. 
 Should be nil if not connecting to one of the additional external accounts.
 */
- (void)connectToServiceWithKeyringConnection:(KeyringConnection *)keyConn andExternalUserID:(NSString *)externalUserID
{
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:willConnectToService:usingKeyringConnection:)]) {
        [self.delegate sharingAuthorizationHelper:self willConnectToService:self.publicizeService usingKeyringConnection:keyConn];
    }

    [self dismissNavViewController];

    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self.blog managedObjectContext]];
    [sharingService createPublicizeConnectionForBlog:self.blog
                                             keyring:keyConn
                                      externalUserID:externalUserID
                                             success:^(PublicizeConnection *pubConn) {
                                                 if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:didConnectToService:withPublicizeConnection:)]) {
                                                     [self.delegate sharingAuthorizationHelper:self didConnectToService:self.publicizeService withPublicizeConnection:pubConn];
                                                 }
                                             }
                                             failure:^(NSError *error) {
                                                 [self connectionFailedWithError:error];
                                             }];
}

/**
 A convenience method for handling an error when making a publicize connection.
 
 @param error: The error that occurred.
 */
- (void)connectionFailedWithError:(NSError *)error
{
    DDLogError([error description]);
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:connectionFailedForService:)]) {
        [self.delegate sharingAuthorizationHelper:self connectionFailedForService:self.publicizeService];
        return;
    }
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection failed", @"Message to show when Publicize connect failed")];
}


#pragma mark - SharingAccount Delegate Methods

- (void)didDismissSharingAccountViewController:(SharingAccountViewController *)controller
{
    [self dismissNavViewController];

    NSString *str = [NSString stringWithFormat:@"The %@ connection could not be made because no account was selected.", self.publicizeService.label];
    DDLogDebug(str);
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:connectionCancelledForService:)]) {
        [self.delegate sharingAuthorizationHelper:self connectionCancelledForService:self.publicizeService];
        return;
    }
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection cancelled", @"Message to show when Publicize connection is cancelled by the user.")];
}

- (void)sharingAccountViewController:(SharingAccountViewController *)controller
           selectedKeyringConnection:(KeyringConnection *)keyringConnection
                          externalID:(NSString *)externalID
{
    PublicizeConnection *connection = [self publicizeConnectionUsingKeyringConnection:keyringConnection];

    if (!connection) {
        [self connectToServiceWithKeyringConnection:keyringConnection andExternalUserID:externalID];
        return;
    }

    // Check to see if the chosen connection and external ID matches an existin PublicizeConnection.
    // If this is true the user has selected the already connected account and we can just treat it as a sucess.
    if ([self publicizeConnection:connection usesKeyringConnection:keyringConnection withExternalID:externalID]) {
        // The user selected the existing connection. Treat this as success and bail.
        if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:didConnectToService:withPublicizeConnection:)]) {
            [self.delegate sharingAuthorizationHelper:self didConnectToService:self.publicizeService withPublicizeConnection:connection];
        }
        [self dismissNavViewController];
        return;
    }

    // The user has selected a different account on an keyring connection that is already in use.
    // We need to ask the user to confirm, because connecting the new account will disconnect the old one.
    [self confirmNewConnection:keyringConnection withExternalID:externalID disconnectsCurrentConnection:connection];
}

@end
