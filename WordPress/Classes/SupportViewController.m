//
//  SupportViewController.m
//  WordPress
//
//  Created by Aaron Douglas on 5/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "SupportViewController.h"

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
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == SettingsSectionActivityLog) {
        cell.textLabel.text = NSLocalizedString(@"Activity Log", @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == SettingsSectionFAQ) {
        return NSLocalizedString(@"Please visit the FAQ to get answers to common questions. If you're still having trouble, please post in the forums.", @"");
    }

    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case SettingsSectionFAQ:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ios.wordpress.org/faq"]];
            break;
        case SettingsSectionForums:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ios.forums.wordpress.org"]];
            break;
    }
}
@end
