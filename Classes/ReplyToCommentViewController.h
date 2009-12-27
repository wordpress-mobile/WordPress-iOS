//
//  EditCommentViewController.h
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import <UIKit/UIKit.h>
#import "CommentViewController.h"


@interface ReplyToCommentViewController : UIViewController {
	
	CommentViewController *commentViewController;
	UIAlertView *progressAlert;
	
	NSMutableArray *commentDetails;
    int currentIndex;
	IBOutlet UITextView *textView;
	UIBarButtonItem *saveButton;
	UIBarButtonItem *doneButton;


}

@property (nonatomic, retain) CommentViewController *commentViewController;
@property (nonatomic, retain) NSMutableArray *commentDetails;
@property (nonatomic, retain) UIBarButtonItem *saveButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;

@property int currentIndex;

@end
