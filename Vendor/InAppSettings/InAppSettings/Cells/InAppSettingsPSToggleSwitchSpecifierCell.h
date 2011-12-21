//
//  PSToggleSwitchSpecifier.h
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/21/09.
//  Copyright 2009 InScopeApps{+}. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsTableCell.h"

@interface InAppSettingsPSToggleSwitchSpecifierCell : InAppSettingsTableCell {
    UISwitch *valueSwitch;
}

@property (nonatomic, retain) UISwitch *valueSwitch;

- (BOOL)getBool;
- (void)setBool:(BOOL)newValue;
- (void)switchAction;

@end
