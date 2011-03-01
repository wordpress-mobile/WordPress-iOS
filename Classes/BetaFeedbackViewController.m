//
//  BetaFeedbackViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 2/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "BetaFeedbackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WPDataController.h"


@implementation BetaFeedbackViewController

@synthesize name, email, feedback, cancelButton, sendFeedbackButton, activeField, scrollView;


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
    [feedback.layer setCornerRadius:5.0f];
    [feedback.layer setMasksToBounds:YES];
	
	name.delegate = self;
	email.delegate = self;
	feedback.delegate = self;
	
	//[scrollView
	 //setContentSize:CGSizeMake(self.view.frame.size.width,
	//						   self.view.frame.size.height+200)];
	
	[self registerForKeyboardNotifications];
	
}

- (void)dealloc {
	[name release];
	[email release];
	[feedback release];
	[cancelButton release];
	[sendFeedbackButton release];
	[activeField release];
	[scrollView release];
    [super dealloc];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	activeField = nil;
	[self checkSendButtonEnable];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	if ([textView.text isEqualToString:@"Feedback (required)"])
		textView.text = nil;
	textView.textColor = [UIColor blackColor];
	isEditingFeedback = YES;
	if (!DeviceIsPad())
		cancelButton.title = @"Done";
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	[self checkSendButtonEnable];
}

-(void)checkSendButtonEnable {
	if (![name.text isEqualToString:@""] && ![email.text isEqualToString:@""] && ![feedback.text isEqualToString:@""] && ![feedback.text isEqualToString:@"Feedback (required)"])
		[sendFeedbackButton setEnabled:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
	if (textField == name)
		[email becomeFirstResponder];
	else if (textField == email) {
		[feedback becomeFirstResponder];
		CGPoint scrollPoint = CGPointMake(0.0, feedback.frame.origin.y - 20);
		[scrollView setContentOffset:scrollPoint animated:YES];
	}
    return YES;
}

-(void) cancel: (id)sender {
	if (isEditingFeedback && !DeviceIsPad()) {
		[feedback resignFirstResponder];
		isEditingFeedback = NO;
		cancelButton.title = @"Cancel";
	}
	else
		[self dismissModalViewControllerAnimated:YES];
}

-(void) sendFeedback: (id)sender {
	[sendFeedbackButton setEnabled:NO];
	sendFeedbackButton.title = @"Sending...";
	[self performSelectorInBackground:@selector(sendFeedbackInBackground) withObject: nil];
}

-(void) sendFeedbackInBackground{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (![name.text isEqualToString:@""] && ![email.text isEqualToString:@""] && ![feedback.text isEqualToString:@""] && ![feedback.text isEqualToString:@"Feedback (required)"]) {
		XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:@"http://iosbeta.wordpress.com/xmlrpc.php"]];
		NSMutableDictionary *commentParams = [NSMutableDictionary dictionary];
		
		[commentParams setObject:feedback.text forKey:@"content"];
		[commentParams setObject:@"153" forKey:@"post_id"];
		[commentParams setObject:@"approve" forKey:@"status"];
		[commentParams setObject:email.text forKey:@"author_email"];
		[commentParams setObject:name.text forKey:@"author"];
		NSArray *args = [NSArray arrayWithObjects:@"15835028", @"", @"", @"153", commentParams, nil];
		
		[xmlrpcRequest setMethod:@"wp.newComment" withObjects:args];
		NSNumber *result = [[WPDataController sharedInstance] executeXMLRPCRequest:xmlrpcRequest];
		[xmlrpcRequest release];
		if ([result isKindOfClass:[NSError class]]) {
			//oh well
			//NSLog(@"wpNewComment failed: %@", result);
			
		}
		[self dismissModalViewControllerAnimated:YES];
	}
	else {
		[sendFeedbackButton setEnabled:YES];
		sendFeedbackButton.title = @"Send";
	}
	[pool release];
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillBeHidden:)
												 name:UIKeyboardWillHideNotification object:nil];
	
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardBoundsUserInfoKey] CGRectValue].size;
	
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
	
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
	if (activeField == email) {
		CGPoint scrollPoint = CGPointMake(0.0, email.frame.origin.y - 20);
		[scrollView setContentOffset:scrollPoint animated:YES];
	}
	else if (isEditingFeedback){
		CGPoint scrollPoint = CGPointMake(0.0, feedback.frame.origin.y - 20);
		[scrollView setContentOffset:scrollPoint animated:YES];
	}
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
	if (DeviceIsPad())
		return YES;

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


@end
