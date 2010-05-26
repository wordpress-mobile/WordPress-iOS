//
//  WelcomeViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class	WebSignupViewController;

@interface WelcomeViewController : UIViewController {

	UIButton *haveAccount;
	UIButton *newUser;
	IBOutlet UINavigationController *navigationController;
	IBOutlet UIWindow *window;
	WebSignupViewController *webSignupViewController;
	IBOutlet UILabel *tagline;
	
}

@property (nonatomic, retain) IBOutlet UIButton *haveAccount;

@property (nonatomic, retain) IBOutlet UIButton	*newUser;

@property (nonatomic, retain) UINavigationController *navigationController;

@property (nonatomic, retain) UIWindow *window;

@property (nonatomic, retain) IBOutlet UILabel *tagline;

@property (nonatomic, retain) WebSignupViewController *webSignupViewController;

-(IBAction)loadAccountSignup:(id) sender;

-(IBAction)loadEditBlog:(id) sender;

@end
