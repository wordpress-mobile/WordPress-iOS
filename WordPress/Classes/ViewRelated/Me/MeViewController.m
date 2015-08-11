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
#import <WordPress-iOS-Shared/WPTableViewSectionHeaderFooterView.h>
#import "HelpshiftUtils.h"
#import "WordPress-Swift.h"


typedef NS_ENUM(NSInteger, MeSectionSections)
{
    MeSectionsAccount = 0,
    MeSectionsExtra,
    MeSectionsWpCom,
    MeSectionsCount
};

typedef NS_ENUM(NSInteger, MeSectionAccount) {
    MeSectionAccountSettings = 0,
    MeSectionAccountNotifications,
    MeSectionAccountCount
};

typedef NS_ENUM(NSInteger, MeSectionExtra) {
    MeSectionExtraHelp = 0,
    MeSectionExtraAbout,
    MeSectionExtraCount
};

typedef NS_ENUM(NSInteger, MeSectionWpCom) {
    MeSectionWpComAuthentication = 0,
    MeSectionWpComCount
};


static NSString *const WPMeRestorationID = @"WPMeRestorationID";
static NSString *const MVCCellReuseIdentifier = @"MVCCellReuseIdentifier";

@interface MeViewController () <UIViewControllerRestoration, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UITableView   *tableView;
@property (nonatomic, strong) MeHeaderView  *headerView;
@property (nonatomic, strong) NSDictionary  *rowCountMap;

@end

@implementation MeViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [self new];
}

#pragma mark - LifeCycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Me", @"Me page title");
        self.restorationIdentifier = WPMeRestorationID;
        self.restorationClass = [self class];

        // we want to observe for the account change notification even if the view is not visible
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultAccountDidChange:)
                                                     name:WPAccountDefaultWordPressComAccountChangedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(helpshiftUnreadCountUpdated:)
                                                     name:HelpshiftUnreadCountUpdatedNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self buildTableView];
    [self refreshAccountUserDetails];
    [self refreshHeaderView];
    [self refreshTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];

    [HelpshiftUtils refreshUnreadNotificationCount];
}

#pragma mark - View Construction / Configuration

- (void)buildTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = WPTableViewDefaultRowHeight;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:MVCCellReuseIdentifier];
    [self.view addSubview:self.tableView];

    self.headerView = [[MeHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), MeHeaderViewHeight)];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    [self setupAutolayoutConstraints];
}

- (void)setupAutolayoutConstraints
{
    NSMutableDictionary *views = [@{@"tableView": self.tableView} mutableCopy];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
}

- (void)refreshAccountUserDetails
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    if (!defaultAccount) {
        return;
    }

    // We want to keep email and default blog information up to date, this is a reasonable best place to do it
    [accountService updateUserDetailsForAccount:defaultAccount success:^{
        [self refreshHeaderViewEmail];
    } failure:nil];
}

#pragma mark - Header methods

- (void)refreshHeaderView
{
    WPAccount *defaultAccount = [self defaultAccount];

    if (defaultAccount) {
        self.tableView.tableHeaderView = self.headerView;
        [self.headerView setDisplayName:defaultAccount.displayName];
        [self.headerView setUsername:defaultAccount.username];
        [self.headerView setGravatarEmail:defaultAccount.email];
    }
    else {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)refreshHeaderViewEmail
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    [self.headerView setGravatarEmail:defaultAccount.email];
}

- (void)refreshTableView
{
    // Let's hide the Notifications Row, whenever there is no default account
    NSInteger accountRowCount = MeSectionAccountCount;
    if (!self.defaultAccount) {
        --accountRowCount;
    }
    
    self.rowCountMap = @{
        @(MeSectionsAccount)    : @(accountRowCount),
        @(MeSectionsExtra)      : @(MeSectionExtraCount),
        @(MeSectionsWpCom)      : @(MeSectionWpComCount)
    };
    
    [self.tableView reloadData];
}

- (WPAccount *)defaultAccount
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    
    return accountService.defaultWordPressComAccount;
}

- (UILabel *)helpshiftBadgeLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 15;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
    label.textColor = [UIColor whiteColor];
    return label;
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return MeSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rowCountMap[@(section)] intValue] ?: 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MVCCellReuseIdentifier];
    [WPStyleGuide configureTableViewCell:cell];

    if (indexPath.section == MeSectionsAccount) {
        switch (indexPath.row) {
            case MeSectionAccountSettings:
                cell.textLabel.text = NSLocalizedString(@"Account Settings", @"");
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.accessibilityLabel = @"Account Settings";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case MeSectionAccountNotifications:
                cell.textLabel.text = NSLocalizedString(@"Notification Settings", @"");
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.accessibilityLabel = @"Notification Settings";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
        }
    } else if (indexPath.section == MeSectionsExtra) {
        switch (indexPath.row) {
            case MeSectionExtraHelp:
                cell.textLabel.text = NSLocalizedString(@"Help & Support", @"");
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.accessibilityLabel = @"Help & Support";

                NSInteger unreadNotificationCount = [HelpshiftUtils unreadNotificationCount];
                if ([HelpshiftUtils isHelpshiftEnabled] && unreadNotificationCount > 0) {
                    UILabel *label = [self helpshiftBadgeLabel];
                    label.text = [NSString stringWithFormat:@"%ld", unreadNotificationCount];
                    cell.accessoryView = label;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                } else {
                    cell.accessoryView = nil;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                break;
            case MeSectionExtraAbout:
                cell.textLabel.text = NSLocalizedString(@"About", @"");
                cell.textLabel.textAlignment = NSTextAlignmentLeft;
                cell.accessibilityLabel = @"About";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
        }
    } else if (indexPath.section == MeSectionsWpCom) {
        if (indexPath.row == MeSectionWpComAuthentication) {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
            
            cell.accessoryType = UITableViewCellAccessoryNone;

            if (defaultAccount) {
                NSString *signOutString = NSLocalizedString(@"Disconnect from WordPress.com",
                                                            @"Label for disconnecting from WordPress.com account");
                cell.textLabel.text = signOutString;
                cell.accessibilityIdentifier = signOutString;
                [WPStyleGuide configureTableViewDestructiveActionCell:cell];
            }
            else {
                NSString *signInString = NSLocalizedString(@"Connect to WordPress.com",
                                                           @"Label for connecting to WordPress.com account");
                cell.textLabel.text = signInString;
                cell.accessibilityIdentifier = signInString;
                [WPStyleGuide configureTableViewActionCell:cell];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
            }
        }
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];
    if (!title) {
        return CGFLOAT_MIN;
    }
    
    return [WPTableViewSectionHeaderFooterView heightForHeader:title width:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (section == MeSectionsWpCom) {
        return NSLocalizedString(@"WordPress.com Account", @"WordPress.com sign-in/sign-out section header title");
    }
    return nil;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == MeSectionsAccount) {
        switch (indexPath.row) {
            case MeSectionAccountSettings:
                [self navigateToAccountSettings];
                break;
            case MeSectionAccountNotifications:
                [self navigateToNotificationSettings];
                break;
        }
    } else if (indexPath.section == MeSectionsExtra) {
        switch (indexPath.row) {
            case MeSectionExtraHelp:
                [self navigateToHelp];
                break;
            case MeSectionExtraAbout:
                [self navigateToAbout];
                break;
        }
        
    } else if (indexPath.section == MeSectionsWpCom) {
        if (indexPath.row == MeSectionWpComAuthentication) {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

            if (defaultAccount) {
                // Present the Sign out ActionSheet
                NSString *signOutTitle = NSLocalizedString(@"Disconnecting your account will remove all of @%@’s WordPress.com data from this device.",
                                                           @"Label for disconnecting WordPress.com account. The %@ is a placeholder for the user's screen name.");
                signOutTitle = [NSString stringWithFormat:signOutTitle, [defaultAccount username]];
                UIActionSheet *actionSheet;
                actionSheet = [[UIActionSheet alloc] initWithTitle:signOutTitle
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                            destructiveButtonTitle:NSLocalizedString(@"Disconnect", @"Button for confirming disconnecting WordPress.com account")
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
                loginViewController.dismissBlock = ^(BOOL cancelled){
                    [self dismissViewControllerAnimated:YES completion:nil];
                };

                UINavigationController *loginNavigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
                [self presentViewController:loginNavigationController animated:YES completion:nil];
            }
        }
    }
}

#pragma mark - Actions

- (void)navigateToAccountSettings
{
    [WPAnalytics track:WPAnalyticsStatOpenedSettings];

    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)navigateToNotificationSettings
{
    NSString *nibName = [NotificationSettingsViewController classNameWithoutNamespaces];
    NotificationSettingsViewController *settingsViewController = [[NotificationSettingsViewController alloc] initWithNibName:nibName bundle:nil];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)navigateToHelp
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController pushViewController:supportViewController animated:YES];
}

- (void)navigateToAbout
{
    NSString *nibName               = [AboutViewController classNameWithoutNamespaces];
    AboutViewController *aboutVC    = [[AboutViewController alloc] initWithNibName:nibName bundle:nil];
    
    [self.navigationController pushViewController:aboutVC animated:YES];
}


#pragma mark - Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification
{
    [self refreshHeaderView];
    [self refreshTableView];
}


#pragma mark - Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // Sign out asynchronously so the popover animation can finish on iPad #3667
        dispatch_async(dispatch_get_main_queue(), ^{
            // Sign out
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

            [accountService removeDefaultWordPressComAccount];

            // reload all table view to update the header as well
            [self refreshTableView];
        });
    }
}

#pragma mark - Helpshift Notifications

- (void)helpshiftUnreadCountUpdated:(NSNotification *)notification
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:MeSectionExtraHelp inSection:MeSectionsExtra];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
