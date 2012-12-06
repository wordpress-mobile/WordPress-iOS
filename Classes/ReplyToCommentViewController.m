//
//  ReplyToCommentViewController.m
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import "ReplyToCommentViewController.h"
#import "WPProgressHUD.h"

@interface ReplyToCommentViewController (Private)

- (BOOL)isConnectedToHost;
- (void)initiateSaveCommentReply:(id)sender;
- (void)saveReplyBackgroundMethod:(id)sender;
- (void)callBDMSaveCommentReply:(SEL)selector;
- (void)endTextEnteringButtonAction:(id)sender;
- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;

@end

@implementation ReplyToCommentViewController

@synthesize delegate, saveButton, doneButton, comment;
@synthesize cancelButton, hasChanges, textViewText, isTransitioning, isEditing;


- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidLoad];
		
	if (!saveButton) {
	saveButton = [[UIBarButtonItem alloc] 
				  initWithTitle:NSLocalizedString(@"Reply", @"") 
				  style:UIBarButtonItemStyleDone
				  target:self 
				  action:@selector(initiateSaveCommentReply:)];
	}
    self.navigationItem.rightBarButtonItem = saveButton;
    
	isEditing = YES;
    self.hasChanges = NO;
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}


- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];
	
	//foo = textView.text;//so we can compare to set hasChanges correctly
	textViewText = [[NSString alloc] initWithString: textView.text];
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelView:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
	cancelButton = nil;
	
	[textView becomeFirstResponder];

}


- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidUnload];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark -
#pragma mark KeyboardNotification Methods

- (void)handleKeyboardDidShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;

    CGRect keyFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect rect = [self.view convertRect:keyFrame fromView:self.view.window];

    CGRect frm = self.view.frame;
    frm.size.height = rect.origin.y;
    
    textView.frame = frm;
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
    CGRect frm = textView.frame;
    frm.size.height = self.view.frame.size.height;
    textView.frame = frm;
}


#pragma mark -
#pragma mark Button Override Methods

- (void)cancelView:(id)sender {
	if (![textView.text isEqualToString:textViewText]) {
		self.hasChanges=YES;
	}
	if (delegate) {
		[delegate cancelReplyToCommentViewController:self];	
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
}


#pragma mark -
#pragma mark Helper Methods

- (void)endTextEnteringButtonAction:(id)sender {
    [textView resignFirstResponder];
	UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
	if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
		isTransitioning = YES;
		UIViewController *garbageController = [[UIViewController alloc] init]; 
		[self.navigationController pushViewController:garbageController animated:NO]; 
		[self.navigationController popViewControllerAnimated:NO];
		self.isTransitioning = NO;
		[textView resignFirstResponder];
	}
	isEditing = NO;
}


#pragma mark -
#pragma mark Text View Delegate Methods

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	NSString *textString = textView.text;
	if (![textString isEqualToString:textViewText]) {
		self.hasChanges=YES;
	}
	
	self.isEditing = NO;
	
	if (IS_IPAD == NO) {
		self.navigationItem.leftBarButtonItem =
		[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"")
										 style:UIBarButtonItemStyleBordered
										target:self
										action:@selector(cancelView:)];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	self.navigationItem.rightBarButtonItem = saveButton;
	
	if (IS_IPAD == NO) {
		doneButton = [[UIBarButtonItem alloc] 
									   initWithTitle:NSLocalizedString(@"Done", @"") 
									   style:UIBarButtonItemStyleDone 
									   target:self 
									   action:@selector(endTextEnteringButtonAction:)];
		
		[self.navigationItem setLeftBarButtonItem:doneButton];
	}
	isEditing = YES;
}


//replace "&nbsp" with a space @"&#160;" before Apple's broken TextView handling can do so and break things
//this enables the "http helper" to work as expected
//important is capturing &nbsp BEFORE the semicolon is added.  Not doing so causes a crash in the textViewDidChange method due to array overrun
- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	//if nothing has been entered yet, return YES to prevent crash when hitting delete
	
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
		
		updatedText = nil;
		
        // let the textView know that it should ingore the inserted text
        return NO;
    }
	
	updatedText = nil;
	
    // let the textView know that it should handle the inserted text
    return YES;
}


#pragma mark -
#pragma mark Comment Handling Methods

- (BOOL)isConnectedToHost {
    WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.currentBlogAvailable == NO ) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Problem", @"")
																	  message:NSLocalizedString(@"The internet connection appears to be offline.", @"")
																	 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [connectionFailAlert show];
        return NO;
    }
	
    return YES;
}

- (void)initiateSaveCommentReply:(id)sender {
	//we should call endTextEnteringButtonAction here, bc if you click on reply without clicking on the 'done' btn
	//within the keyboard, the textViewDidEndEditing is never called
	[self endTextEnteringButtonAction:sender];
	if(hasChanges == NO) {
		if (IS_IPAD == YES) {
			[textView becomeFirstResponder];
		}
		UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"The Reply is Empty", @"")
                                                                      message:NSLocalizedString(@"Please type a reply to the comment.", @"")
                                                                     delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [connectionFailAlert show];
		return;
	}
	
    progressAlert = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Sending Reply...", @"")];
    [progressAlert show];
    self.comment.content = textView.text;
    [self.comment uploadWithSuccess:^{
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        progressAlert = nil;
		hasChanges = NO;
		if(delegate && [delegate respondsToSelector:@selector(closeReplyViewAndSelectTheNewComment)]){
			[delegate closeReplyViewAndSelectTheNewComment];
		} else {
			[self cancelView:nil];
		}
    } failure:^(NSError *error) {
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        progressAlert = nil;
        
        NSString *message = NSLocalizedString(@"Sorry, something went wrong posting the comment reply. Please try again.", @"");

        if (error.code == 405) {
            // XML-RPC is disabled.
            message = error.localizedDescription;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:message];
    }];
}

@end
