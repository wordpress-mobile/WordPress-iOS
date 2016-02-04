#import "SharingAuthorizationHelper.h"

#import "Blog.h"
#import "BlogService.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationWebViewController.h"
#import "WordPress-Swift.h"


@interface SharingAuthorizationHelper() <SharingAuthorizationDelegate>
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) PublicizeService *publicizeService;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic) BOOL reconnecting;
@end

@implementation SharingAuthorizationHelper

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


#pragma mark - Actions

- (void)connectPublicizeService
{
    self.reconnecting = YES;
    [self authorizeWithConnectionURL:[NSURL URLWithString:self.publicizeService.connectURL]];
}

- (void)reconnectPublicizeConnection:(PublicizeConnection *)publicizeConnection
{
    self.reconnecting = NO;
    [self authorizeWithConnectionURL:[NSURL URLWithString:publicizeConnection.refreshURL]];
}

- (void)authorizeWithConnectionURL:(NSURL *)connectionURL
{
    SharingAuthorizationWebViewController *webViewController = [SharingAuthorizationWebViewController controllerWithPublicizer:self.publicizeService
                                                                                                                 connectionURL:connectionURL
                                                                                                                       forBlog:self.blog];
    webViewController.delegate = self;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.viewController presentViewController:navController animated:YES completion:nil];
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


#pragma mark - Keyring Wrangling

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

        [weakSelf selectKeyring:marr];

    } failure:^(NSError *error) {
        if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:keyringFetchFailedForService:)]) {
            [self.delegate sharingAuthorizationHelper:self keyringFetchFailedForService:self.publicizeService];
            return;
        }

        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Keychain connection fetch failed", @"Message to show when Keyring connection synchronization failed")];
    }];
}

- (void)selectKeyring:(NSArray *)keyringConnections
{
    NSParameterAssert([[keyringConnections firstObject] isKindOfClass:[KeyringConnection class]]);

    __weak __typeof__(self) weakSelf = self;
    NSMutableArray *accountNames = [NSMutableArray array];
    for (KeyringConnection *keyConn in keyringConnections) {
        [accountNames addObject:keyConn.externalDisplay];
    }

    NSString *title = NSLocalizedString(@"Connecting %@", @"Title of Publicize account selection");
    title = [NSString stringWithFormat:title, self.publicizeService.label];

    KeyringConnection *keyConn = [keyringConnections firstObject];
    NSString *message;
    if ([keyringConnections count] > 1 || [keyConn.additionalExternalUsers count] > 0) {
        message = NSLocalizedString(@"Select the account you would like to authorize. Note that your posts will be automatically shared to the selected account.", @"");
    } else {
        message = NSLocalizedString(@"Confirm this is the account you would like to authorize. Note that your posts will be automatically shared to this account.", @"");
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    // Build the list, default first, then any additional users.
    for (KeyringConnection *keyConn in keyringConnections) {
        [alertController addActionWithTitle:keyConn.externalDisplay style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [weakSelf connectToServiceWithKeyringConnection:keyConn andExternalUserID:nil];
                                    }];

        for (KeyringConnectionExternalUser *externalUser in keyConn.additionalExternalUsers) {
            [alertController addActionWithTitle:externalUser.externalName style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [weakSelf connectToServiceWithKeyringConnection:keyConn andExternalUserID:externalUser.externalID];
                                        }];
        }
    }

    NSString *serviceName = self.publicizeService.label;
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                      handler:^(UIAlertAction *action) {
                                          NSString *str = [NSString stringWithFormat:@"The %@ connection could not be made because no account was selected.", serviceName];
                                          DDLogDebug(str);
                                          if ([weakSelf.delegate respondsToSelector:@selector(sharingAuthorizationHelper:connectionCancelledForService:)]) {
                                              [weakSelf.delegate sharingAuthorizationHelper:weakSelf connectionCancelledForService:weakSelf.publicizeService];
                                              return;
                                          }
                                          [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection cancelled", @"Message to show when Publicize connection is cancelled by the user.")];
                                      }];

    if ([UIDevice isPad]) {
        UIView *sourceView = self.popoverSourceView;
        CGRect sourceBounds;
        UIPopoverArrowDirection arrowDirection = UIPopoverArrowDirectionAny;
        if (sourceView) {
            sourceBounds = sourceView.bounds;
        } else {
            // Safety net.
            sourceView = self.viewController.view;
            sourceBounds = CGRectMake(sourceView.center.x, sourceView.center.y, 1.0, 1.0);
            arrowDirection = UIPopoverArrowDirectionUp;
        }
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        [self.viewController presentViewController:alertController animated:YES completion:nil];

        UIPopoverPresentationController *presentationController = alertController.popoverPresentationController;
        presentationController.permittedArrowDirections = arrowDirection;
        presentationController.sourceView = sourceView;
        presentationController.sourceRect = sourceBounds;
    } else {
        [self.viewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)connectToServiceWithKeyringConnection:(KeyringConnection *)keyConn andExternalUserID:(NSString *)externalUserID
{
    if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:willConnectToService:usingKeyringConnection:)]) {
        [self.delegate sharingAuthorizationHelper:self willConnectToService:self.publicizeService usingKeyringConnection:keyConn];
    }

    // Check to see if the user chose an existing connection.
    PublicizeConnection *connection = [self existingPublicizeConnectionForKeyringConnection:keyConn withExternalUserID:externalUserID];
    if (connection) {
        // The user selected the existing connection. Treat this as success and bail.
        if ([self.delegate respondsToSelector:@selector(sharingAuthorizationHelper:didConnectToService:withPublicizeConnection:)]) {
            [self.delegate sharingAuthorizationHelper:self didConnectToService:self.publicizeService withPublicizeConnection:connection];
        }
        return;
    }

    __weak __typeof__(self) weakSelf = self;
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self.blog managedObjectContext]];
    [sharingService createPublicizeConnectionForBlog:self.blog
                                             keyring:keyConn
                                      externalUserID:externalUserID
                                             success:^(PublicizeConnection *pubConn) {
                                                 if ([weakSelf.delegate respondsToSelector:@selector(sharingAuthorizationHelper:didConnectToService:withPublicizeConnection:)]) {
                                                     [weakSelf.delegate sharingAuthorizationHelper:weakSelf didConnectToService:weakSelf.publicizeService withPublicizeConnection:pubConn];
                                                 }
                                             }
                                             failure:^(NSError *error) {
                                                 DDLogError([error description]);
                                                 if ([weakSelf.delegate respondsToSelector:@selector(sharingAuthorizationHelper:connectionFailedForService:)]) {
                                                     [weakSelf.delegate sharingAuthorizationHelper:weakSelf connectionFailedForService:weakSelf.publicizeService];
                                                     return;
                                                 }
                                                 [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection failed", @"Message to show when Publicize connect failed")];
                                             }];
}


- (PublicizeConnection *)existingPublicizeConnectionForKeyringConnection:(KeyringConnection *)keyringConnection withExternalUserID:(NSString *)externalUserID
{
    for (PublicizeConnection *connection in self.blog.connections) {
        // If the publicize connection is using the keyring connection, and the publicize connection's externalID is either the
        if ([connection.keyringConnectionID isEqualToNumber:keyringConnection.keyringID]) {
            // if the specified externalUserID matches the connection's externalID,
            // or if the externalUserID is nil, and the connection's externalID is equal to the keyring connections externalID
            // then the user choose an already connected account.
            if ([externalUserID isEqualToString:connection.externalID] ||
                (externalUserID == nil && [connection.externalID isEqualToString:keyringConnection.externalID])) {
                return connection;
            }
        }
    }
    return nil;
}

@end
