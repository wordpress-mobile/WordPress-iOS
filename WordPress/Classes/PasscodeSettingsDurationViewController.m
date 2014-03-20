/*
 * SettingsViewController.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import "PasscodeSettingsDurationViewController.h"
#import <iOSPasscodeLock/PasscodeCoordinator.h>

@interface PasscodeSettingsDurationViewController ()

@end

@implementation PasscodeSettingsDurationViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self setTitle:NSLocalizedString(@"Activation", nil)];
}


#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    [WPStyleGuide configureTableViewCell:cell];

    NSString *cellText = self.durations[indexPath.row];
    
    if([cellText isEqualToString:self.psvc.passcodeDuration])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    cell.textLabel.text = cellText;

    return cell;
}

#pragma mark - UITableViewDelegate methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.psvc.passcodeDuration = self.durations[indexPath.row];
    [[PasscodeCoordinator sharedCoordinator] setPasscodeInactivityDurationInMinutes:self.durationMinutes[indexPath.row]];
    [self.psvc reloadTableView];
    [self.navigationController popViewControllerAnimated:YES];
    
}
@end
