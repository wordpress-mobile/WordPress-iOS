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

@interface EditCommentViewController : UIViewController <UIActionSheetDelegate> {
    CommentViewController *commentViewController;
    UIAlertView *progressAlert;

    IBOutlet UITextView *textView;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *cancelButton;
    BOOL hasChanges, isTransitioning, isEditing;
    NSString *textViewText; //to compare for hasChanges

}
	
	
@property (nonatomic, strong) Comment *comment;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) CommentViewController *commentViewController;
@property (nonatomic) BOOL hasChanges;
@property (nonatomic) BOOL isTransitioning;
@property (nonatomic) BOOL isEditing;
@property (nonatomic, strong) NSString *textViewText;
    
-(void)cancelView:(id)sender;

@end
