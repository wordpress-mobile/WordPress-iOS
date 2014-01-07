//
//  SupportViewController.m
//  WordPress
//
//  Created by Aaron Douglas on 5/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "ActivityLogViewController.h"
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import "WordPressAppDelegate.h"
#import <DDFileLogger.h>

static NSString *const UserDefaultsFeedbackEnabled = @"wp_feedback_enabled";
static NSString *const FeedbackCheckUrl = @"http://api.wordpress.org/iphoneapp/feedback-check/1.0/";

@interface SupportViewController ()

@property (nonatomic, assign) BOOL feedbackEnabled;

@end

@implementation SupportViewController

typedef NS_ENUM(NSInteger, SettingsViewControllerSections)
{
    SettingsSectionFAQForums,
    SettingsSectionFeedback,
    SettingsSectionActivityLog,
};

+ (void)checkIfFeedbackShouldBeEnabled {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{UserDefaultsFeedbackEnabled: @YES}];
    NSURL *url = [NSURL URLWithString:FeedbackCheckUrl];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DDLogVerbose(@"Feedback response received: %@", JSON);
        NSNumber *feedbackEnabled = JSON[@"feedback-enabled"];
        if (feedbackEnabled == nil) {
            feedbackEnabled = @YES;
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:feedbackEnabled.boolValue forKey:UserDefaultsFeedbackEnabled];
        [defaults synchronize];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DDLogError(@"Error received while checking feedback enabled status: %@", error);
        
        // Lets be optimistic and turn on feedback by default if this call doesn't work
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:UserDefaultsFeedbackEnabled];
        [defaults synchronize];
    }];
    
    [operation start];
}

+ (void)showFromTabBar {
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:supportViewController];
    aNavigationController.navigationBar.translucent = NO;
    
    if (IS_IPAD) {
        aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    UIViewController *presenter = [[WordPressAppDelegate sharedWordPressApplicationDelegate] tabBarController];
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
        _feedbackEnabled = YES;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.feedbackEnabled = [defaults boolForKey:UserDefaultsFeedbackEnabled];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    if([self.navigationController.viewControllers count] == 1) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SettingsSectionFAQForums || section == SettingsSectionActivityLog)
        return 2;
    
    if (section == SettingsSectionFeedback) {
        return self.feedbackEnabled ? 1 : 0;
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SupportViewStandardCell";
    static NSString *CellIdentifierExtraDebug = @"SupportViewExtraDebugCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil && indexPath.section == SettingsSectionActivityLog && indexPath.row == 0) {
        // Settings / Extra Debug
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierExtraDebug];
        UISwitch *extraDebugSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [extraDebugSwitch addTarget:self action:@selector(handleExtraDebugChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = extraDebugSwitch;
    } else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    [WPStyleGuide configureTableViewCell:cell];

    if (indexPath.section == SettingsSectionFAQForums && indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"WordPress Help Center", @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == SettingsSectionFAQForums && indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"WordPress Forums", @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == SettingsSectionFeedback) {
        cell.textLabel.text = NSLocalizedString(@"E-mail Support", @"");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [WPStyleGuide configureTableViewActionCell:cell];
    } else if (indexPath.section == SettingsSectionActivityLog) {
        cell.textLabel.textAlignment = NSTextAlignmentLeft;

        if (indexPath.row == 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedString(@"Extra Debug", @"");
            UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
            aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Activity Logs", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }


}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == SettingsSectionFAQForums) {
        return NSLocalizedString(@"Visit the Help Center to get answers to common questions, or visit the Forums to ask new ones.", @"");
    } else if (section == SettingsSectionActivityLog) {
        return NSLocalizedString(@"Turning on Extra Debug will log additional items to assist with us helping you with resolving a problem.", @"");
    }

    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == SettingsSectionFAQForums && indexPath.row == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ios.wordpress.org/faq"]];
    } else if (indexPath.section == SettingsSectionFAQForums && indexPath.row == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ios.forums.wordpress.org"]];
    } else if (indexPath.section == SettingsSectionFeedback) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailComposeViewController = [self feedbackMailViewController];
            [self presentViewController:mailComposeViewController animated:YES completion:nil];
        } else {
            [WPError showAlertWithTitle:NSLocalizedString(@"Feedback", nil) message:NSLocalizedString(@"Your device is not configured to send e-mail.", nil)];
        }
    } else if (indexPath.section == SettingsSectionActivityLog && indexPath.row == 1) {
        ActivityLogViewController *activityLogViewController = [[ActivityLogViewController alloc] init];
        [self.navigationController pushViewController:activityLogViewController animated:YES];
    }
}

#pragma mark - SupportViewController methods

- (void)handleExtraDebugChanged:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:aSwitch.on forKey:@"extra_debug"];
    [NSUserDefaults resetStandardUserDefaults];
}

- (MFMailComposeViewController *)feedbackMailViewController
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];;
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
    DDFileLogger *fileLogger = delegate.fileLogger;
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

- (void)dismiss {
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

@end
