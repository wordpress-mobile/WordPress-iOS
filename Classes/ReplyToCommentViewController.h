//
//  ReplyToCommentViewController.h
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import <UIKit/UIKit.h>
#import "WPNavigationLeftButtonView.h"


@class CommentViewController;


@interface ReplyToCommentViewController : UIViewController <UIActionSheetDelegate>{
	
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


}


@property (nonatomic, retain) NSMutableArray *commentDetails;
@property (nonatomic, retain) NSMutableDictionary *comment;
@property (nonatomic, retain) UIBarButtonItem *saveButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;
@property (nonatomic, retain)   WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) CommentViewController *commentViewController;
@property (nonatomic, retain) UILabel *label;

@property int currentIndex;

-(void)cancelView:(id)sender;
-(void) test;

@end
