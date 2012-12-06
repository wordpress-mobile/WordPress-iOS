//
//  ReplyToCommentViewController.h
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@class CommentViewController;

@protocol ReplyToCommentViewControllerDelegate <NSObject>

- (void)cancelReplyToCommentViewController:(id)sender;

@optional
- (void)closeReplyViewAndSelectTheNewComment;

@end

@interface ReplyToCommentViewController : UIViewController <UIActionSheetDelegate>{
	
	id <ReplyToCommentViewControllerDelegate> delegate;
	UIAlertView *progressAlert;
	
	IBOutlet UITextView *textView;
	UIBarButtonItem *saveButton;
	UIBarButtonItem *doneButton;
	UIBarButtonItem *cancelButton;
	BOOL hasChanges, isTransitioning, isEditing;
	NSString *textViewText; //to compare for hasChanges
	
}

@property (nonatomic, strong) id<ReplyToCommentViewControllerDelegate> delegate;
@property (nonatomic, strong) Comment *comment;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic) BOOL hasChanges;
@property (nonatomic) BOOL isTransitioning;
@property (nonatomic) BOOL isEditing;
@property (nonatomic, copy) NSString *textViewText;

-(void)cancelView:(id)sender;

@end
