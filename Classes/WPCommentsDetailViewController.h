//
//  WPCommentsDetailViewController.h
//  WordPress
//
//  Created by ramesh kakula on 05/09/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kCustomButtonHeight		30.0

@interface WPCommentsDetailViewController : UIViewController {

    IBOutlet UILabel     *commenterNameLabel;
    IBOutlet UILabel     *commentedOnLabel;
    IBOutlet UILabel     *commentedDateLabel;
    IBOutlet UITextView  *commentsTextView;
    NSMutableArray *commentDetails;
	
    IBOutlet UIToolbar  *approveAndUnapproveButtonBar;
    IBOutlet UIToolbar  *deleteButtonBar;

     UIBarButtonItem *segmentBarItem;
    int currentIndex;	
}

@property (nonatomic,retain) UILabel *commenterNameLabel;
@property (nonatomic,retain) UILabel *commentedOnLabel;
@property (nonatomic,retain) UILabel *commentedDateLabel;
@property (nonatomic,retain) UITextView *commentsTextView;
@property (nonatomic, retain) NSMutableArray *commentDetails;


- (void)segmentAction:(id)sender;
-(void)fillCommentDetails:(NSArray*)comments atRow:(int)row;


- (void)deleteComment:(id)sender;
- (void)approveComment:(id)sender;
- (void)unApproveComment:(id)sender;

@end
