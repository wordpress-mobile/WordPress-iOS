//
//  ReplyToCommentViewController.m
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import "ReplyToCommentViewController.h"

@implementation ReplyToCommentViewController

@synthesize delegate;

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidLoad];
    
    // Replace the text of the existing save button with "Reply"
    self.navigationItem.rightBarButtonItem.title = @"Reply";
	self.isEditing = YES;
 }

#pragma mark -
#pragma mark Comment Handling Methods

- (void)initiateSaveCommentReply:(id)sender {
	//we should call endTextEnteringButtonAction here, bc if you click on reply without clicking on the 'done' btn
	//within the keyboard, the textViewDidEndEditing is never called
	[self endTextEnteringButtonAction:sender];
	if(self.hasChanges == NO) {
		if (IS_IPAD == YES) {
			[self.textView becomeFirstResponder];
		}
		UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"The Reply is Empty", @"")
                                                                      message:NSLocalizedString(@"Please type a reply to the comment.", @"")
                                                                     delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [connectionFailAlert show];
		return;
	}
	
    self.textView.editable = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.comment.content = self.textView.text;
    [self.comment uploadWithSuccess:^{
		self.hasChanges = NO;
		if(delegate && [delegate respondsToSelector:@selector(closeReplyViewAndSelectTheNewComment)]){
			[delegate closeReplyViewAndSelectTheNewComment];
		} else {
			[self cancelView:nil];
		}
    } failure:^(NSError *error) {
        self.textView.editable = YES;
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = YES;

        NSString *message = NSLocalizedString(@"Sorry, something went wrong posting the comment reply. Please try again.", @"");

        if (error.code == 405) {
            // XML-RPC is disabled.
            message = error.localizedDescription;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:message];
    }];
}

#pragma mark -
#pragma mark Button Override Methods

- (void)cancelView:(id)sender {
	if (![self.textView.text isEqualToString:self.textViewText]) {
		self.hasChanges = YES;
	}
	if (delegate) {
		[delegate cancelReplyToCommentViewController:self];
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
}

@end
