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

static NSString *const UserDefaultsFeedbackEnabled = @"wp_feedback_enabled";
static NSString *const kExtraDebugDefaultsKey = @"extra_debug";
int const kActivitySpinnerTag = 101;
int const kHelpshiftWindowTypeFAQs = 1;
int const kHelpshiftWindowTypeConversation = 2;

static NSString *const FeedbackCheckUrl = @"https://api.wordpress.org/iphoneapp/feedback-check/1.0/";

@interface SupportViewController () <UIViewControllerRestoration>

@property (nonatomic, assign) BOOL feedbackEnabled;

@end

@implementation SupportViewController

typedef NS_ENUM(NSInteger, SettingsViewControllerSections)
{
    SettingsSectionFAQForums,
    SettingsSectionFeedback,
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

typedef NS_ENUM(NSInteger, SettingsSectionFeedbackRows)
{
    SettingsSectionFeedbackRowEmailSupport,
    SettingsSectionFeedbackRowCount
};

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

+ (void)checkIfFeedbackShouldBeEnabled
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{UserDefaultsFeedbackEnabled: @YES}];
    NSURL *url = [NSURL URLWithString:FeedbackCheckUrl];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];

    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [[AFJSONResponseSerializer alloc] init];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        DDLogVerbose(@"Feedback response received: %@", responseObject);
        NSNumber *feedbackEnabled = responseObject[@"feedback-enabled"];
        if (feedbackEnabled == nil) {
            feedbackEnabled = @YES;
        }

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:feedbackEnabled.boolValue forKey:UserDefaultsFeedbackEnabled];
        [defaults synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error received while checking feedback enabled status: %@", error);

        // Lets be optimistic and turn on feedback by default if this call doesn't work
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:UserDefaultsFeedbackEnabled];
        [defaults synchronize];
    }];

    [operation start];
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

        _feedbackEnabled = YES;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setRowHeight:WPTableViewDefaultRowHeight];
    
    if (UIDevice.isPad) {
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:WPTableHeaderPadFrame];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:WPTableFooterPadFrame];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.feedbackEnabled = [defaults boolForKey:UserDefaultsFeedbackEnabled];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];

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

        [defaultAccount.restApi GET:@"v1.1/me"
                         parameters:nil
                            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                [self hideLoadingSpinner];

                                NSString *displayName = ([responseObject valueForKey:@"display_name"]) ? [responseObject objectForKey:@"display_name"] : nil;
                                NSString *emailAddress = ([responseObject valueForKey:@"email"]) ? [responseObject objectForKey:@"email"] : nil;
                                NSString *userID = ([responseObject valueForKey:@"ID"]) ? [[responseObject objectForKey:@"ID"] stringValue] : nil;

                                [HelpshiftSupport setUserIdentifier:userID];
                                [self displayHelpshiftWindowOfType:helpshiftType withUsername:displayName andEmail:emailAddress andMetadata:metaData];
                            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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

    if (section == SettingsSectionFeedback) {
        return self.feedbackEnabled ? SettingsSectionFeedbackRowCount : 0;
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
    } else if (indexPath.section == SettingsSectionFeedback) {
        cell.textLabel.text = NSLocalizedString(@"E-mail Support", @"");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [WPStyleGuide configureTableViewActionCell:cell];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Make sure no Section Header is rendered
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Make sure no Section Header is rendered
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *title = [self titleForFooterInSection:section];
    if (!title) {
        return nil;
    }
    
    WPTableViewSectionHeaderFooterView *footer = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleFooter];
    footer.title = title;
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *title = [self titleForFooterInSection:section];
    if (!title) {
        // Fix: Prevents extra spacing when dealing with empty footers
        return CGFLOAT_MIN;
    }
    
    return [WPTableViewSectionHeaderFooterView heightForFooter:title width:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)titleForFooterInSection:(NSInteger)section
{
    if (section == SettingsSectionFAQForums) {
        return NSLocalizedString(@"Visit the Help Center to get answers to common questions, or visit the Forums to ask new ones.", @"");
    } else if (section == SettingsSectionSettings) {
        return NSLocalizedString(@"The Extra Debug feature includes additional information in activity logs, and can help us troubleshoot issues with the app.", @"");
    }
    return nil;
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
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.wordpress.org/support/"]];
            }
        } else if (indexPath.row == SettingsSectionFAQForumsRowContact) {
            if ([HelpshiftUtils isHelpshiftEnabled]) {
                [WPAnalytics track:WPAnalyticsStatSupportOpenedHelpshiftScreen];
                [self prepareAndDisplayHelpshiftWindowOfType:kHelpshiftWindowTypeConversation];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://ios.forums.wordpress.org"]];
            }
        }
    } else if (indexPath.section == SettingsSectionFeedback) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailComposeViewController = [self feedbackMailViewController];
            [self presentViewController:mailComposeViewController animated:YES completion:nil];
        } else {
            [WPError showAlertWithTitle:NSLocalizedString(@"Feedback", nil) message:NSLocalizedString(@"Your device is not configured to send e-mail.", nil)];
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

- (MFMailComposeViewController *)feedbackMailViewController
{
    NSString *appVersion = [[NSBundle mainBundle] detailedVersionNumber];
    NSString *device = [UIDeviceHardware platformString];
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    NSString *iosVersion = [[UIDevice currentDevice] systemVersion];

    NSMutableString *messageBody = [NSMutableString string];
    [messageBody appendFormat:@"\n\n==========\n%@\n\n", NSLocalizedString(@"Please leave your comments above this line.", @"")];
    [messageBody appendFormat:@"Device: %@\n", device];
    [messageBody appendFormat:@"App Version: %@\n", appVersion];
    [messageBody appendFormat:@"Locale: %@\n", locale];
    [messageBody appendFormat:@"OS Version: %@\n", iosVersion];

    WordPressAppDelegate *delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    DDFileLogger *fileLogger = delegate.logger.fileLogger;
    NSArray *logFiles = fileLogger.logFileManager.sortedLogFileInfos;

    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;

    [mailComposeViewController setMessageBody:messageBody isHTML:NO];
    [mailComposeViewController setSubject:@"WordPress for iOS Help Request"];
    [mailComposeViewController setToRecipients:@[@"mobile-support@automattic.com"]];

    if (logFiles.count > 0) {
        DDLogFileInfo *logFileInfo = (DDLogFileInfo *)logFiles[0];
        NSData *logData = [NSData dataWithContentsOfFile:logFileInfo.filePath];

        [mailComposeViewController addAttachmentData:logData mimeType:@"text/plain" fileName:@"current_log.txt"];
    }

    mailComposeViewController.modalPresentationCapturesStatusBarAppearance = NO;

    return mailComposeViewController;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultFailed:
            break;
        case MFMailComposeResultSaved:
        case MFMailComposeResultSent:
            break;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helpshift Notifications

- (void)helpshiftUnreadCountUpdated:(NSNotification *)notification
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:SettingsSectionFAQForums];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
