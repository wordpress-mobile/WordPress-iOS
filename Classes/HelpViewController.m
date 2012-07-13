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

- (void)dealloc {    
    [faqButton release];
    [forumButton release];
    [emailButton release];
    [cancel release];
    [navBar release];
    [helpText release];
    
    [super dealloc];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.faqButton = nil;
    self.forumButton = nil;
    self.helpText = nil;
    self.cancel = nil;
    self.navBar = nil;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
	if (![MFMailComposeViewController canSendMail])
		[emailButton setHidden:YES]; 
	
	if (IS_IPAD)
		self.navigationItem.title = NSLocalizedString(@"Help", @"");
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    
    self.helpText.text = NSLocalizedString(@"Please visit the FAQ to get answers to common questions. If you're still having trouble, post in the forums or email us.", @"");
    [self.faqButton setTitle:NSLocalizedString(@"Read the FAQ", @"") forState:UIControlStateNormal];
    [self.forumButton setTitle:NSLocalizedString(@"Visit the Forums", @"") forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	if (IS_IPAD && isBlogSetup)
			[navBar setHidden:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
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
		NSString *logData = [NSString stringWithContentsOfFile:FileLoggerPath() encoding:NSUTF8StringEncoding error:nil];
		[controller addAttachmentData:[logData dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:@"wordpress.log"];
	}
	
	if (controller) [self presentModalViewController:controller animated:YES];
	[controller release];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
	[self dismissModalViewControllerAnimated:YES];
}



@end
