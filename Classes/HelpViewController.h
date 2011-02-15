//
//  Help.h
//  WordPress
//
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

@interface HelpViewController : UIViewController <MFMailComposeViewControllerDelegate> {
	
	IBOutlet UIButton *faqButton;
	IBOutlet UIButton *forumButton;
	IBOutlet UIButton *emailButton;
	IBOutlet UIBarButtonItem *cancel;
	IBOutlet UINavigationBar *navBar;
}

@property (nonatomic, retain) IBOutlet UIButton *faqButton;
@property (nonatomic, retain) IBOutlet UIButton *forumButton;
@property (nonatomic, retain) IBOutlet UIButton *emailButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancel;
@property (nonatomic, retain) IBOutlet UINavigationBar *navBar;

-(IBAction) cancel: (id)sender;
-(IBAction) visitFAQ: (id)sender;
-(IBAction) visitForum: (id)sender;
-(IBAction) sendEmail: (id)sender;

@end
