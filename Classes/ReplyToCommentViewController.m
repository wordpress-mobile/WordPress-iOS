//
//  EditCommentViewController.m
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import "ReplyToCommentViewController.h"
#import "BlogDataManager.h"
#import "WPProgressHUD.h"
#import "Reachability.h"

@interface ReplyToCommentViewController (Private)

- (BOOL)isConnectedToHost;
- (void)initiateSaveCommentReply:(id)sender;
- (void)saveReplyBackgroundMethod:(id)sender;
- (void)callBDMSaveCommentReply:(SEL)selector;
- (void)endTextEnteringButtonAction:(id)sender;


@end



@implementation ReplyToCommentViewController

@synthesize commentViewController, commentDetails, currentIndex, saveButton, doneButton;

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
	
	if (!saveButton) {
	saveButton = [[UIBarButtonItem alloc] 
				  initWithTitle:@"Save" 
				  style:UIBarButtonItemStylePlain 
				  target:self 
				  action:@selector(endTextEnteringButtonAction:)];
	}
	
	//if (!saveButton) {
	
	//}
	
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated {

	
//	[commentViewController.navigationItem setBackBarButtonItem:doneButton];
//	[commentViewController.navigationItem setBackBarButtonItem:backButton];
//	[backButton release];
	
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
#pragma mark Text View Methods

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	
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
								   style:UIBarButtonItemStylePlain 
								   target:self 
								   action:@selector(endTextEnteringButtonAction:)];
	
	//self.navigationItem.backBarButtonItem = doneButton;
	[commentViewController.navigationItem setBackBarButtonItem:doneButton];
	//commentViewController.navigationItem.backBarButtonItem = doneButton;
	
	//UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Foo" style:UIBarButtonItemStyleDone target:nil action:nil];
//	[self.navigationItem setBackBarButtonItem:backButton];
//	[backButton release];
}

- (void)endTextEnteringButtonAction:(id)sender {

    [textView resignFirstResponder];
//    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:pageDetailsController.leftView];
//    pageDetailsController.navigationItem.leftBarButtonItem = barButton;
//    [barButton release];
//	if((pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || 
//	   (pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeRight))
//		[[UIDevice currentDevice] setOrientation:UIInterfaceOrientationPortrait];
	
	[self initiateSaveCommentReply: nil];
	
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
	
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Saving Your Reply..."];
    [progressAlert show];
	
    [self performSelectorInBackground:@selector(saveReplyBackgroundMethod:) withObject:nil];

}

- (void)saveReplyBackgroundMethod:(id)sender {
	[self callBDMSaveCommentReply:@selector(replyToComment:forBlog:)];
}

- (void)callBDMSaveCommentReply:(SEL)selector {
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

if ([self isConnectedToHost]) {
	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	
	//NSMutableArray *selectedComment = [NSArray arrayWithObjects:[commentDetails objectAtIndex:currentIndex], nil];
	//After getting selected comment, we need to replace whatever necessary data with 
	//whatever the user put into the text field...  for sure the "content" field... anything else?
	//it may be possible to simply replace the content with the new content and send this off to the BDM method...
	//at this point it's neither fish nor fowl, because it's a hybrid with new content but all the "old" data
	//from the parent comment.  As far as I can see, that's what's needed - parent id, username etc and new content...
	//BDM replyToComment method will take this and format the xmlrpc POST.
	
	NSMutableDictionary *comment = [commentDetails objectAtIndex:currentIndex];
	[comment setValue:textView.text forKey:@"content"];
	//NSString *commentid = [commentsDict valueForKey:@"comment_id"];
	
	
	[sharedDataManager performSelector:selector withObject:comment withObject:[sharedDataManager currentBlog]];
	
	[sharedDataManager loadCommentTitlesForCurrentBlog];
	[self.navigationController popViewControllerAnimated:YES];
}

[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
[progressAlert release];
[pool release];
}


@end
