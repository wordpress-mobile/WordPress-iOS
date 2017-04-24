#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "ActivityLogViewController.h"
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import "WordPressAppDelegate.h"
#import <CocoaLumberjack/DDFileLogger.h>
#import "HelpshiftSupport.h"
#import "WPAnalytics.h"
#import <WordPressShared/WPStyleGuide.h>
#import "ContextManager.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "BlogService.h"
#import "Blog.h"
#import "NSBundle+VersionNumberHelper.h"
#import "WordPress-Swift.h"
#import "WPTabBarController.h"
#import "WPAppAnalytics.h"
#import "HelpshiftUtils.h"
#import "WPLogger.h"
#import "WPGUIConstants.h"

SupportSourceTag const SupportSourceTagWPComLogin = @"origin:wpcom-login-screen";
SupportSourceTag const SupportSourceTagWPComSignup = @"origin:signup-screen";
SupportSourceTag const SupportSourceTagWPOrgLogin = @"origin:wporg-login-screen";
SupportSourceTag const SupportSourceTagJetpackLogin = @"origin:jetpack-login-screen";
SupportSourceTag const SupportSourceTagGeneralLogin = @"origin:login-screen";

static NSString *const WPSupportRestorationID = @"WPSupportRestorationID";

static NSString *const kExtraDebugDefaultsKey = @"extra_debug";

int const kHelpshiftWindowTypeFAQs = 1;
int const kHelpshiftWindowTypeConversation = 2;

@interface SupportViewController () <UIViewControllerRestoration>
@property (nonatomic, strong) NSIndexPath *helpshiftLoadingIndexPath;
@end

@implementation SupportViewController

typedef NS_ENUM(NSInteger, SettingsViewControllerSections)
{
    SettingsSectionFAQForums,
    SettingsSectionSettings,
    SettingsSectionCount
};

typedef NS_ENUM(NSInteger, SettingsSectionFAQForumsRows)
{
    SettingsSectionFAQForumsRowHelpCenter,
    SettingsSectionFAQForumsRowContact,
    SettingsSectionFAQForumsRowCount
};

typedef NS_ENUM(NSInteger, SettingsSectionActivitySettingsRows)
{
    SettingsSectionSettingsRowVersion,
    SettingsSectionSettingsRowExtraDebug,
    SettingsSectionSettingsRowTracking,
    SettingsSectionSettingsRowActivityLogs,
    SettingsSectionSettingsRowCount
};

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

- (void)showFromTabBar
{
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:self];
    aNavigationController.navigationBar.translucent = NO;

    if (IS_IPAD) {
        aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    UIViewController *presenter = [WPTabBarController sharedInstance];
    if (presenter.presentedViewController) {
        presenter = presenter.presentedViewController;
    }
    [presenter presentViewController:aNavigationController animated:YES completion:nil];
}

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Support", @"");
        self.restorationIdentifier = WPSupportRestorationID;
        self.restorationClass = [self class];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setRowHeight:WPTableViewDefaultRowHeight];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    [self.navigationController setNavigationBarHidden:NO animated:YES];

    if ([self.navigationController.viewControllers count] == 1 && !self.splitViewController) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(helpshiftUnreadCountUpdated:)
                                                 name:HelpshiftUnreadCountUpdatedNotification
                                               object:nil];

    [HelpshiftUtils refreshUnreadNotificationCount];
    [WPAnalytics track:WPAnalyticsStatOpenedSupport];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setHelpshiftLoadingIndexPath:(NSIndexPath *)helpshiftLoadingIndexPath
{
    if (_helpshiftLoadingIndexPath != helpshiftLoadingIndexPath) {
        NSIndexPath *reloadIndexPath = helpshiftLoadingIndexPath ?: _helpshiftLoadingIndexPath;

        _helpshiftLoadingIndexPath = helpshiftLoadingIndexPath;

        [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)prepareAndDisplayHelpshiftWindowOfType:(int)helpshiftType
{
    HelpshiftPresenter *presenter = [HelpshiftPresenter new];
    presenter.sourceTag = self.sourceTag;

    __weak __typeof(self) weakSelf = self;
    void (^completion)() = ^{
        weakSelf.helpshiftLoadingIndexPath = nil;
    };

    if (helpshiftType == kHelpshiftWindowTypeFAQs) {
        self.helpshiftLoadingIndexPath = [NSIndexPath indexPathForRow:SettingsSectionFAQForumsRowHelpCenter
                                                                                     inSection:SettingsSectionFAQForums];

        [presenter presentHelpshiftFAQWindowFromViewController:self
                                            refreshUserDetails:YES
                                                    completion:completion];
    } else if (helpshiftType == kHelpshiftWindowTypeConversation) {
        self.helpshiftLoadingIndexPath = [NSIndexPath indexPathForRow:SettingsSectionFAQForumsRowContact
                                                            inSection:SettingsSectionFAQForums];

        [presenter presentHelpshiftConversationWindowFromViewController:self
                                                     refreshUserDetails:YES
                                                             completion:completion];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SettingsSectionFAQForums) {
        return SettingsSectionFAQForumsRowCount;
    }

    if (section == SettingsSectionSettings) {
        return SettingsSectionSettingsRowCount;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = nil;
    if (indexPath.section == SettingsSectionSettings
        && (indexPath.row == SettingsSectionSettingsRowExtraDebug
            || indexPath.row == SettingsSectionSettingsRowTracking)) {
        // Settings / Extra Debug
        static NSString *CellIdentifierSwitchAccessory = @"SupportViewSwitchAccessoryCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierSwitchAccessory];

        if (cell == nil) {
            cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierSwitchAccessory];
        }

        UISwitch *switchAccessory = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchAccessory.tag = indexPath.row;
        [switchAccessory addTarget:self action:@selector(handleCellSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchAccessory;
    } else if (indexPath.section == SettingsSectionFAQForums && indexPath.row == SettingsSectionFAQForumsRowHelpCenter) {
        static NSString *CellIdentifierBadgeAccessory = @"SupportViewBadgeAccessoryCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierBadgeAccessory];

        if (cell == nil) {
            cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierBadgeAccessory];
        }
    } else {
        static NSString *CellIdentifier = @"SupportViewStandardCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)addActivityIndicatorViewToTableViewCell:(UITableViewCell *)cell
{
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicator startAnimating];

    cell.accessoryView = activityIndicator;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentNatural;
    [WPStyleGuide configureTableViewCell:cell];

    if (indexPath.section == SettingsSectionFAQForums) {
        if (indexPath.row == SettingsSectionFAQForumsRowHelpCenter) {
            cell.textLabel.text = NSLocalizedString(@"WordPress Help Center", @"");

            if (indexPath == self.helpshiftLoadingIndexPath) {
                [self addActivityIndicatorViewToTableViewCell:cell];
            } else {
                cell.accessoryView = nil;
            }

            [WPStyleGuide configureTableViewActionCell:cell];
        } else if (indexPath.row == SettingsSectionFAQForumsRowContact) {
            if ([HelpshiftUtils isHelpshiftEnabled]) {
                cell.textLabel.text = NSLocalizedString(@"Contact Us", nil);

                if (indexPath == self.helpshiftLoadingIndexPath) {
                    [self addActivityIndicatorViewToTableViewCell:cell];
                } else if ([HelpshiftUtils unreadNotificationCount] > 0) {
                    UILabel *helpshiftUnreadCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
                    helpshiftUnreadCountLabel.layer.masksToBounds = YES;
                    helpshiftUnreadCountLabel.layer.cornerRadius = 15;
                    helpshiftUnreadCountLabel.textAlignment = NSTextAlignmentCenter;
                    helpshiftUnreadCountLabel.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
                    helpshiftUnreadCountLabel.textColor = [UIColor whiteColor];
                    helpshiftUnreadCountLabel.text = [NSString stringWithFormat:@"%ld", [HelpshiftUtils unreadNotificationCount]];

                    cell.accessoryView = helpshiftUnreadCountLabel;
                } else {
                    cell.accessoryView = nil;
                }
                
                cell.accessoryType = UITableViewCellAccessoryNone;
                [WPStyleGuide configureTableViewActionCell:cell];
            } else {
                cell.textLabel.text = NSLocalizedString(@"WordPress Forums", @"");
                [WPStyleGuide configureTableViewActionCell:cell];
            }
        }
    } else if (indexPath.section == SettingsSectionSettings) {
        cell.textLabel.textAlignment = NSTextAlignmentNatural;

        if (indexPath.row == SettingsSectionSettingsRowVersion) {
            // App Version
            cell.textLabel.text = NSLocalizedString(@"Version", @"");
            cell.detailTextLabel.text = [[NSBundle mainBundle] shortVersionString];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == SettingsSectionSettingsRowExtraDebug) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedString(@"Extra Debug", @"");
            UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
            aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kExtraDebugDefaultsKey];
        } else if (indexPath.row == SettingsSectionSettingsRowTracking) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedString(@"Anonymous Usage Tracking", @"Setting for enabling anonymous usage tracking");
            UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
            aSwitch.on = [[WordPressAppDelegate sharedInstance].analytics isTrackingUsage];
        } else if (indexPath.row == SettingsSectionSettingsRowActivityLogs) {
            cell.textLabel.text = NSLocalizedString(@"Activity Logs", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == SettingsSectionFAQForums) {
        if ([HelpshiftUtils isHelpshiftEnabled]) {
            return NSLocalizedString(@"Visit the Help Center to get answers to common questions, or contact us for more help.", @"Support screen footer text displayed when Helpshift is enabled.");
        } else {
            return NSLocalizedString(@"Visit the Help Center to get answers to common questions, or visit the Forums to ask new ones.", @"Support screen footer text displayed when Helpshift is disabled.");
        }
    } else if (section == SettingsSectionSettings) {
        return NSLocalizedString(@"The Extra Debug feature includes additional information in activity logs, and can help us troubleshoot issues with the app.", @"");
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == SettingsSectionFAQForums) {
        if (indexPath.row == SettingsSectionFAQForumsRowHelpCenter) {
            if ([HelpshiftUtils isHelpshiftEnabled]) {
                [self prepareAndDisplayHelpshiftWindowOfType:kHelpshiftWindowTypeFAQs];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.wordpress.com/support/"] options:nil completionHandler:nil];
            }
        } else if (indexPath.row == SettingsSectionFAQForumsRowContact) {
            if ([HelpshiftUtils isHelpshiftEnabled]) {
                [WPAnalytics track:WPAnalyticsStatSupportOpenedHelpshiftScreen];
                [self prepareAndDisplayHelpshiftWindowOfType:kHelpshiftWindowTypeConversation];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://ios.forums.wordpress.org"] options:nil completionHandler:nil];
            }
        }
    } else if (indexPath.section == SettingsSectionSettings) {
        if (indexPath.row == SettingsSectionSettingsRowActivityLogs) {
            ActivityLogViewController *activityLogViewController = [[ActivityLogViewController alloc] init];
            [self.navigationController pushViewController:activityLogViewController animated:YES];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.helpshiftLoadingIndexPath && indexPath.section == SettingsSectionFAQForums) {
        return NO;
    }

    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.helpshiftLoadingIndexPath && indexPath.section == SettingsSectionFAQForums) {
        return nil;
    }

    return indexPath;
}

#pragma mark - SupportViewController methods

- (void)handleCellSwitchChanged:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;

    if (aSwitch.tag == SettingsSectionSettingsRowExtraDebug) {
        [[NSUserDefaults standardUserDefaults] setBool:aSwitch.on forKey:kExtraDebugDefaultsKey];
        [NSUserDefaults resetStandardUserDefaults];
    } else {
        [[WordPressAppDelegate sharedInstance].analytics setTrackingUsage:aSwitch.on];
    }
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helpshift Notifications

- (void)helpshiftUnreadCountUpdated:(NSNotification *)notification
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:SettingsSectionFAQForums];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
