//
//  ReplyToCommentViewController.m
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import "ReplyToCommentViewController.h"
#import "BlogDataManager.h"
#import "WPProgressHUD.h"
#import "Reachability.h"

NSTimeInterval kAnimationDuration2 = 0.3f;

@interface ReplyToCommentViewController (Private)

- (BOOL)isConnectedToHost;
- (void)initiateSaveCommentReply:(id)sender;
- (void)saveReplyBackgroundMethod:(id)sender;
- (void)callBDMSaveCommentReply:(SEL)selector;
- (void)endTextEnteringButtonAction:(id)sender;


@end



@implementation ReplyToCommentViewController

@synthesize commentViewController, commentDetails, currentIndex, saveButton, doneButton, comment;
@synthesize leftView, cancelButton, label;

//TODO: Make sure to give this class a connection to commentDetails and currentIndex from CommentViewController

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
	[super viewDidLoad];
	
	comment = [[NSMutableDictionary alloc] init];
	
	if (!saveButton) {
	saveButton = [[UIBarButtonItem alloc] 
				  initWithTitle:@"Save" 
				  style:UIBarButtonItemStyleDone
				  target:self 
				  action:@selector(initiateSaveCommentReply:)];
	}
	
	
	if (!leftView) {
        leftView = [WPNavigationLeftButtonView createCopyOfView];
        [leftView setTitle:@"Comment"];
	}
	
}


- (void)viewWillAppear:(BOOL)animated {

	[leftView setTarget:self withAction:@selector(cancelView:)];
	cancelButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
	self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
	
	comment = [commentDetails objectAtIndex:currentIndex];
	if ([[comment valueForKey:@"status"] isEqualToString:@"hold"]) {
		NSLog(@"inside if of vwappear");
		label.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
		label.hidden = NO;
	} else {
		label.hidden = YES;
		//TODO: JOHNB - code movement of text view upward if this is not a pending comment
		
	}
	
	[textView becomeFirstResponder];
	

	
	
	
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[saveButton release];
	//[doneButton release];
    [super dealloc];
}

#pragma mark -
#pragma mark Button Override Methods

- (void)cancelView:(id)sender {
    [commentViewController cancelView:sender];
	NSLog(@"inside replyToCommentViewController cancelView");
	
//    if (!hasChanges) {
//        //[self stopTimer];
        //[commentViewController.navigationController popViewControllerAnimated:YES];
	//[commentViewController.navigationController popViewControllerAnimated:YES];
//        return;
//    }
//	
//	
//	
//    //[postSettingsController endEditingAction:nil];
//    //[postDetailEditController endEditingAction:nil];
//	
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
//															 delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard"
//													otherButtonTitles:nil];
//    actionSheet.tag = 401;
//    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
//    [actionSheet showInView:self.view];
//    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//    [delegate setAlertRunning:YES];
//	
//    [actionSheet release];
}

#pragma mark -
#pragma mark Helper Methods

- (void) test{
	NSLog(@"inside replyTOCommentViewController:test");
}

- (void)endTextEnteringButtonAction:(id)sender {
	
    [textView resignFirstResponder];
	//    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:pageDetailsController.leftView];
	//    pageDetailsController.navigationItem.leftBarButtonItem = barButton;
	//    [barButton release];
	//	if((pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || 
	//	   (pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeRight))
	//		[[UIDevice currentDevice] setOrientation:UIInterfaceOrientationPortrait];
	
	//[self initiateSaveCommentReply: nil];
	
}



#pragma mark -
#pragma mark Text View Delegate Methods


- (void)textViewDidEndEditing:(UITextView *)aTextView {
	//make the text view longer !!!! Will need to modify this for rotation
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kAnimationDuration2];
	CGRect frame = textView.frame;
	frame.size.height = 460.0f;
	textView.frame = frame;
    [UIView commitAnimations];
	
	
//	isEditing = NO;
//    dismiss = NO;
//	
//    if (isTextViewEditing) {
//        isTextViewEditing = NO;
//		
//        [self bringTextViewDown];
//		
//        if (postDetailViewController.hasChanges == YES) {
//            [leftView setTitle:@"Cancel"];
//        } else {
//            [leftView setTitle:@"Posts"];
//        }
	[leftView setTitle:@"Cancel"];
	UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:leftView];
	self.navigationItem.leftBarButtonItem = barItem;
	//[barItem release];
	//[barItem retain];
	
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	
	
//	//make the text view shorter !!!! Will need to modify this for rotation
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kAnimationDuration2];
	CGRect frame = textView.frame;
	frame.size.height = 225.0f;
	textView.frame = frame;
    [UIView commitAnimations];
	
 //   isEditing = YES;
//	
//	if ((postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
//		|| (postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeRight)) {
//        [self setTextViewHeight:116];
//		
//		
//    }
//	
//    dismiss = NO;
//	
//    if (!isTextViewEditing) {
//        isTextViewEditing = YES;
//		
//        [self updateTextViewPlacehoderFieldStatus];
		
       // UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
																	  //target:self action:@selector(endTextEnteringButtonAction:)];
		//UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain
																  //target:self action:@selector(endTextEnteringButtonAction:)];
	//[commentViewController.navigationItem setLeftBarButtonItem:doneButton];
	//[commentViewController.navigationItem setLeftBarButtonItem:saveButton];
	//commentViewController.navigationItem.leftBarButtonItem = saveButton;
        //[saveButton release];
		
        //[self bringTextViewUp];
//    }
	self.navigationItem.rightBarButtonItem = saveButton;
	doneButton = [[UIBarButtonItem alloc] 
								   initWithTitle:@"Done" 
								   style:UIBarButtonItemStyleDone 
								   target:self 
								   action:@selector(endTextEnteringButtonAction:)];
	
	[self.navigationItem setLeftBarButtonItem:doneButton];
	//[commentViewController.navigationItem setLeftBarButtonItem:doneButton];
	//commentViewController.navigationItem.backBarButtonItem = doneButton;
	
	//UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Foo" style:UIBarButtonItemStyleDone target:nil action:nil];
//	[self.navigationItem setBackBarButtonItem:backButton];
//	[backButton release];
}




#pragma mark -
#pragma mark Comment Handling Methods

- (BOOL)isConnectedToHost {
    if (![[Reachability sharedReachability] remoteHostStatus] != NotReachable) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
																	  message:@"Operation is not supported now."
																	 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectionFailAlert show];
        [connectionFailAlert release];
        return NO;
    }
	
    return YES;
}

- (void)initiateSaveCommentReply:(id)sender {

    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Saving Reply..."];
    [progressAlert show];
	comment = [commentDetails objectAtIndex:currentIndex];
	[comment setValue:textView.text forKey:@"content"];	
    [self performSelectorInBackground:@selector(saveReplyBackgroundMethod:) withObject:nil];
	[self.navigationController popViewControllerAnimated:YES];
	

}

- (void)saveReplyBackgroundMethod:(id)sender {
	[self callBDMSaveCommentReply:@selector(replyToComment:forBlog:)];
	NSLog(@"after callBDMSaveCommentReply");
}

- (void)callBDMSaveCommentReply:(SEL)selector {
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

if ([self isConnectedToHost]) {
	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	[sharedDataManager performSelector:selector withObject:[self comment] withObject:[sharedDataManager currentBlog]];
	[sharedDataManager loadCommentTitlesForCurrentBlog];
}

[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
[progressAlert release];
[pool release];
}


@end
