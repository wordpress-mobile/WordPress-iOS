/*
 * SettingsViewController.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import "PasscodeSettingsViewController.h"
#import "PasscodeSettingsDurationViewController.h"
#import <iOSPasscodeLock/PasscodeCoordinator.h>

@interface PasscodeSettingsViewController ()

@property (strong, nonatomic) NSArray *durations;
@property (strong, nonatomic) NSArray *durationMinutes;
@property (assign) BOOL passcodeEnabled;
@property (assign) NSInteger selectedInactivtyDurationIndex;
@end

typedef enum {
    PasscodeSettingsSectionEnabled = 0,
    PasscodeSettingsSectionConfiguration,
    PasscodeSettingsSectionCount
} PasscodeSettingsSection;

@implementation PasscodeSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:NSLocalizedString(@"Passcode Lock", nil)];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self resetDurations];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.passcodeEnabled ? PasscodeSettingsSectionCount : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case PasscodeSettingsSectionEnabled:
            return 1;
        case PasscodeSettingsSectionConfiguration:
            return 2;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    [WPStyleGuide configureTableViewCell:cell];
    if(indexPath.section == PasscodeSettingsSectionEnabled) {
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchview.tag = 1;
        [switchview addTarget:self action:@selector(updateSwitch:) forControlEvents:UIControlEventTouchUpInside];
        [switchview setOn:self.passcodeEnabled];
        cell.accessoryView = switchview;
        cell.textLabel.text = NSLocalizedString(@"Passcode Lock",nil);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if(indexPath.section == PasscodeSettingsSectionConfiguration && indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Activate",nil);
        cell.detailTextLabel.text = self.passcodeDuration;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if(indexPath.section == PasscodeSettingsSectionConfiguration && indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Change Passcode",nil);
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.passcodeEnabled) {
        if(indexPath.section == PasscodeSettingsSectionConfiguration && indexPath.row == 0) {
            PasscodeSettingsDurationViewController *psdvc = [[PasscodeSettingsDurationViewController alloc]initWithStyle:UITableViewStyleGrouped];
            psdvc.durations = self.durations;
            psdvc.durationMinutes = self.durationMinutes;
            psdvc.psvc = self;
            [self.navigationController pushViewController:psdvc animated:YES];
        }
        else if(indexPath.section == PasscodeSettingsSectionConfiguration && indexPath.row == 1) {
            [[PasscodeCoordinator sharedCoordinator] changePasscodeWithCompletion:^(BOOL success) {
                [self reloadTableView];
            }];
        }
    }
    [self reloadTableView];
}

#pragma mark - Helper methods

- (void)updateSwitch:(UISwitch *)switchView {
    __weak PasscodeSettingsViewController *selfRef = self;

    if(switchView.isOn) {
        [[PasscodeCoordinator sharedCoordinator] setupNewPasscodeWithCompletion:^(BOOL success) {
            if(success) {
                selfRef.passcodeEnabled = YES;
                [selfRef.tableView insertSections:[NSIndexSet indexSetWithIndex:PasscodeSettingsSectionConfiguration] withRowAnimation:UITableViewRowAnimationFade];
                [self reloadTableView];

            }
            else {
                selfRef.passcodeEnabled = NO;
                [switchView setOn:NO];
                [self reloadTableView];
            }
        }];
    }
    else {
        [[PasscodeCoordinator sharedCoordinator] disablePasscodeProtectionWithCompletion:^(BOOL success) {
            if(success) {
                self.passcodeEnabled = NO;
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:PasscodeSettingsSectionConfiguration] withRowAnimation:UITableViewRowAnimationNone];
                [self reloadTableView];

            }
            else {
                [switchView setOn:YES];
                self.passcodeEnabled = YES;
                [self reloadTableView];

            }
        }];
    }
    [self reloadTableView];
}

- (void)reloadTableView {
    [self resetDurations];
    [self.tableView reloadData];
}

- (void)resetDurations {
    self.durations = @[NSLocalizedString(@"Immediately",nil),
                       NSLocalizedString(@"After 1 minute",nil),
                       NSLocalizedString(@"After 15 minutes",nil)];
    
    self.durationMinutes = @[@0, @1, @15];
    
    if([[PasscodeCoordinator sharedCoordinator] isPasscodeProtectionOn])
    {
        self.passcodeEnabled = YES;
        
        NSNumber *inactivityDuration = [[PasscodeCoordinator sharedCoordinator] getPasscodeInactivityDurationInMinutes];
        if(inactivityDuration)
        {
            self.selectedInactivtyDurationIndex = [self.durationMinutes indexOfObject:inactivityDuration];
            self.passcodeDuration = self.durations[self.selectedInactivtyDurationIndex];
        }
    }
    else{
        self.passcodeEnabled = NO;
        self.passcodeDuration = self.durations[0];
    }
}

@end
