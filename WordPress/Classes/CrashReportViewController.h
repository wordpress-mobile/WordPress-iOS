//
//  CrashReportViewController.h
//  WordPress
//
//  Created by Chris Boyd on 10/22/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <CrashReporter/CrashReporter.h>

@interface CrashReportViewController : UIViewController <MFMailComposeViewControllerDelegate>  {
	NSData *crashData;
    IBOutlet UILabel *messageLabel;
    IBOutlet UIButton *sendButton, *dontSendButton;
}

@property (nonatomic, strong) NSData *crashData;

- (IBAction)yes:(id)sender;
- (IBAction)no:(id)sender;
- (IBAction)disable:(id)sender;
- (void)finish;

@end
