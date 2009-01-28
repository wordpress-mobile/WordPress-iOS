//
//  CommentsListController.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CommentsListController : UIViewController<UITableViewDataSource> {

	IBOutlet UITableView *commentsTableView;

	IBOutlet UIBarButtonItem *syncPostsButton;
	IBOutlet UIBarButtonItem *commentStatusButton;
	
	IBOutlet UIToolbar  *editToolbar; 
	UIBarButtonItem *editButtonItem;
	
	IBOutlet UIBarButtonItem  *approveButton;
	IBOutlet UIBarButtonItem  *unapproveButton;
	IBOutlet UIBarButtonItem  *spamButton;
	IBOutlet UIButton  *deleteButton;

	BOOL connectionStatus;
	BOOL editMode;
	BOOL changeEditMode;

	NSMutableArray *commentsArray;
	NSMutableDictionary *commentsDict;
	NSMutableArray *selectedComments;
}
@property (nonatomic,retain) NSMutableArray *selectedComments;
@property (nonatomic,retain) NSMutableArray *commentsArray;

- (IBAction)downloadRecentComments:(id)sender;
- (IBAction)deleteSelectedComments:(id)sender;
- (IBAction)approveSelectedComments:(id)sender;
- (IBAction)unapproveSelectedComments:(id)sender;
- (IBAction)spamSelectedComments:(id)sender;
@end