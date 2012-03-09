//
//  BetaFeedbackViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 2/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BetaFeedbackViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate>{
	
	IBOutlet UITextField *name;
	IBOutlet UITextField *email;
	IBOutlet UITextView *feedback;
	IBOutlet UIBarButtonItem *cancelButton;
	IBOutlet UIBarButtonItem *sendFeedbackButton;
	BOOL isEditingFeedback;
	UITextField *activeField;
	IBOutlet UIScrollView *scrollView;

}

@property (nonatomic, retain) IBOutlet UITextField *name;
@property (nonatomic, retain) IBOutlet UITextField *email;
@property (nonatomic, retain) IBOutlet UITextView *feedback;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *sendFeedbackButton;
@property (nonatomic, retain) UITextField *activeField;
@property (nonatomic, retain) UIScrollView *scrollView;

-(IBAction) cancel: (id)sender;
-(IBAction) sendFeedback: (id)sender;
-(void) sendFeedback: (id)sender;
-(void) registerForKeyboardNotifications;
-(void) checkSendButtonEnable;
@end
