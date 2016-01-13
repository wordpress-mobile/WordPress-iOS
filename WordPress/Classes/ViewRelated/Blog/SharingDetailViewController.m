#import "SharingDetailViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationWebViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPTableViewCell.h"
#import <WordPressShared/WPTableViewSectionHeaderFooterView.h>

#import "WordPress-Swift.h"


static NSString *const PublicizeCellIdentifier = @"PublicizeCell";

@interface PublicizeCelll : UITableViewCell
@end

@implementation PublicizeCelll

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:style reuseIdentifier:reuseIdentifier];
}

@end

@interface SharingDetailViewController () <SharingAuthorizationDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) PublicizeService *publicizeService;

@end

@implementation SharingDetailViewController

- (instancetype)initWithBlog:(Blog *)blog publicizeService:(PublicizeService *)publicizeService
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeService = publicizeService;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Sharing", @"Title for blog detail sharing screen.");

    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[PublicizeCelll class] forCellReuseIdentifier:PublicizeCellIdentifier];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(handleConnectTapped:)];
}


- (void)handleConnectTapped:(UIBarButtonItem *)button
{
    // Show connection.
    [self authorizePublicizer:self.publicizeService withRefresh:self.publicizeService.connectURL];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Settings", @"Section title");
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    if (title.length == 0) {
        return nil;
    }

    WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
    header.title = title;
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Allow this connection to be used by all admins and users of your site.", @"");
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForFooterInSection:section];
    if (title.length == 0) {
        return nil;
    }

    WPTableViewSectionHeaderFooterView *footer = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleFooter];
    footer.title = title;
    return footer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PublicizeCelll *cell = [tableView dequeueReusableCellWithIdentifier:PublicizeCellIdentifier forIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"Available to all users", @"");

    } else if (indexPath.section == 1) {
        cell.textLabel.text = NSLocalizedString(@"Disconnect account", @"Verb. Text label. Tapping displays a screen where the user can configure 'share' buttons for third-party services.");

    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    [self promptToConfirmDisconnect];
}

- (void)disconnectFromPublicizeService
{
    PublicizeConnection *pubConn = [self connectionForService:self.publicizeService];

//    __weak __typeof__(self) weakSelf = self;

    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [sharingService deletePublicizeConnection:pubConn success:^{
        // TODO:

    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Disconnect failed", @"Message to show when Publicize disconnect failed")];
    }];
}

- (void)promptToConfirmDisconnect
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addDestructiveActionWithTitle:NSLocalizedString(@"Disconnect", @"") handler:^(UIAlertAction *action) {
        [self disconnectFromPublicizeService];
    }];

    [alert addCancelActionWithTitle:NSLocalizedString(@"Cancel", @"") handler:nil];

    [self presentViewController:alert animated:YES completion:nil];
}


//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    
//    if (self.connectingService || self.disconnectingService) {
//        return;
//    }
//    
//    PublicizeService *publicizer = self.publicizeServices[indexPath.row];
//    if ([self blogIsConnectedToPublicizeService:publicizer]) {
//        PublicizeConnection *pubConn;
//        for (PublicizeConnection *connection in self.blog.connections) {
//            if ([connection.service isEqualToString:publicizer.serviceID]) {
//                pubConn = connection;
//                break;
//            }
//        }
//        if (pubConn == nil) {
//            return;
//        }
//
//        self.disconnectingService = publicizer;
//        [self disconnectPublicizer:pubConn];
//
//    } else {
//        self.connectingService = publicizer;
//        [self authorizePublicizer:publicizer withRefresh:publicizer.connectURL];
//    }
//
//    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//}

#pragma mark - Publicizer management

- (PublicizeConnection *)connectionForService:(PublicizeService *)publicizeService
{
    for (PublicizeConnection *pubConn in self.blog.connections) {
        if ([pubConn.service isEqualToString:publicizeService.serviceID]) {
            return pubConn;
        }
    }
    return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.blog.managedObjectContext;
}

- (BOOL)blogIsConnectedToPublicizeService:(PublicizeService *)pubServ
{
    // TODO: should we filter out broken connections?
    for (PublicizeConnection *pubConn in self.blog.connections) {
        if ([pubConn.service isEqualToString:pubServ.serviceID]) {
            return YES;
        }
    }
    return NO;
}

//- (void)syncPublicizeServices
//{
//    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
//    __weak __typeof__(self) weakSelf = self;
//    [sharingService syncPublicizeServices:^{
//        [weakSelf syncConnections];
//    } failure:^(NSError *error) {
//        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Publicize service synchronization failed", @"Message to show when Publicize service synchronization failed")];
//        [weakSelf refreshPublicizers];
//    }];
//}
//
//- (void)syncConnections
//{
//    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
//    __weak __typeof__(self) weakSelf = self;
//    [sharingService syncPublicizeConnectionsForBlog:self.blog success:^{
//        [weakSelf refreshPublicizers];
//    } failure:^(NSError *error) {
//        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Publicize connection synchronization failed", @"Message to show when Publicize connection synchronization failed")];
//        [weakSelf refreshPublicizers];
//    }];
//}

- (void)fetchKeyringConnectionsForService:(PublicizeService *)pubServ
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService fetchKeyringConnections:^(NSArray *keyringConnections) {
        NSMutableArray *marr = [NSMutableArray array];
        for (KeyringConnection *keyConn in keyringConnections) {
            if ([keyConn.service isEqualToString:pubServ.serviceID]) {
                [marr addObject:keyConn];
            }
        }
        [weakSelf selectKeyring:marr forService:pubServ];

    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Keychain connection fetch failed", @"Message to show when Keyring connection synchronization failed")];
    }];
}

- (void)selectKeyring:(NSArray *)keyringConnections forService:(PublicizeService *)pubServ
{
    NSParameterAssert([[keyringConnections firstObject] isKindOfClass:[KeyringConnection class]]);
    NSParameterAssert(pubServ);

//    __weak __typeof__(self) weakSelf = self;
    NSMutableArray *accountNames = [NSMutableArray array];
    for (KeyringConnection *keyConn in keyringConnections) {
        [accountNames addObject:keyConn.externalDisplay];
    }

    // TODO: Switch to UIAlertController
    // NOTE: Currently, implementation assumes account names will be different, but they could be the same.
    // We'll have better handling with UIAlertController. For now this works as a tester/demo
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect account:", @"Title of Publicize account selection")
//                                                     cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
//                                               destructiveButtonTitle:nil
//                                                    otherButtonTitles:accountNames
//                                                           completion:^(NSString *buttonTitle){
//                                                               __typeof__(self) strongSelf = weakSelf;
//                                                               if (!strongSelf) {
//                                                                   return;
//                                                               }
//                                                               [strongSelf handleSelectedAccountWithName:buttonTitle
//                                                                                                    from:keyringConnections
//                                                                                           forPublicizer:pubServ];
//                                                           }];
//    [actionSheet showInView:self.view];

}


- (void)handleSelectedAccountWithName:(NSString *)accountName
                                 from:(NSArray *)keyringConnections
                        forPublicizer:(PublicizeService *)pubServ
{
    // Don't worry about secondary accounts for now.
    for (KeyringConnection *keyConn in keyringConnections) {
        if ([keyConn.externalDisplay isEqualToString:accountName]) {
            [self connectToPublicizeService:pubServ withKeyringConnection:keyConn];
            return;
        }
    }
//    [self refreshPublicizers];
}


- (void)connectToPublicizeService:(PublicizeService *)pubServ withKeyringConnection:(KeyringConnection *)keyConn
{
//    __weak __typeof__(self) weakSelf = self;
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [sharingService createPublicizeConnectionForBlog:self.blog
                                             keyring:keyConn
                                      externalUserID:nil
                                             success:^(PublicizeConnection *pubConn) {
                                                 // NOTE: We're just resyncing now but we'll actually use pubConn eventually.
//                                                 [weakSelf syncConnections];
                                             }
                                             failure:^(NSError *error) {
                                                 [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connect failed", @"Message to show when Publicize connect failed")];
//                                                 [weakSelf refreshPublicizers];
                                             }];
}


- (void)authorizePublicizer:(PublicizeService *)publicizer
                withRefresh:(NSString *)refresh
{
    NSParameterAssert(publicizer);
    
    SharingAuthorizationWebViewController *webViewController = [SharingAuthorizationWebViewController controllerWithPublicizer:publicizer
                                                                                                                    andRefresh:refresh
                                                                                                                       forBlog:self.blog];
    webViewController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)authorizeDidSucceed:(PublicizeService *)publicizer
{
    [self fetchKeyringConnectionsForService:publicizer];
}

- (void)authorize:(PublicizeService *)publicizer didFailWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Authorization failed", @"Message to show when Publicize authorization failed")];
//    [self refreshPublicizers];
}

- (void)authorizeDidCancel:(PublicizeService *)publicizer
{
//    // called in response to user dismissal
//    [self refreshPublicizers];
}

@end
