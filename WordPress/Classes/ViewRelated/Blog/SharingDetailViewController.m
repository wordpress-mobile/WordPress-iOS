#import "SharingDetailViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationHelper.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPTableViewCell.h"

#import "WordPress-Swift.h"

static NSString *const CellIdentifier = @"CellIdentifier";

@interface SharingDetailViewController () <SharingAuthorizationHelperDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) PublicizeConnection *publicizeConnection;
@property (nonatomic, strong) PublicizeService *publicizeService;
@property (nonatomic, strong) SharingAuthorizationHelper *helper;
@end

@implementation SharingDetailViewController

- (void)dealloc
{
    self.helper.delegate = nil;
}

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
        _helper = [[SharingAuthorizationHelper alloc] initWithViewController:self blog:blog publicizeService:service];
        _helper.delegate = self;
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
    if (section == 1 && [self.publicizeConnection isBroken]) {
        NSString *title = NSLocalizedString(@"There is an issue connecting to %@. Reconnect to continue publicizing.", @"Informs the user about an issue connecting to the third-party sharing service. The `%@` is a placeholder for the service name.");
        return [NSString stringWithFormat:title, self.publicizeService.label];
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
        cell.textLabel.textColor = [WPStyleGuide jazzyOrange];

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
    [sharingService updateSharedForBlog:self.blog
                                 shared:shared
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
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    [self.helper reconnectPublicizeConnection:self.publicizeConnection];
}

- (void)disconnectPublicizeConnection
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [sharingService deletePublicizeConnectionForBlog:self.blog pubConn:self.publicizeConnection success:nil failure:^(NSError *error) {
        DDLogError([error description]);
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Disconnect failed", @"Message to show when Publicize disconnect failed")];
    }];

    // Since the service optimistically deletes the connection, go ahead and pop.
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)promptToConfirmDisconnect
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

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

    if ([UIDevice isPad]) {
        alert.modalPresentationStyle = UIModalPresentationPopover;
        [self presentViewController:alert animated:YES completion:nil];

        NSUInteger section = [self.publicizeConnection isBroken] ? 2 : 1;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        UIPopoverPresentationController *presentationController = alert.popoverPresentationController;
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.sourceView = cell.textLabel;
        presentationController.sourceRect = cell.textLabel.bounds;
    } else {
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - SharingAuthenticationHelper Delegate Methods

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper didConnectToService:(PublicizeService *)service withPublicizeConnection:(PublicizeConnection *)keyringConnection
{
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Reconnected", @"Message shwon to confirm a publicize connection has been successfully reconnected.")];
}

@end
