#import "SharingViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "WPTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationWebViewController.h"
#import "UIActionSheet+Helpers.h"
#import "WordPress-Swift.h"

typedef NS_ENUM(NSInteger, SharingSection){
    SharingPublicize = 0,
    //SharingConnections,
    //SharingButtons,
    //SharingOptions,
    SharingSectionCount,
};

static NSString *const PublicizeCellIdentifier = @"PublicizeCell";

@interface PublicizeCell : WPTableViewCell
@end

@implementation PublicizeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end

@interface SharingViewController () <SharingAuthorizationDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) NSArray *publicizeServices;
@property (nonatomic, strong) PublicizeService *connectingService;
@property (nonatomic, strong) PublicizeService *disconnectingService;

@end

@implementation SharingViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeServices = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Sharing", @"Title for blog detail sharing screen.");

    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[PublicizeCell class] forCellReuseIdentifier:PublicizeCellIdentifier];

    // Refreshes the tableview.
    [self refreshPublicizers];

    // Syncs servcies and connections.
    [self syncPublicizeServices];
}

- (void)refreshPublicizers
{
    self.connectingService = nil;
    self.disconnectingService = nil;

    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    self.publicizeServices = [sharingService allPublicizeServices];

    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SharingSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicize:
            return NSLocalizedString(@"Publicize", @"Section title for Publicize services in Sharing screen");
        default:
            return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (title.length > 0) {
        WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
        header.title = title;
        return header;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicize:
            return self.publicizeServices.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PublicizeCell *cell = [tableView dequeueReusableCellWithIdentifier:PublicizeCellIdentifier forIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];
    
    switch (indexPath.section) {
        case SharingPublicize: {
            PublicizeService *publicizer = self.publicizeServices[indexPath.row];
            cell.textLabel.text = publicizer.label;
            NSString *title = nil;
            if ([self.connectingService.serviceID isEqualToString:publicizer.serviceID]) {
                title = NSLocalizedString(@"Connecting…", @"Button title while a Publicize service is connecting");
            } else if ([self.disconnectingService.serviceID isEqualToString:publicizer.serviceID]) {
                title = NSLocalizedString(@"Disconnecting…", @"Button title while a Publicize service is disconnecting");
            } else if ([self blogIsConnectedToPublicizeService:publicizer]) {
                title = NSLocalizedString(@"Disconnect", @"Button title to disconnect a Publicize service");
            } else {
                title = NSLocalizedString(@"Connect", @"Button title to connect a Publicize service");
            }
            cell.detailTextLabel.text = title;
        } break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.connectingService || self.disconnectingService) {
        return;
    }
    
    PublicizeService *publicizer = self.publicizeServices[indexPath.row];
    if ([self blogIsConnectedToPublicizeService:publicizer]) {
        PublicizeConnection *pubConn;
        for (PublicizeConnection *connection in self.blog.connections) {
            if ([connection.service isEqualToString:publicizer.serviceID]) {
                pubConn = connection;
                break;
            }
        }
        if (pubConn == nil) {
            return;
        }

        self.disconnectingService = publicizer;
        [self disconnectPublicizer:pubConn];

    } else {
        self.connectingService = publicizer;
        [self authorizePublicizer:publicizer withRefresh:publicizer.connectURL];
    }

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Publicizer management

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

- (void)syncPublicizeServices
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeServices:^{
        [weakSelf syncConnections];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Publicize service synchronization failed", @"Message to show when Publicize service synchronization failed")];
        [weakSelf refreshPublicizers];
    }];
}

- (void)syncConnections
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeConnectionsForBlog:self.blog success:^{
        [weakSelf refreshPublicizers];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Publicize connection synchronization failed", @"Message to show when Publicize connection synchronization failed")];
        [weakSelf refreshPublicizers];
    }];
}

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

    __weak __typeof__(self) weakSelf = self;
    NSMutableArray *accountNames = [NSMutableArray array];
    for (KeyringConnection *keyConn in keyringConnections) {
        [accountNames addObject:keyConn.externalDisplay];
    }

    // TODO: Switch to UIAlertController
    // NOTE: Currently, implementation assumes account names will be different, but they could be the same.
    // We'll have better handling with UIAlertController. For now this works as a tester/demo
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect account:", @"Title of Publicize account selection")
                                                     cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:accountNames
                                                           completion:^(NSString *buttonTitle){
                                                               __typeof__(self) strongSelf = weakSelf;
                                                               if (!strongSelf) {
                                                                   return;
                                                               }
                                                               [strongSelf handleSelectedAccountWithName:buttonTitle
                                                                                                    from:keyringConnections
                                                                                           forPublicizer:pubServ];
                                                           }];
    [actionSheet showInView:self.view];

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
    [self refreshPublicizers];
}


- (void)connectToPublicizeService:(PublicizeService *)pubServ withKeyringConnection:(KeyringConnection *)keyConn
{
    __weak __typeof__(self) weakSelf = self;
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [sharingService createPublicizeConnectionForBlog:self.blog
                                             keyring:keyConn
                                      externalUserID:nil
                                             success:^(PublicizeConnection *pubConn) {
                                                 // NOTE: We're just resyncing now but we'll actually use pubConn eventually.
                                                 [weakSelf syncConnections];
                                             }
                                             failure:^(NSError *error) {
                                                 [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connect failed", @"Message to show when Publicize connect failed")];
                                                 [weakSelf refreshPublicizers];
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
    [self refreshPublicizers];
}

- (void)authorizeDidCancel:(PublicizeService *)publicizer
{
    // called in response to user dismissal
    [self refreshPublicizers];
}

- (void)disconnectPublicizer:(PublicizeConnection *)pubConn
{
    NSParameterAssert(pubConn);
    
    __weak __typeof__(self) weakSelf = self;

    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [sharingService deletePublicizeConnection:pubConn success:^{
        [weakSelf syncConnections];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Disconnect failed", @"Message to show when Publicize disconnect failed")];
        [weakSelf syncConnections];
    }];
}

@end
