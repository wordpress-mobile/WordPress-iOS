#import "SharingDetailViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationWebViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPTableViewCell.h"

#import "WordPress-Swift.h"

static NSString *const CellIdentifier = @"CellIdentifier";

@interface SharingDetailViewController () <SharingAuthorizationDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) PublicizeConnection *publicizeConnection;
@property (nonatomic, strong) PublicizeService *publicizeService;

@end

@implementation SharingDetailViewController

- (instancetype)initWithBlog:(Blog *)blog
         publicizeConnection:(PublicizeConnection *)connection
            publicizeService:(PublicizeService *)service
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert([connection isKindOfClass:[PublicizeConnection class]]);
    NSParameterAssert([service isKindOfClass:[PublicizeService class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeConnection = connection;
        _publicizeService = service;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = self.publicizeConnection.externalDisplay;

    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:CellIdentifier];
}


#pragma mark - Instance Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return self.blog.managedObjectContext;
}


#pragma mark - TableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.publicizeConnection isBroken]) {
        return 3;
    }

    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderFooterView heightForHeader:title width:CGRectGetWidth(self.view.bounds)];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (indexPath.section == 0) {
        cell = [self switchTableViewCell];

    } else if (indexPath.section == 1 && [self.publicizeConnection isBroken]) {
        cell.textLabel.text = NSLocalizedString(@"Reconnect", @"Verb. Text label. Tapping attempts to reconnect a third-party sharing service to the user's blog.");
        [WPStyleGuide configureTableViewActionCell:cell];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;

    } else {
        cell.textLabel.text = NSLocalizedString(@"Disconnect", @"Verb. Text label. Tapping disconnects a third-party sharing service from the user's blog.");
        [WPStyleGuide configureTableViewDestructiveActionCell:cell];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1 && [self.publicizeConnection isBroken]) {
        [self reconnectPublicizeConnection];

    } else {
        [self promptToConfirmDisconnect];
    }
}

- (SwitchTableViewCell *)switchTableViewCell
{
    SwitchTableViewCell *cell = [[SwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.text = NSLocalizedString(@"Available to all users", @"");
    cell.on = self.publicizeConnection.shared;

    __weak __typeof(self) weakSelf = self;
    cell.onChange = ^(BOOL value) {
        [weakSelf updateSharedGlobally:value];
    };

    return cell;
}


#pragma mark - Publicize Connection Methods

- (void)updateSharedGlobally:(BOOL)shared
{
    __weak __typeof(self) weakSelf = self;
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];

    [sharingService updateShared:shared
          forPublicizeConnection:self.publicizeConnection
                         success:nil
                         failure:^(NSError *error) {
                             DDLogError([error description]);
                             [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Change failed", @"Message to show when Publicize globally shared setting failed")];
                             [weakSelf.tableView reloadData];
                         }];
}

- (void)reconnectPublicizeConnection
{

}

- (void)disconnectPublicizeConnection
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [sharingService deletePublicizeConnection:self.publicizeConnection success:^{
        if (self.navigationController.topViewController == self) {
            [self.navigationController popViewControllerAnimated:YES];
        }

    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Disconnect failed", @"Message to show when Publicize disconnect failed")];
    }];
}

- (void)promptToConfirmDisconnect
{
    NSString *message = NSLocalizedString(@"Disconnecting this account means published posts will no longer be automatically shared to %@", @"Explanatory text for the user. The `%@` is a placeholder for the name of a third-party sharing service.");
    message = [NSString stringWithFormat:message, self.publicizeService.label];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addDestructiveActionWithTitle:NSLocalizedString(@"Disconnect", @"Verb. Title of a button. Tapping disconnects a third-party sharing service from the user's blog.")
                                 handler:^(UIAlertAction *action) {
                                     [self disconnectPublicizeConnection];
                                 }];

    [alert addCancelActionWithTitle:NSLocalizedString(@"Cancel", @"Verb. A button title.") handler:nil];

    [self presentViewController:alert animated:YES completion:nil];
}


@end
