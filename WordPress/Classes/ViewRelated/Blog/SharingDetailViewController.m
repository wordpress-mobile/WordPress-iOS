#import "SharingDetailViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SVProgressHUD+Dismiss.h"
#import "SharingAuthorizationHelper.h"
#import <WordPressShared/WPTableViewCell.h>
#import <WordPressUI/WordPressUI.h>
#import "WordPress-Swift.h"



static NSString *const CellIdentifier = @"CellIdentifier";

@interface SharingDetailViewController () <SharingAuthorizationHelperDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) PublicizeConnection *publicizeConnection;
@property (nonatomic, strong) SharingAuthorizationHelper *helper;
@end

@implementation SharingDetailViewController

- (void)dealloc
{
    self.helper.delegate = nil;
}

- (instancetype)initWithBlog:(Blog *)blog
         publicizeConnection:(PublicizeConnection *)connection
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert([connection isKindOfClass:[PublicizeConnection class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeConnection = connection;
        SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
        PublicizeService *publicizeService = [sharingService findPublicizeServiceNamed:connection.service];
        if (publicizeService) {
            self.helper = [[SharingAuthorizationHelper alloc] initWithViewController:self
                                                                                blog:self.blog
                                                                    publicizeService:publicizeService];
            self.helper.delegate = self;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = self.publicizeConnection.externalDisplay;

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:CellIdentifier];
}


#pragma mark - Instance Methods

- (void)openFacebookFAQ
{
    NSURL *url = [NSURL URLWithString:@"https://en.blog.wordpress.com/2018/07/23/sharing-options-from-wordpress-com-to-facebook-are-changing/"];
    [[UIApplication sharedApplication] openURL:url options:[NSDictionary new] completionHandler:nil];
}

- (NSString *)textForFacebookFooter
{
    NSString *title = NSLocalizedString(@"As of August 1, 2018, Facebook no longer allows direct sharing of posts to Facebook Profiles. Connections to Facebook Pages remain unchanged.", @"Message shown to users who have an old publicize connection to a facebook profile.");
    return [NSString stringWithFormat:title, self.publicizeConnection.label];
}

- (NSString *)textForBrokenConnectionFooter
{
    NSString *title = NSLocalizedString(@"There is an issue connecting to %@. Reconnect to continue publicizing.", @"Informs the user about an issue connecting to the third-party sharing service. The `%@` is a placeholder for the service name.");
    return [NSString stringWithFormat:title, self.publicizeConnection.label];
}

- (void)configureReconnectCell: (UITableViewCell *)cell
{
    cell.textLabel.text = NSLocalizedString(@"Reconnect", @"Verb. Text label. Tapping attempts to reconnect a third-party sharing service to the user's blog.");
    [WPStyleGuide configureTableViewActionCell:cell];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor murielAccent];
}

- (void)configureLearnMoreCell: (UITableViewCell *)cell
{
    cell.textLabel.text = NSLocalizedString(@"Learn More", @"Title of a button. Tapping allows the user to learn more about the specific error.");
    [WPStyleGuide configureTableViewActionCell:cell];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor murielPrimary];
}

- (void)configureDisconnectCell: (UITableViewCell *)cell
{
    cell.textLabel.text = NSLocalizedString(@"Disconnect", @"Verb. Text label. Tapping disconnects a third-party sharing service from the user's blog.");
    [WPStyleGuide configureTableViewDestructiveActionCell:cell];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.blog.managedObjectContext;
}


#pragma mark - TableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.publicizeConnection requiresUserAction]) {
        return 3;
    }

    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Settings", @"Section title");
    }

    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Allow this connection to be used by all admins and users of your site.", @"");
    }

    if (section == 1) {
        if ([self.publicizeConnection mustDisconnectFacebook]) {
            return [self textForFacebookFooter];
        }

        if ([self.publicizeConnection isBroken]) {
            return [self textForBrokenConnectionFooter];
        }
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
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
        [self configureReconnectCell:cell];

    } else if (indexPath.section == 1 && [self.publicizeConnection mustDisconnectFacebook]) {
        [self configureLearnMoreCell:cell];

    } else {
        [self configureDisconnectCell:cell];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1 && [self.publicizeConnection isBroken]) {
        [self reconnectPublicizeConnection];
    } else if (indexPath.section == 1 && [self.publicizeConnection mustDisconnectFacebook]) {
            [self openFacebookFAQ];
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
                                    [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Change failed", @"Message to show when Publicize globally shared setting failed")];
                                    [weakSelf.tableView reloadData];
                                }];
}

- (void)reconnectPublicizeConnection
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];

    __weak __typeof(self) weakSelf = self;
    if (self.helper == nil) {
        [sharingService syncPublicizeServicesForBlog:self.blog
                                             success:^{
                                                 [[weakSelf helper] reconnectPublicizeConnection:weakSelf.publicizeConnection];
                                             }
                                             failure:^(NSError * _Nullable error) {
                                                 [WPError showNetworkingAlertWithError:error];
                                             }];
    } else {
        [self.helper reconnectPublicizeConnection:weakSelf.publicizeConnection];
    }
}

- (void)disconnectPublicizeConnection
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [sharingService deletePublicizeConnectionForBlog:self.blog pubConn:self.publicizeConnection success:nil failure:^(NSError *error) {
        DDLogError([error description]);
        [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Disconnect failed", @"Message to show when Publicize disconnect failed")];
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
    message = [NSString stringWithFormat:message, self.publicizeConnection.label];
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
    [SVProgressHUD showDismissibleSuccessWithStatus:NSLocalizedString(@"Reconnected", @"Message shwon to confirm a publicize connection has been successfully reconnected.")];
}

@end
