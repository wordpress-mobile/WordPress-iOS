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
#import "WordPressAppDelegate.h"

@interface CrashReportViewController : UIViewController <MFMailComposeViewControllerDelegate>  {
	NSData *crashData;
}

@property (nonatomic, retain) NSData *crashData;

- (IBAction)yes:(id)sender;
- (IBAction)no:(id)sender;
- (IBAction)disable:(id)sender;
- (void)finish;

@end
