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

- (void)dismissNavViewController
{
    [self.navController dismissViewControllerAnimated:YES completion:nil];
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

    [self fetchKeyringConnectionsForService:publicizer];
}

- (void)authorize:(PublicizeService *)publicizer didFailWithError:(NSError *)error
{
    DDLogError([error description]);
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:authorizationFailedForService:)]) {
        [self.delegate sharingAuthorizationHelper:self authorizationFailedForService:self.publicizeService];
        return;
    }

    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection failed", @"Message to show when Publicize authorization failed")];
}

- (void)authorizeDidCancel:(PublicizeService *)publicizer
{
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:authorizationCancelledForService:)]) {
        [self.delegate sharingAuthorizationHelper:self authorizationCancelledForService:self.publicizeService];
        return;
    }

    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection cancelled", @"Message to show when Publicize authorization is cancelled")];
}


#pragma mark - Keyring Account Selection Methods

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

- (void)showAccountSelectorForKeyrings:(NSArray *)keyringConnections
{
    NSParameterAssert([[keyringConnections firstObject] isKindOfClass:[KeyringConnection class]]);

    SharingAccountViewController *controller = [[SharingAccountViewController alloc] initWithService:self.publicizeService
                                                                           connections:keyringConnections
                                                                   existingConnections:[self connectionsForService]];
    controller.delegate = self;
    [self.navController setViewControllers:@[controller] animated:YES];
}


#pragma mark - SharingAccountSelection Methods

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

- (void)confirmNewConnection:(KeyringConnection *)keyringConnection withExternalID:(NSString *)externalID disconnectsCurrentConnection:(PublicizeConnection *)currentPublicizeConnection
{
    NSString *accountName = externalID ?: keyringConnection.externalID;
    NSString *title = NSLocalizedString(@"Connecting %@", @"Connecting is a verb. Title of Publicize account selection. The %@ is a placeholder for the service's name.");
    NSString *message = NSLocalizedString(@"Connecting %@ will replace the existing connection to %@.", @"Informs the user of consequences of chooseing a new account to connect to publicize.  The %@ characters are placeholders for account names.");
    NSString *cancel = NSLocalizedString(@"Cancel", @"Verb. Tapping cancels the publicize account selection.");
    NSString *connect = NSLocalizedString(@"Connect", @"Verb. Tapping connects an account to Publicize.");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:title, self.publicizeService.label]
                                                                             message:[NSString stringWithFormat:message, accountName, currentPublicizeConnection.externalID]
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addCancelActionWithTitle:cancel handler:nil];

    [alertController addDefaultActionWithTitle:connect handler:^(UIAlertAction *action) {
        [self updateConnection:currentPublicizeConnection forKeyringConnection:keyringConnection withExternalID:externalID];
    }];

    [alertController presentFromRootViewController];
}

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
