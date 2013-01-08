//
//  EditCommentViewController.h
//  WordPress
//
//  Created by John Bickerstaff on 1/24/10.
//  
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@class CommentViewController;

@interface EditCommentViewController : UIViewController <UIActionSheetDelegate>
	
@property (nonatomic, strong) Comment *comment;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) CommentViewController *commentViewController;
@property (nonatomic) BOOL hasChanges;
@property (nonatomic) BOOL isTransitioning;
@property (nonatomic) BOOL isEditing;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSString *textViewText;
@property (nonatomic, strong) UIAlertView *progressAlert;

- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;
- (void)endTextEnteringButtonAction:(id)sender;
- (void)textViewDidEndEditing:(UITextView *)aTextView;
- (void)textViewDidBeginEditing:(UITextView *)aTextView;
- (BOOL)isConnectedToHost;
- (void)initiateSaveCommentReply:(id)sender;
- (void)cancelView:(id)sender;

@end
