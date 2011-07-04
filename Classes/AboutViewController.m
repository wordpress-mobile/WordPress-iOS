//
//  AboutViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "AboutViewController.h"


@implementation AboutViewController

@synthesize appTitleText, appDescriptionText, websiteButton, privacyPolicyButton, termsOfServiceButton, cancel, navBar, isBlogSetup;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
	if (![MFMailComposeViewController canSendMail])
		[emailButton setHidden:YES]; 
	
	if (DeviceIsPad())
		self.navigationItem.title = NSLocalizedString(@"About", @"");
    
    self.appTitleText.text = NSLocalizedString(@"WordPress for iOS", @"");
	self.appDescriptionText.text = NSLocalizedString(@"Publisher: Automattic - Copyright: Automattic", @"");
	[self.termsOfServiceButton setTitle:NSLocalizedString(@"Terms of Service", @"") forState:UIControlStateNormal];
	[self.privacyPolicyButton setTitle:NSLocalizedString(@"Privacy Policy", @"") forState:UIControlStateNormal];
    [self.websiteButton setTitle:NSLocalizedString(@"www.automattic.com", @"") forState:UIControlStateNormal];
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

-(void) viewTermsOfService: (id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://wordpress.com/tos/"]];
	//[self dismissModalViewControllerAnimated:YES];
}

-(void) viewPrivacyPolicy: (id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://automattic.com/privacy/"]];
	//[self dismissModalViewControllerAnimated:YES];
}

-(void) viewWebsite: (id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://automattic.com/"]];
	//[self dismissModalViewControllerAnimated:YES];
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
    self.termsOfServiceButton = nil;
    self.privacyPolicyButton = nil;
    self.websiteButton = nil;
    self.appTitleText = nil;
	self.appDescriptionText = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
