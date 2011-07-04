//
//  AboutViewController.h
//  WordPress
//-
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

@interface AboutViewController : UIViewController <MFMailComposeViewControllerDelegate> {
	
	IBOutlet UIButton *termsOfServiceButton;
	IBOutlet UIButton *privacyPolicyButton;
	IBOutlet UIButton *websiteButton;
	IBOutlet UIBarButtonItem *cancel;
	IBOutlet UINavigationBar *navBar;
	
	BOOL isBlogSetup;
}

@property (nonatomic, retain) IBOutlet UIButton *termsOfServiceButton;
@property (nonatomic, retain) IBOutlet UIButton *privacyPolicyButton;
@property (nonatomic, retain) IBOutlet UIButton *websiteButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancel;
@property (nonatomic, retain) IBOutlet UINavigationBar *navBar;
@property (nonatomic, retain) IBOutlet UILabel *appTitleText;
@property (nonatomic, retain) IBOutlet UILabel *appDescriptionText;
@property (nonatomic, assign) BOOL isBlogSetup;

-(IBAction) cancel: (id)sender;
-(IBAction) viewTermsOfService: (id)sender;
-(IBAction) viewPrivacyPolicy: (id)sender;
-(IBAction) viewWebsite: (id)sender;

@end
