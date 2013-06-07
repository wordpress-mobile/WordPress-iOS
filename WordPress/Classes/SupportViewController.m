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

@interface SupportViewController ()

@end

@implementation SupportViewController

typedef NS_ENUM(NSInteger, SettingsViewControllerSections)
{
    SettingsSectionFAQ,
    SettingsSectionForums,
    SettingsSectionFeedback,
    SettingsSectionActivityLog,
};


- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Support", @"");
    }

    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundView = nil;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SettingsSectionActivityLog)
        return 2;

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
    cell.textLabel.textAlignment = NSTextAlignmentCenter;

    if (indexPath.section == SettingsSectionFAQ) {
        cell.textLabel.text = NSLocalizedString(@"Visit the FAQ", @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == SettingsSectionForums) {
        cell.textLabel.text = NSLocalizedString(@"Visit the Forums", @"");
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.section == SettingsSectionFeedback) {
        cell.textLabel.text = NSLocalizedString(@"Send Us Feedback", @"");
        cell.accessoryType = UITableViewCellAccessoryNone;
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
    if (section == SettingsSectionFAQ) {
        return NSLocalizedString(@"Please visit the FAQ to get answers to common questions. If you're still having trouble, please post in the forums or send us feedback.", @"");
    } else if (section == SettingsSectionActivityLog) {
        return NSLocalizedString(@"Turning on Extra Debug will log additional items to assist with us helping you with resolving a problem.", @"");
    }

    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == SettingsSectionFAQ) {
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:[NSURL URLWithString:@"http://ios.wordpress.org/faq"]];
        [self.navigationController pushViewController:webViewController animated:YES];
    } else if (indexPath.section == SettingsSectionForums) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ios.forums.wordpress.org"]];
    } else if (indexPath.section == SettingsSectionFeedback) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailComposeViewController = [self feedbackMailViewController];
            [self presentViewController:mailComposeViewController animated:YES completion:nil];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Feedback", @"")
                                                                message:NSLocalizedString(@"Your device is not configured to send e-mail.", @"")
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    } else if (indexPath.section == SettingsSectionActivityLog && indexPath.row == 0) {
        abort();
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
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;

    [mailComposeViewController setSubject:@"WordPress for iOS Help Request"];
    [mailComposeViewController setToRecipients:@[@"support@wordpress.com"]];

    return mailComposeViewController;
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
