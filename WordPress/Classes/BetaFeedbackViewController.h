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

@property (nonatomic, strong) IBOutlet UITextField *name;
@property (nonatomic, strong) IBOutlet UITextField *email;
@property (nonatomic, strong) IBOutlet UITextView *feedback;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *sendFeedbackButton;
@property (nonatomic, strong) UITextField *activeField;
@property (nonatomic, strong) UIScrollView *scrollView;

-(IBAction) cancel: (id)sender;
-(IBAction) sendFeedback: (id)sender;
-(void) sendFeedback: (id)sender;
-(void) registerForKeyboardNotifications;
-(void) checkSendButtonEnable;
@end
