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
#import <iOSPasscodeLock/PasscodeManager.h> 

@interface PasscodeSettingsViewController ()

@property (strong, nonatomic) NSArray *durations;
@property (strong, nonatomic) NSArray *durationMinutes;
@property (assign) BOOL passcodeEnabled;
@property (assign) NSInteger selectedInactivtyDurationIndex;
@end


@implementation PasscodeSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:NSLocalizedString(@"Passcode Lock", nil)];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self resetDurations];
}

#pragma mark - UITableViewDataSource methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.passcodeEnabled)
    {
        return 2;
    }
    else
    {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return 1;
    }
    else
    {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    [WPStyleGuide configureTableViewCell:cell];
    if(indexPath.section== 0) //Switch
    {
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchview.tag = 1;
        [switchview addTarget:self action:@selector(updateSwitch:) forControlEvents:UIControlEventTouchUpInside];
        [switchview setOn:self.passcodeEnabled];
        cell.accessoryView = switchview;
        cell.textLabel.text = NSLocalizedString(@"Passcode Lock",nil);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if(indexPath.section == 1 && indexPath.row == 0)//Duration
    {
        cell.textLabel.text = NSLocalizedString(@"Activate",nil);
        cell.detailTextLabel.text = self.passcodeDuration;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    }
    else if(indexPath.section == 1 && indexPath.row == 1) //Change passcode
    {
        cell.textLabel.text = NSLocalizedString(@"Change Passcode",nil);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    }
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.passcodeEnabled)
    {
        if(indexPath.section == 1 && indexPath.row == 0)
        {
            PasscodeSettingsDurationViewController *psdvc = [[PasscodeSettingsDurationViewController alloc]initWithStyle:UITableViewStyleGrouped];
            psdvc.durations = self.durations;
            psdvc.durationMinutes = self.durationMinutes;
            psdvc.psvc = self; 
            
            [self.navigationController pushViewController:psdvc animated:YES];
        }
        else if(indexPath.section == 1 && indexPath.row == 1)
        {
            [[PasscodeManager sharedManager] changePasscodeWithCompletion:nil];
        }
    }
}

#pragma mark - Helper methods

-(void)updateSwitch:(UISwitch *)switchView
{
    __weak PasscodeSettingsViewController *selfRef = self;

    if(switchView.isOn){
        
        [[PasscodeManager sharedManager] setupNewPasscodeWithCompletion:^(BOOL success) {
            if(success){
                selfRef.passcodeEnabled = YES;
                [selfRef.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                [self reloadTableView];

            }
            else{
                selfRef.passcodeEnabled = NO;
                [switchView setOn:NO];
                [self reloadTableView];

            }
        }];
    }
    else{
        [[PasscodeManager sharedManager] disablePasscodeProtectionWithCompletion:^(BOOL success) {
            if(success){
                self.passcodeEnabled = NO;
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
                [self reloadTableView];

            }
            else{
                [switchView setOn:YES];
                self.passcodeEnabled = YES;
                [self reloadTableView];

            }
        }];
    }
}

-(void)reloadTableView
{
    [self resetDurations];
    [self.tableView reloadData];
}

- (void)resetDurations
{
    self.durations = @[NSLocalizedString(@"Immediately",nil),
                       NSLocalizedString(@"After 1 minute",nil),
                       NSLocalizedString(@"After 15 minutes",nil)];
    
    self.durationMinutes = @[@0, @1, @15];
    
    if([[PasscodeManager sharedManager] isPasscodeProtectionOn])
    {
        self.passcodeEnabled = YES;
        
        NSNumber *inactivityDuration = [[PasscodeManager sharedManager] getPasscodeInactivityDurationInMinutes];
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
