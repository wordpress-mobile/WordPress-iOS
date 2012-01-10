//
//  EditCommentViewController.m
//  WordPress
//
//  Created by John Bickerstaff on 1/24/10.
//  
//

#import "EditCommentViewController.h"
#import "WPProgressHUD.h"
#import "CommentViewController.h"

NSTimeInterval kAnimationDuration3 = 0.3f;

@interface EditCommentViewController (Private)

- (BOOL)isConnectedToHost;
- (void)initiateSaveCommentReply:(id)sender;
- (void)saveReplyBackgroundMethod:(id)sender;
- (void)callBDMSaveCommentEdit:(SEL)selector;
- (void)endTextEnteringButtonAction:(id)sender;
- (void)testStringAccess;
- (void) receivedRotate: (NSNotification*) notification;


@end



@implementation EditCommentViewController

@synthesize commentViewController, saveButton, doneButton, comment;
@synthesize cancelButton, label, hasChanges, textViewText, isTransitioning, isEditing;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
	 [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
     [super viewDidLoad];
      
     if (!saveButton) {
         saveButton = [[UIBarButtonItem alloc] 
         initWithTitle:NSLocalizedString(@"Save", @"") 
         style:UIBarButtonItemStyleDone
         target:self 
         action:@selector(initiateSaveCommentReply:)];
     }
     
     self.hasChanges = NO;
 
 }

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedRotate:) name: UIDeviceOrientationDidChangeNotification object: nil];
	
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelView:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
	
	textView.text = self.comment.content;
	//foo = textView.text;//so we can compare to set hasChanges correctly
	textViewText = [[NSString alloc] initWithString: textView.text];
	[textView becomeFirstResponder];
	isEditing = YES;
}

-(void) viewWillDisappear: (BOOL) animated{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.comment = nil;
	[saveButton release];
	[textViewText release];
	//[doneButton release];
    [super dealloc];
}

#pragma mark -
#pragma mark Button Override Methods

- (void)cancelView:(id)sender {
    [commentViewController cancelView:sender];
}

#pragma mark -
#pragma mark Helper Methods

- (void)test {
	// Huh???
	// NSLog(@"inside replyTOCommentViewController:test");
}

- (void)endTextEnteringButtonAction:(id)sender {
    [textView resignFirstResponder];
	if (DeviceIsPad() == NO) {
		UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
		if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
			isTransitioning = YES;
			UIViewController *garbageController = [[[UIViewController alloc] init] autorelease]; 
			[self.navigationController pushViewController:garbageController animated:NO]; 
			[self.navigationController popViewControllerAnimated:NO];
			self.isTransitioning = NO;
			[textView resignFirstResponder];
		}
	}
	isEditing = NO;
}

- (void)setTextViewHeight:(float)height {
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kAnimationDuration3];
    CGRect frame = textView.frame;
    frame.size.height = height;
    textView.frame = frame;
	[UIView commitAnimations];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	if (DeviceIsPad())
		return YES;
	else if (self.isTransitioning){
        self.comment.content = textView.text;
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
    else if (isEditing) {
        return YES;
    }
	
	return NO;
}

-(void) receivedRotate: (NSNotification*) notification
{
	if (isEditing) {
		UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
		if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
			if (DeviceIsPad())
				[self setTextViewHeight:353];
			else
				[self setTextViewHeight:106];
		}
		else if (UIInterfaceOrientationIsPortrait(interfaceOrientation)){
			if (DeviceIsPad())
				[self setTextViewHeight:504];
			else
				[self setTextViewHeight:200];
		}
	}
}

#pragma mark -
#pragma mark Text View Delegate Methods

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	NSString *textString = textView.text;
	if (![textString isEqualToString:textViewText]) {
		self.hasChanges=YES;
	}
	
	self.isEditing = NO;
	
	if (DeviceIsPad())
		[self setTextViewHeight:576];
	else
		[self setTextViewHeight:416];
	
	if (DeviceIsPad() == NO) {
		self.navigationItem.leftBarButtonItem =
		[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"")
										 style: UIBarButtonItemStyleBordered
										target:self
										action:@selector(cancelView:)];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	self.navigationItem.rightBarButtonItem = saveButton;
	if (DeviceIsPad() == NO) {
		doneButton = [[UIBarButtonItem alloc] 
					  initWithTitle:NSLocalizedString(@"Done", @"") 
					  style:UIBarButtonItemStyleDone 
					  target:self 
					  action:@selector(endTextEnteringButtonAction:)];
		
		[self.navigationItem setLeftBarButtonItem:doneButton];
	}
	isEditing = YES;
	[self receivedRotate:nil]; 
}

//replace "&nbsp" with a space @"&#160;" before Apple's broken TextView handling can do so and break things
//this enables the "http helper" to work as expected
//important is capturing &nbsp BEFORE the semicolon is added.  Not doing so causes a crash in the textViewDidChange method due to array overrun
- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	
	//if nothing has been entered yet, or if user deletes all text, return YES to prevent crash when hitting delet
    if (text.length == 0) {
		return YES;
    }
	
    // create final version of textView after the current text has been inserted
    NSMutableString *updatedText = [[NSMutableString alloc] initWithString:aTextView.text];
    [updatedText insertString:text atIndex:range.location];
	
    NSRange replaceRange = range, endRange = range;
	
    if (text.length > 1) {
        // handle paste
        replaceRange.length = text.length;
    } else {
        // handle normal typing
        replaceRange.length = 6;  // length of "&#160;" is 6 characters
		if( replaceRange.location >= 5) //we should check the location. the new location must be > 0
			replaceRange.location -= 5; // look back one characters (length of "&#160;" minus one)
		else {
			//the beginning of the field
			replaceRange.location = 0; 
			replaceRange.length = 5;
		}
    }
	
	int replaceCount = 0;
	
	@try{
		// replace "&nbsp" with "&#160;" for the inserted range
		if([updatedText length] > 4)
			replaceCount = [updatedText replaceOccurrencesOfString:@"&nbsp" withString:@"&#160;" options:NSCaseInsensitiveSearch range:replaceRange];
	}
	@catch (NSException *e){
		NSLog(@"NSRangeException: Can't replace text in range.");
	}
	@catch (id ue) { // least specific type. NSRangeException is a const defined in a string constant
		NSLog(@"NSRangeException: Can't replace text in range.");
	}
	
    if (replaceCount > 0) {
        // update the textView's text
        aTextView.text = updatedText;
		
        // leave cursor at end of inserted text
        endRange.location += text.length + replaceCount * 1; // length diff of "&nbsp" and "&#160;" is 1 character
        aTextView.selectedRange = endRange; 
		
        [updatedText release];
		
        // let the textView know that it should ingore the inserted text
        return NO;
    }
	
    [updatedText release];
	
    // let the textView know that it should handle the inserted text
    return YES;
}

#pragma mark -
#pragma mark Comment Handling Methods

- (BOOL)isConnectedToHost {
  WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ( appDelegate.currentBlogAvailable == NO ) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No connection to host.", @"")
																	  message:NSLocalizedString(@"Operation is not supported now.", @"")
																	 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [connectionFailAlert show];
        [connectionFailAlert release];
        return NO;
    }
	
    return YES;
}

- (void)initiateSaveCommentReply:(id)sender {
	[self endTextEnteringButtonAction: sender];
	if(hasChanges == NO) {
		if (DeviceIsPad() == YES) {
			[commentViewController performSelectorOnMainThread:@selector(cancelView:) withObject:self waitUntilDone:NO];
		} else
			[self.navigationController popViewControllerAnimated:YES];
		return;
	}
	self.comment.content = textView.text;
	commentViewController.wasLastCommentPending = YES;
	[commentViewController showComment:comment];
	[self.navigationController popViewControllerAnimated:YES];
	
    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Saving Edit...", @"")];
    [progressAlert show];
    [self.comment uploadWithSuccess:^{
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        [progressAlert release];
        self.hasChanges = NO;
		if (DeviceIsPad() == YES) {
			[commentViewController performSelectorOnMainThread:@selector(cancelView:) withObject:self waitUntilDone:NO];
		}
    } failure:^(NSError *error) {
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        [progressAlert release];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:NSLocalizedString(@"Something went wrong posting the comment reply.", @"")];
    }];
}

@end
