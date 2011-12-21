//
//  InAppSettingsConstants.h
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/21/09.
//  Copyright 2009 InScopeApps{+}. All rights reserved.
//

#import <Availability.h>

#define InAppSettingsRootFile @"Root"
#define InAppSettingsProjectName @"InAppSettings"
#define InAppSettingsNotificationName @"InAppSettingsNotification"

#define InAppSettingsOffsetY 2.0f
#define InAppSettingsFontSize 17.0f
#define InAppSettingsCellPadding 9.0f
#define InAppSettingsTablePadding 10.0f
#define InAppSettingsPowerFooterHeight 32.0f
#define InAppSettingsLightingBoltSize 16.0f
#define InAppSettingsKeyboardAnimation 0.3f
#define InAppSettingsCellTextFieldMinX 115.0f
#define InAppSettingsCellToggleSwitchWidth 94.0f
#define InAppSettingsCellDisclosureIndicatorWidth 10.0f
#define InAppSettingsTotalCellPadding InAppSettingsCellPadding*2
#define InAppSettingsTotalTablePadding InAppSettingsTablePadding*2
#define InAppSettingsScreenWidth 320
#define InAppSettingsScreenHeight 480
#define InAppSettingsCellTitleMaxWidth InAppSettingsScreenWidth-(InAppSettingsTotalTablePadding+InAppSettingsTotalCellPadding)
#define InAppSettingsFooterFont [UIFont systemFontOfSize:14.0f]
#define InAppSettingsBoldFont [UIFont boldSystemFontOfSize:InAppSettingsFontSize]
#define InAppSettingsNormalFont [UIFont systemFontOfSize:InAppSettingsFontSize]
#define InAppSettingsBlue [UIColor colorWithRed:0.22f green:0.33f blue:0.53f alpha:1.0f];
#define InAppSettingsFooterBlue [UIColor colorWithRed:0.36f green:0.39f blue:0.45f alpha:1.0f]

#define InAppSettingsOpenUrl(url) [[UIApplication sharedApplication] openURL:url];
#define InAppSettingsBundlePath [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"]
#define InAppSettingsFullPlistPath(file) \
    [InAppSettingsBundlePath stringByAppendingPathComponent:[file stringByAppendingPathExtension:@"plist"]]
#define InAppSettingsLocalize(stringKey, tableKey) \
    [[NSBundle bundleWithPath:InAppSettingsBundlePath] localizedStringForKey:stringKey value:stringKey table:tableKey]

// settings strings
#define InAppSettingsStringsTable @"StringsTable"
#define InAppSettingsPreferenceSpecifiers @"PreferenceSpecifiers"

#define InAppSettingsPSGroupSpecifier @"PSGroupSpecifier"
#define InAppSettingsPSSliderSpecifier @"PSSliderSpecifier"
#define InAppSettingsPSChildPaneSpecifier @"PSChildPaneSpecifier"
#define InAppSettingsPSTextFieldSpecifier @"PSTextFieldSpecifier"
#define InAppSettingsPSTitleValueSpecifier @"PSTitleValueSpecifier"
#define InAppSettingsPSMultiValueSpecifier @"PSMultiValueSpecifier"
#define InAppSettingsPSToggleSwitchSpecifier @"PSToggleSwitchSpecifier"

#define InAppSettingsSpecifierKey @"Key"
#define InAppSettingsSpecifierType @"Type"
#define InAppSettingsSpecifierFile @"File"
#define InAppSettingsSpecifierTitle @"Title"
#define InAppSettingsSpecifierTitles @"Titles"
#define InAppSettingsSpecifierValues @"Values"
#define InAppSettingsSpecifierDefaultValue @"DefaultValue"
#define InAppSettingsSpecifierMinimumValue @"MinimumValue"
#define InAppSettingsSpecifierMaximumValue @"MaximumValue"
#define InAppSettingsSpecifierInAppURL @"InAppURL"
#define InAppSettingsSpecifierInAppTitle @"InAppTitle"

// test what cell init code should be used
#define InAppSettingsUseNewCells __IPHONE_3_0 && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_0

// test if the new keyboard calls should be used
#define InAppSettingsUseNewKeyboard __IPHONE_3_2 && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2

// test if the value of PSMultiValueSpecifier should be on the right or left if there is no title
#define InAppSettingsUseNewMultiValueLocation [[[UIDevice currentDevice] systemVersion] doubleValue] >= 4.0

// if you dont want to display the footer set this to NO
#define InAppSettingsDisplayPowered YES
