//
//  RootViewController.h
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/21/09.
//  Copyright InScopeApps{+} 2009. All rights reserved.
//

@interface RootViewController : UIViewController {
    UILabel *userSettingsLabel1;
    UILabel *userSettingsLabel2;
    UILabel *userSettingsLabel3;
    UILabel *userSettingsLabel4;
}

@property (nonatomic, retain) IBOutlet UILabel *userSettingsLabel1;
@property (nonatomic, retain) IBOutlet UILabel *userSettingsLabel2;
@property (nonatomic, retain) IBOutlet UILabel *userSettingsLabel3;
@property (nonatomic, retain) IBOutlet UILabel *userSettingsLabel4;

- (IBAction)showSettings;
- (IBAction)presentSettings;

@end
