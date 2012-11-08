//
//  CrashReportViewController.m
//  WordPress
//
//  Created by Chris Boyd on 10/22/10.
//  Code is poetry.
//

#import "CrashReportViewController.h"

NSString *CrashFilePath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"crash_data.txt"];
}

@implementation CrashReportViewController

@synthesize crashData;

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
	self.title = NSLocalizedString(@"Crash Detected", @"");
    messageLabel.text = NSLocalizedString(@"It looks like WordPress for iOS crashed the last time you used it. You can help us resolve the issue by sending a crash report.", @"");
    [sendButton setTitle:NSLocalizedString(@"Send Crash Report", @"") forState:UIControlStateNormal];
    [dontSendButton setTitle:NSLocalizedString(@"Don't Send Crash Report", @"") forState:UIControlStateNormal];
}

- (void)viewDidUnload {
    messageLabel = nil;
    sendButton = nil;
    dontSendButton = nil;
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[PLCrashReporter sharedReporter] purgePendingCrashReport];
    [[NSFileManager defaultManager] removeItemAtPath:CrashFilePath() error:nil];
    [super viewWillDisappear:animated];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE) {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPAD || interfaceOrientation == UIDeviceOrientationPortrait)  
        return YES; 
    else  
        return NO; 
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self finish];
}

- (IBAction)yes:(id)sender {
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSError *error;
	crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
	if(crashData != nil) {
		PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error: &error];
		if (report == nil) {
			NSLog(@"Could not parse crash report");
		}
		else if([MFMailComposeViewController canSendMail]) {
			// Create a mail message with the crash report
			NSMutableString *body = [NSMutableString stringWithString:NSLocalizedString(@"Please describe what you were doing when the app crashed: ", @"")];
			MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
			NSString *subject = [NSString stringWithFormat:@"WordPress %@ Crash Report", 
								 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
			[controller setMailComposeDelegate:self];
			[controller setToRecipients:[NSArray arrayWithObject:@"crashreport@automattic.com"]];
			[controller setSubject:subject];
			
			// Add specific exception info if available
			if(report.hasExceptionInfo) {
				[body appendFormat:@"Exception %@ -- %@\n", report.exceptionInfo.exceptionName, report.exceptionInfo.exceptionReason];
			}
			
			// Set the message body and add the log as an attachment
			[controller setMessageBody:body isHTML:NO];
			[controller addAttachmentData:crashData mimeType:@"application/octet-stream" fileName:@"crash.log"];

            if ([[NSFileManager defaultManager] fileExistsAtPath:CrashFilePath()]) {
                NSString *ourCrash = [NSString stringWithContentsOfFile:CrashFilePath() encoding:NSUTF8StringEncoding error:nil];
                [controller addAttachmentData:[ourCrash dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:@"crash_data.txt"];
            }

			if ([[NSFileManager defaultManager] fileExistsAtPath:FileLoggerPath()]) {
                NSString *ourCrash = [NSString stringWithContentsOfFile:FileLoggerPath() encoding:NSUTF8StringEncoding error:nil];
                [controller addAttachmentData:[ourCrash dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:@"wordpress.log"];
            }
			
			// Present and release
			[self presentModalViewController:controller animated:NO];
		}
		else {
			[self finish];
		}
	}
}

- (IBAction)no:(id)sender {
	[self finish];
}

- (IBAction)disable:(id)sender {
	[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"crash_report_dontbug"];
	[self finish];
}

- (void)finish {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CrashReporterIsFinished" object:nil];
}

@end
