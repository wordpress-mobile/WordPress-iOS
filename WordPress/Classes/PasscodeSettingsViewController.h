//
//  PasscodeSettingsViewController.h
//  WPiOSPasscodeLock
//
//  Created by Basar Akyelli on 2/14/14.
//  Copyright (c) 2014 Basar Akyelli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PasscodeSettingsViewController : UITableViewController

@property (strong, nonatomic) NSString *passcodeDuration;

-(void) reloadTableView; 

@end
