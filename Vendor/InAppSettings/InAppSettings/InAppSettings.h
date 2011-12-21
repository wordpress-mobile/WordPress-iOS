//
//  InAppSettingsViewController.h
//  InAppSettings
//
//  Created by David Keegan on 11/21/09.
//  Copyright 2009 InScopeApps{+}. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsTableCell.h"
#import "InAppSettingsReader.h"
#import "InAppSettingsSpecifier.h"
#import "InAppSettingsConstants.h"

#define InAppSettingsNotification InAppSettingsNotificationName

@interface InAppSettings : NSObject {}

+ (void)registerDefaults;
+ (id)sharedManager;

@end

@interface InAppSettingsModalViewController : UIViewController {}

@end

@interface InAppSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
    NSString *file;
    UITableView *settingsTableView;
    UIControl *firstResponder;
    InAppSettingsReader *settingsReader;
}

@property (nonatomic, copy) NSString *file;
@property (nonatomic, retain) UITableView *settingsTableView;
@property (nonatomic, assign) UIControl *firstResponder;
@property (nonatomic, retain) InAppSettingsReader *settingsReader;

// modal view
- (void)dismissModalView;
- (void)addDoneButton;

//keyboard notification
- (void)registerForKeyboardNotifications;
- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

@end

@interface InAppSettingsLightningBolt : UIView {
    BOOL flip;
}

@property (nonatomic, assign) BOOL flip;

@end
