//
//  PasscodeSettingsDurationViewController.h
//  WPiOSPasscodeLock
//
//  Created by Basar Akyelli on 2/14/14.
//  Copyright (c) 2014 Basar Akyelli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PasscodeSettingsViewController.h" 

@interface PasscodeSettingsDurationViewController : UITableViewController

@property (strong, nonatomic) PasscodeSettingsViewController *psvc; 
@property (strong, nonatomic) NSArray *durations;
@property (strong, nonatomic) NSArray *durationMinutes;

@end
