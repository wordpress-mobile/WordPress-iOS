//
//  EditCommentViewController.h
//  WordPress
//
//  Created by John Bickerstaff on 1/24/10.
//  
//

#import <UIKit/UIKit.h>
#import "WPNavigationLeftButtonView.h"


@class CommentViewController;

@interface EditCommentViewController : UIViewController <UIActionSheetDelegate>
{
		
		CommentViewController *commentViewController;
		UIAlertView *progressAlert;
		
		NSMutableArray *commentDetails;
		NSMutableDictionary *comment;
		int currentIndex;
		IBOutlet UITextView *textView;
		IBOutlet UILabel *label;
		UIBarButtonItem *saveButton;
		UIBarButtonItem *doneButton;
		UIBarButtonItem *cancelButton;
		WPNavigationLeftButtonView *leftView;
		BOOL hasChanges;
		NSString *textViewText; //to compare for hasChanges
		
		
	}
	
	
	@property (nonatomic, retain) NSMutableArray *commentDetails;
	@property (nonatomic, retain) NSMutableDictionary *comment;
	@property (nonatomic, retain) UIBarButtonItem *saveButton;
	@property (nonatomic, retain) UIBarButtonItem *doneButton;
	@property (nonatomic, retain) UIBarButtonItem *cancelButton;
	@property (nonatomic, retain)   WPNavigationLeftButtonView *leftView;
	@property (nonatomic, retain) CommentViewController *commentViewController;
	@property (nonatomic, retain) UILabel *label;
	@property (nonatomic) BOOL hasChanges;
	@property (nonatomic, retain) NSString *textViewText;
	
	@property int currentIndex;
	
	-(void)cancelView:(id)sender;

@end
