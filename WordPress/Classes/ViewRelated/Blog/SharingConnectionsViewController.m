#import "SharingConnectionsViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "SharingDetailViewController.h"
#import "SharingAuthorizationHelper.h"
#import <WordPressShared/WPTableViewCell.h>
#import <WordPressUI/WordPressUI.h>
#import "WordPress-Swift.h"



static NSString *const CellIdentifier = @"CellIdentifier";

@interface SharingConnectionsViewController () <SharingAuthorizationHelperDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) PublicizeService *publicizeService;
@property (nonatomic, strong) SharingAuthorizationHelper *helper;
@property (nonatomic, assign) BOOL connecting;

@end

@implementation SharingConnectionsViewController

#pragma mark - Life Cycle Methods

- (void)dealloc
{
    self.helper.delegate = nil;
}

- (instancetype)initWithBlog:(Blog *)blog publicizeService:(PublicizeService *)publicizeService
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [self initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeService = publicizeService;
        _helper = [[SharingAuthorizationHelper alloc] initWithViewController:self blog:blog publicizeService:publicizeService];
        _helper.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = self.publicizeService.label;

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
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
                                                                            publicizeConnection:connection];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - TableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.publicizeService.serviceID isEqualToString:PublicizeService.googlePlusServiceID]) {
        if ([self hasConnectedAccounts]) {
            return 1;
        } else {
            return 0;
        }
    } else if ([self hasConnectedAccounts]) {
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([self hasConnectedAccounts] && section == 0) {
        return nil;
    }
    NSString *title = NSLocalizedString(@"Connect to automatically share your blog posts to %@", @"Instructional text appearing below a `Connect` button. The `%@` is a placeholder for the name of a third-party sharing service.");
    return [NSString stringWithFormat:title, self.publicizeService.label];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
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
        [self configureConnectionCell:cell atIndexPath:indexPath];
    }

    return cell;
}

- (void)configureConnectionCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [WPStyleGuide configureTableViewActionCell:cell];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = [self titleForConnectionCell];
    if (self.connecting) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = activityView;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [activityView startAnimating];
    } else {
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
}

- (NSString *)titleForConnectionCell
{
    if (self.connecting) {
        return NSLocalizedString(@"Connecting...", @"Verb. Text label. Allows the user to connect to a third-party sharing service like Facebook or Twitter.");
    }
    if ([self hasConnectedAccounts]) {
        return NSLocalizedString(@"Connect Another Account", @"Verb. Text label. Allows the user to connect to a third-party sharing service like Facebook or Twitter.");
    }
    return NSLocalizedString(@"Connect", @"Verb. Text label. Allows the user to connect to a third-party sharing service like Facebook or Twitter.");
}

- (void)configurePublicizeCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    PublicizeConnection *connection = [[self connectionsForService] objectAtIndex:indexPath.row];
    cell.textLabel.text = connection.externalDisplay;

    if ([connection requiresUserAction]) {
        cell.accessoryView = [WPStyleGuide sharingCellWarningAccessoryImageView];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self hasConnectedAccounts] && indexPath.section == 0) {
        PublicizeConnection *connection = [[self connectionsForService] objectAtIndex:indexPath.row];
        [self showDetailForConnection:connection];
        return;
    }

    if (self.connecting) {
        return;
    }

    [self handleConnectTapped:indexPath];
}


#pragma mark - Actions

- (void)handleConnectTapped:(NSIndexPath *)indexPath
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    if ([UIDevice isPad]) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        self.helper.popoverSourceView = cell.textLabel;
    }

    [self.helper connectPublicizeService];
}

- (void)handleContinueURLTapped:(NSURL*)url
{
    UIApplication *application = [UIApplication sharedApplication];

    if ([application canOpenURL:url]) {
        [application openURL:url options:@{} completionHandler:nil];
    }
}


#pragma mark - SharingAuthorizationHelper Delegate Methods

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper connectionFailedForService:(PublicizeService *)service
{
    self.connecting = NO;
    [self.tableView reloadData];
}

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper willConnectToService:(PublicizeService *)service usingKeyringConnection:(KeyringConnection *)keyringConnection
{
    self.connecting = YES;
    [self.tableView reloadData];
}

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper didConnectToService:(PublicizeService *)service withPublicizeConnection:(PublicizeConnection *)keyringConnection
{
    self.connecting = NO;
    [self.tableView reloadData];
    [self showDetailForConnection:keyringConnection];
}

- (void)sharingAuthorizationHelper:(SharingAuthorizationHelper *)helper
      requestToShowValidationError:(ValidationError *)validationError
                fromViewController:(UIViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];

    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:validationError.header
                                                                     message:validationError.body
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:validationError.cancelTitle
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];
    __weak SharingConnectionsViewController *sharingConnectionsVC = self;
    UIAlertAction* continueAction = [UIAlertAction actionWithTitle:validationError.continueTitle
                                                              style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              if (validationError.continueURL) {
                                                                  [sharingConnectionsVC handleContinueURLTapped: validationError.continueURL];
                                                              }
                                                          }];

    [alertVC addAction:continueAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
