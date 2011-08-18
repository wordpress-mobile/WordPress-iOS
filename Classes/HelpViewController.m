//
//  Help.m
//  WordPress
//
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "HelpViewController.h"


@implementation HelpViewController

@synthesize helpText, faqButton, forumButton, cancel, navBar, isBlogSetup;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
	if (![MFMailComposeViewController canSendMail])
		[emailButton setHidden:YES]; 
	
	if (DeviceIsPad())
		self.navigationItem.title = NSLocalizedString(@"Help", @"");
    
    self.helpText.text = NSLocalizedString(@"Please visit the FAQ to get answers to common questions. If you're still having trouble, post in the forums or email us.", @"");
    [self.faqButton setTitle:NSLocalizedString(@"Read the FAQ", @"") forState:UIControlStateNormal];
    [self.forumButton setTitle:NSLocalizedString(@"Visit the Forums", @"") forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	if (DeviceIsPad() && isBlogSetup)
			[navBar setHidden:YES];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (DeviceIsPad())
		return YES;
	
	return NO;
}


-(void) cancel: (id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

-(void) visitFAQ: (id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://ios.wordpress.org/faq"]];
	//[self dismissModalViewControllerAnimated:YES];
}

-(void) visitForum: (id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://ios.forums.wordpress.org"]];
	//[self dismissModalViewControllerAnimated:YES];
}

-(void) sendEmail: (id)sender {
	MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
	controller.mailComposeDelegate = self;
	NSArray *recipient = [[NSArray alloc] initWithObjects:@"support@wordpress.com", nil];
	[controller setToRecipients: recipient];
	[recipient release];
	[controller setSubject:@"WordPress for iOS Help Request"];
	[controller setMessageBody:@"Hello,\n" isHTML:NO];
	if ([[NSFileManager defaultManager] fileExistsAtPath:FileLoggerPath()]) {
		NSString *logData = [NSString stringWithContentsOfFile:FileLoggerPath()];
		[controller addAttachmentData:[logData dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:@"wordpress.log"];
	}
	
	if (controller) [self presentModalViewController:controller animated:YES];
	[controller release];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.faqButton = nil;
    self.forumButton = nil;
    self.helpText = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
