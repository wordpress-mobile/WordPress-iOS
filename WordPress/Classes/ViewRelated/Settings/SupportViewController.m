#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "ActivityLogViewController.h"
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import "WordPressAppDelegate.h"
#import <CocoaLumberjack/DDFileLogger.h>
#import "WPTableViewSectionHeaderFooterView.h"
#import <Helpshift/HelpshiftSupport.h>
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


static NSString *const WPSupportRestorationID = @"WPSupportRestorationID";

static NSString *const kExtraDebugDefaultsKey = @"extra_debug";
int const kActivitySpinnerTag = 101;
int const kHelpshiftWindowTypeFAQs = 1;
int const kHelpshiftWindowTypeConversation = 2;

@interface SupportViewController () <UIViewControllerRestoration>
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

+ (void)showFromTabBar
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:supportViewController];
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

    if ([self.navigationController.viewControllers count] == 1) {
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

- (void)showLoadingSpinner
{
    UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    loading.tag = kActivitySpinnerTag;
    loading.center = self.view.center;
    loading.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:loading];
    [loading startAnimating];
}

- (void)hideLoadingSpinner
{
    [[self.view viewWithTag:kActivitySpinnerTag] removeFromSuperview];
}

- (void)prepareAndDisplayHelpshiftWindowOfType:(int)helpshiftType
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:UserDefaultsHelpshiftWasUsed];
    
    // Notifications
    [[PushNotificationsManager sharedInstance] registerForRemoteNotifications];
    [[InteractiveNotificationsHandler sharedInstance] registerForUserNotifications];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    NSString *isWPCom = (defaultAccount != nil) ? @"Yes" : @"No";
    NSMutableDictionary *metaData = [NSMutableDictionary dictionaryWithDictionary:@{ @"isWPCom" : isWPCom }];

    NSArray *allBlogs = [blogService blogsForAllAccounts];
    for (int i = 0; i < allBlogs.count; i++) {
        Blog *blog = allBlogs[i];

        NSDictionary *blogData = @{[NSString stringWithFormat:@"blog-%i", i+1]: [blog logDescription]};

        [metaData addEntriesFromDictionary:blogData];
    }

    if (defaultAccount) {
        [self showLoadingSpinner];

        [metaData addEntriesFromDictionary:@{@"WPCom Username": defaultAccount.username}];

        [defaultAccount.wordPressComRestApi GET:@"v1.1/me"
                         parameters:nil
                            success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                [self hideLoadingSpinner];

                                NSString *displayName = ([responseObject valueForKey:@"display_name"]) ? [responseObject objectForKey:@"display_name"] : nil;
                                NSString *emailAddress = ([responseObject valueForKey:@"email"]) ? [responseObject objectForKey:@"email"] : nil;
                                NSString *userID = ([responseObject valueForKey:@"ID"]) ? [[responseObject objectForKey:@"ID"] stringValue] : nil;

                                [HelpshiftSupport setUserIdentifier:userID];
                                [self displayHelpshiftWindowOfType:helpshiftType withUsername:displayName andEmail:emailAddress andMetadata:metaData];
                            } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                                [self hideLoadingSpinner];
                                [self displayHelpshiftWindowOfType:helpshiftType withUsername:defaultAccount.username andEmail:nil andMetadata:metaData];
                            }];
    } else {
        [self displayHelpshiftWindowOfType:helpshiftType withUsername:nil andEmail:nil andMetadata:metaData];
    }
}

- (void)displayHelpshiftWindowOfType:(int)helpshiftType
                        withUsername:(NSString*)username
                            andEmail:(NSString*)email
                         andMetadata:(NSDictionary*)metaData
{
    [HelpshiftCore setName:username andEmail:email];

    if (helpshiftType == kHelpshiftWindowTypeFAQs) {
        [HelpshiftSupport showFAQs:self withOptions:@{HelpshiftSupportCustomMetadataKey: metaData}];
    } else if (helpshiftType == kHelpshiftWindowTypeConversation) {
        [HelpshiftSupport showConversation:self withOptions:@{HelpshiftSupportCustomMetadataKey: metaData}];
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

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    [WPStyleGuide configureTableViewCell:cell];

    if (indexPath.section == SettingsSectionFAQForums) {
        if (indexPath.row == SettingsSectionFAQForumsRowHelpCenter) {
            cell.textLabel.text = NSLocalizedString(@"WordPress Help Center", @"");
            [WPStyleGuide configureTableViewActionCell:cell];
        } else if (indexPath.row == SettingsSectionFAQForumsRowContact) {
            if ([HelpshiftUtils isHelpshiftEnabled]) {
                cell.textLabel.text = NSLocalizedString(@"Contact Us", nil);

                if ([HelpshiftUtils unreadNotificationCount] > 0) {
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
        cell.textLabel.textAlignment = NSTextAlignmentLeft;

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
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.wordpress.com/support/"]];
            }
        } else if (indexPath.row == SettingsSectionFAQForumsRowContact) {
            if ([HelpshiftUtils isHelpshiftEnabled]) {
                [WPAnalytics track:WPAnalyticsStatSupportOpenedHelpshiftScreen];
                [self prepareAndDisplayHelpshiftWindowOfType:kHelpshiftWindowTypeConversation];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://ios.forums.wordpress.org"]];
            }
        }
    } else if (indexPath.section == SettingsSectionSettings) {
        if (indexPath.row == SettingsSectionSettingsRowActivityLogs) {
            ActivityLogViewController *activityLogViewController = [[ActivityLogViewController alloc] init];
            [self.navigationController pushViewController:activityLogViewController animated:YES];
        }
    }
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
