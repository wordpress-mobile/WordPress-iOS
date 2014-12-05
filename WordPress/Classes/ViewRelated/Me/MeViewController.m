// Me contents:
//
// + (No Title)
// | Account Settings
// | Help & Support
//
// + (No Title)
// | Log out

#import "MeViewController.h"
#import "SettingsViewController.h"
#import "SupportViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "MeHeaderView.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "LoginViewController.h"
#import <WordPress-iOS-Shared/WPTableViewCell.h>

const typedef enum {
    MeRowAccountSettings = 0,
    MeRowHelp = 1,
    MeRowLoginLogout = 0
} MeRow;

const typedef enum {
    MeSectionGeneralType = 0,
    MeSectionWpCom
} MeSectionContentType;

static NSString *const MVCCellReuseIdentifier = @"MVCCellReuseIdentifier";

static CGFloat const MVCTableViewRowHeight = 50.0;

@interface MeViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MeHeaderView *headerView;

@end

@implementation MeViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = MVCTableViewRowHeight;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:MVCCellReuseIdentifier];
    [self.view addSubview:self.tableView];

    self.headerView = [[MeHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), MeHeaderViewHeight)];

    [self setupAutolayoutConstraints];
}

- (void)setupAutolayoutConstraints
{
    NSMutableDictionary *views = [@{@"tableView": self.tableView} mutableCopy];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultAccountDidChange:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];

    [self refreshDetails];
}

- (void)refreshDetails
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if (defaultAccount) {
        self.tableView.tableHeaderView = self.headerView;
        [self.headerView setUsername:defaultAccount.username];
        [self.headerView setGravatarEmail:@"beau@automattic.com"];
    }
    else {
        self.tableView.tableHeaderView = nil;
    }

    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == MeSectionGeneralType) {
        return 2;
    }
    if (section == MeSectionWpCom) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MVCCellReuseIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [WPStyleGuide configureTableViewActionCell:cell];

    if (indexPath.section == MeSectionGeneralType) {
        switch (indexPath.row) {
            case MeRowAccountSettings:
                cell.textLabel.text = NSLocalizedString(@"Account Settings", @"");
                cell.accessibilityLabel = @"Account Settings";
                break;
            case MeRowHelp:
                cell.textLabel.text = NSLocalizedString(@"Help & Support", @"");
                cell.accessibilityLabel = @"Help & Support";
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == MeSectionWpCom) {
        if (indexPath.row == MeRowLoginLogout) {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

            if (defaultAccount) {
                cell.textLabel.text = NSLocalizedString(@"Sign Out", @"Sign out from WordPress.com");
                cell.accessibilityIdentifier = @"Sign Out";
            }
            else {
                cell.textLabel.text = NSLocalizedString(@"Sign In", @"Sign in to WordPress.com");
                cell.accessibilityIdentifier = @"Sign In";
            }
        }
    }
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == MeSectionGeneralType) {
        switch (indexPath.row) {
            case MeRowAccountSettings:
                [self navigateToSettings];
                break;
            case MeRowHelp:
                [self navigateToHelp];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == MeSectionWpCom) {
        if (indexPath.row == MeRowLoginLogout) {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

            if (defaultAccount) {
                // Present the Sign out ActionSheet
                NSString *signOutTitle = NSLocalizedString(@"You are logged in as %@", @"");
                signOutTitle = [NSString stringWithFormat:signOutTitle, [defaultAccount username]];
                UIActionSheet *actionSheet;
                actionSheet = [[UIActionSheet alloc] initWithTitle:signOutTitle
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                            destructiveButtonTitle:NSLocalizedString(@"Sign Out", @"")
                                                 otherButtonTitles:nil];
                actionSheet.actionSheetStyle = UIActionSheetStyleDefault;

                if (IS_IPAD) {
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    [actionSheet showFromRect:[cell bounds] inView:cell animated:YES];
                } else {
                    [actionSheet showInView:self.view];
                }
            } else {
                LoginViewController *loginViewController = [[LoginViewController alloc] init];
                loginViewController.onlyDotComAllowed = YES;
                loginViewController.cancellable = YES;
                loginViewController.dismissBlock = ^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                };

                UINavigationController *loginNavigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
                [self presentViewController:loginNavigationController animated:YES completion:nil];
            }
        }
    }
}

#pragma mark - Actions

- (void)navigateToSettings
{
    [WPAnalytics track:WPAnalyticsStatOpenedSettings];

    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)navigateToHelp
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController pushViewController:supportViewController animated:YES];
}

#pragma mark - Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification
{
    [self refreshDetails];
}

#pragma mark -
#pragma mark Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // Sign out
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

        [accountService removeDefaultWordPressComAccount];

        // reload all table view to update the header as well
        [self.tableView reloadData];
    }
}

@end
