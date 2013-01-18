//
//  Help.h
//  WordPress
//
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "WordPressAppDelegate.h"

@interface HelpViewController : UIViewController <MFMailComposeViewControllerDelegate> {
	
	IBOutlet UIButton *faqButton;
	IBOutlet UIButton *forumButton;
	IBOutlet UINavigationBar *navBar;
	
	BOOL isBlogSetup;
}

@property (nonatomic, strong) IBOutlet UIButton *faqButton;
@property (nonatomic, strong) IBOutlet UIButton *forumButton;
@property (nonatomic, strong) IBOutlet UILabel *helpText;
@property (nonatomic, assign) BOOL isBlogSetup;

-(IBAction)cancel: (id)sender;
-(IBAction)helpButtonTap: (id)sender;

@end
