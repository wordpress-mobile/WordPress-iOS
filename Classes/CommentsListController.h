//
//  CommentsListController.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CommentsListController : UIViewController {

	IBOutlet UITableView *commentsTableView;

	IBOutlet UIBarButtonItem *syncPostsButton;
	IBOutlet UIBarButtonItem *commentStatusButton;
	
    IBOutlet UIToolbar  *editToolbar;
	UIBarButtonItem *editButtonItem;

	BOOL connectionStatus;
	BOOL editMode;
	BOOL changeEditMode;
}

//@property (nonatomic, retain) NSMutableArray *commentDetails;

- (IBAction)downloadRecentComments:(id)sender;

@end