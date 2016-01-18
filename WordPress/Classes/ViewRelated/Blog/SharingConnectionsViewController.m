#import "SharingConnectionsViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "SVProgressHUD.h"
#import "SharingDetailViewController.h"
#import "SharingAuthorizationWebViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPTableViewCell.h"
#import "WordPress-Swift.h"

static NSString *const CellIdentifier = @"CellIdentifier";

@interface SharingConnectionsViewController () <SharingAuthorizationDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) PublicizeService *publicizeService;

@end

@implementation SharingConnectionsViewController

#pragma mark - Life Cycle Methods

- (instancetype)initWithBlog:(Blog *)blog publicizeService:(PublicizeService *)publicizeService
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [self initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeService = publicizeService;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = self.publicizeService.label;

    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:CellIdentifier];

}


#pragma mark - Instance Methods

- (NSArray *)connectionsForService
{
    NSMutableArray *connections = [NSMutableArray array];
    for (PublicizeConnection *pubConn in self.blog.connections) {
        if ([pubConn.service isEqualToString:self.publicizeService.serviceID]) {
            [connections addObject:pubConn];
        }
    }
    return [NSArray arrayWithArray:connections];
}

- (BOOL)hasConnectedAccounts
{
    return [[self connectionsForService] count] > 0;
}

- (void)showDetailForConnection:(PublicizeConnection *)connection
{
    SharingDetailViewController *controller = [[SharingDetailViewController alloc] initWithBlog:self.blog
                                                                            publicizeConnection:connection
                                                                               publicizeService:self.publicizeService];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - TableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self hasConnectedAccounts]) {
        return 2;
    }

    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    if ([self hasConnectedAccounts] && section == 0) {
        title = NSLocalizedString(@"Connected Accounts", @"Noun. Title. Title for the list of accounts for third party sharing services.");
    } else {
        NSString *format = NSLocalizedString(@"Publicize to %@", @"Title. `Publicize` is used as a verb here but `Share` (verb) would also work here. The `%@` is a placeholder for the service name.");
        title = [NSString stringWithFormat:format, self.publicizeService.label];
    }

    return title;
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
    if ([self hasConnectedAccounts] && section == 0) {
        return nil;
    }

    NSString *title = NSLocalizedString(@"Connect to automatically share your blog posts to %@", @"Instructional text appearing below a `Connect` button. The `%@` is a placeholder for the name of a third-party sharing service.");
    return [NSString stringWithFormat:title, self.publicizeService.label];
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
    if ([self hasConnectedAccounts] && section == 0) {
        return [[self connectionsForService] count];
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    // resets the cell
    [WPStyleGuide configureTableViewCell:cell];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.textLabel.textAlignment = NSTextAlignmentNatural;

    if ([self hasConnectedAccounts] && indexPath.section == 0) {
        [self configurePublicizeCell:cell atIndexPath:indexPath];

    } else {
        [WPStyleGuide configureTableViewActionCell:cell];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.text = NSLocalizedString(@"Connect", @"Verb. Text label. Allows the user to connect to a third-party sharing service like Facebook or Twitter.");
    }

    return cell;
}

- (void)configurePublicizeCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    PublicizeConnection *connection = [[self connectionsForService] objectAtIndex:indexPath.row];
    cell.textLabel.text = connection.externalDisplay;

    if ([connection.status isEqualToString:@"broken"]) {
        cell.accessoryView = [self warningAccessoryView];
    }
}

- (UIImageView *)warningAccessoryView
{
    //TODO: Need actual exclaimation graphic.
    CGFloat imageSize = 22.0;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageSize, imageSize)];
    imageView.image = [UIImage imageWithColor:[WPStyleGuide jazzyOrange]
                                   havingSize:imageView.frame.size];
    imageView.layer.cornerRadius = imageSize / 2.0;
    imageView.layer.masksToBounds = YES;
    return imageView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self hasConnectedAccounts] && indexPath.section == 0) {
        PublicizeConnection *connection = [[self connectionsForService] objectAtIndex:indexPath.row];
        [self showDetailForConnection:connection];
        return;
    }

    [self handleConnectTapped];
}


#pragma mark - Actions

- (void)handleConnectTapped
{
    SharingAuthorizationWebViewController *webViewController = [SharingAuthorizationWebViewController controllerWithPublicizer:self.publicizeService
                                                                                                                       forBlog:self.blog];
    webViewController.delegate = self;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - Authorization Delegate Methods

- (void)authorizeDidSucceed:(PublicizeService *)publicizer
{
    [self fetchKeyringConnectionsForService:publicizer];
}

- (void)authorize:(PublicizeService *)publicizer didFailWithError:(NSError *)error
{
    DDLogError([error description]);
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection failed", @"Message to show when Publicize authorization failed")];
}

- (void)authorizeDidCancel:(PublicizeService *)publicizer
{
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection canceled", @"Message to show when Publicize authorization is canceled")];
}


#pragma mark - Keyring Wrangling

- (void)fetchKeyringConnectionsForService:(PublicizeService *)pubServ
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self.blog managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService fetchKeyringConnections:^(NSArray *keyringConnections) {
        NSMutableArray *marr = [NSMutableArray array];
        for (KeyringConnection *keyConn in keyringConnections) {
            if ([keyConn.service isEqualToString:pubServ.serviceID]) {
                [marr addObject:keyConn];
            }
        }
        [weakSelf selectKeyring:marr];

    } failure:^(NSError *error) {
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

    NSString *message = NSLocalizedString(@"Confirm this is the account you would like to authorize. Note that your posts will be automatically shared to this account.", @"");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    for (KeyringConnection *keyConn in keyringConnections) {
        [alertController addActionWithTitle:keyConn.externalDisplay style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [weakSelf connectToServiceWithKeyringConnection:keyConn];
                                    }];
    }

    [alertController addCancelActionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                      handler:^(UIAlertAction *action) {
                                          NSString *str = [NSString stringWithFormat:@"The %@ connection could not be made because no account was selected.", self.publicizeService.label];
                                          NSLog(str);
                                      }];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)connectToServiceWithKeyringConnection:(KeyringConnection *)keyConn
{
    __weak __typeof__(self) weakSelf = self;
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self.blog managedObjectContext]];
    [sharingService createPublicizeConnectionForBlog:self.blog
                                             keyring:keyConn
                                      externalUserID:nil
                                             success:^(PublicizeConnection *pubConn) {
                                                 [weakSelf.tableView reloadData];
                                                 [weakSelf showDetailForConnection:pubConn];
                                             }
                                             failure:^(NSError *error) {
                                                 DDLogError([error description]);
                                                 [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connection failed", @"Message to show when Publicize connect failed")];
                                             }];
}

@end
