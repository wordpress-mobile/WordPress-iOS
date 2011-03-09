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
{
		
		CommentViewController *commentViewController;
		UIAlertView *progressAlert;
		
		IBOutlet UITextView *textView;
		IBOutlet UILabel *label;
		UIBarButtonItem *saveButton;
		UIBarButtonItem *doneButton;
		UIBarButtonItem *cancelButton;
		BOOL hasChanges, isTransitioning, isEditing;
		NSString *textViewText; //to compare for hasChanges
		
		
	}
	
	
	@property (nonatomic, retain) Comment *comment;
	@property (nonatomic, retain) UIBarButtonItem *saveButton;
	@property (nonatomic, retain) UIBarButtonItem *doneButton;
	@property (nonatomic, retain) UIBarButtonItem *cancelButton;
	@property (nonatomic, retain) CommentViewController *commentViewController;
	@property (nonatomic, retain) UILabel *label;
	@property (nonatomic) BOOL hasChanges;
	@property (nonatomic) BOOL isTransitioning;
	@property (nonatomic) BOOL isEditing;
	@property (nonatomic, retain) NSString *textViewText;
		
	-(void)cancelView:(id)sender;

@end
