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

@interface EditCommentViewController (Private)

- (BOOL)isConnectedToHost;
- (void)initiateSaveCommentReply:(id)sender;
- (void)saveReplyBackgroundMethod:(id)sender;
- (void)callBDMSaveCommentEdit:(SEL)selector;
- (void)endTextEnteringButtonAction:(id)sender;
- (void)testStringAccess;

@end

@implementation EditCommentViewController

@synthesize commentViewController, saveButton, doneButton, comment;
@synthesize cancelButton, hasChanges, textViewText, isTransitioning, isEditing;


- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
      
    if (!saveButton) {
        self.saveButton = [[UIBarButtonItem alloc] 
                      initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment).") 
                      style:UIBarButtonItemStyleDone
                      target:self 
                      action:@selector(initiateSaveCommentReply:)];
        
        self.navigationItem.rightBarButtonItem = saveButton;
     }
     
     self.hasChanges = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewWillAppear:animated];
	
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelView:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
	
	textView.text = self.comment.content;
	//foo = textView.text;//so we can compare to set hasChanges correctly
	textViewText = [[NSString alloc] initWithString: textView.text];
	[textView becomeFirstResponder];
	isEditing = YES;
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
	if (IS_IPAD == NO) {
		UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
		if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
			isTransitioning = YES;
			UIViewController *garbageController = [[UIViewController alloc] init]; 
			[self.navigationController pushViewController:garbageController animated:NO]; 
			[self.navigationController popViewControllerAnimated:NO];
			self.isTransitioning = NO;
			[textView resignFirstResponder];
		}
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
										 style: UIBarButtonItemStyleBordered
										target:self
										action:@selector(cancelView:)];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	if (IS_IPAD == NO) {
		self.doneButton = [[UIBarButtonItem alloc] 
					  initWithTitle:NSLocalizedString(@"Done", @"") 
					  style:UIBarButtonItemStyleDone 
					  target:self 
					  action:@selector(endTextEnteringButtonAction:)];
		
		[self.navigationItem setLeftBarButtonItem:doneButton];
	}
	isEditing = YES;
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
        return NO;
    }
	
    return YES;
}

- (void)initiateSaveCommentReply:(id)sender {
	[self endTextEnteringButtonAction: sender];
	if(hasChanges == NO) {
        [commentViewController cancelView:self];
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
        self.hasChanges = NO;
        [commentViewController cancelView:self];
    } failure:^(NSError *error) {
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        
        NSString *message = NSLocalizedString(@"Sorry, something went wrong during comment moderation. Please try again.", @"");
        
        if (error.code == 405) {
            // XML-RPC is disabled.
            message = error.localizedDescription;
        }
        
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:message];
    }];
}

@end
