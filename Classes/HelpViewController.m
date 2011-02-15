//
//  Help.m
//  WordPress
//
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "HelpViewController.h"


@implementation HelpViewController

@synthesize faqButton, forumButton, emailButton, cancel, navBar;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (![MFMailComposeViewController canSendMail])
		[emailButton setHidden:YES]; 
	
	if (DeviceIsPad()) {
		[navBar setHidden:YES];
		self.navigationItem.title = @"Help";
	}
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
	[controller setSubject:@"WordPress for iOS Help Request"];
	[controller setMessageBody:@"Hello,\n" isHTML:NO]; 
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
	[faqButton release];
	[forumButton release];
    [emailButton release];
}


- (void)dealloc {
    [super dealloc];
}


@end
