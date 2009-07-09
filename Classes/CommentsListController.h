//
//  CommentsListController.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import <Foundation/Foundation.h>

#import "CommentsTableViewDelegate.h"
#import "RefreshButtonView.h"

@interface CommentsListController : UIViewController <UITableViewDataSource, CommentsTableViewDelegate> {
	IBOutlet UITableView *commentsTableView;
	
	IBOutlet UIToolbar *editToolbar; 
	UIBarButtonItem *editButtonItem;
	RefreshButtonView *refreshButton;
	
	IBOutlet UIBarButtonItem *approveButton;
	IBOutlet UIBarButtonItem *unapproveButton;
	IBOutlet UIBarButtonItem *spamButton;
	IBOutlet UIButton *deleteButton;
    
	BOOL connectionStatus;
	BOOL editing;
    
	NSMutableArray *commentsArray;
	NSMutableDictionary *commentsDict;
	NSMutableArray *selectedComments;
}

@property (readonly) UIBarButtonItem *editButtonItem;
@property (nonatomic, retain) NSMutableArray *selectedComments;
@property (nonatomic, retain) NSMutableArray *commentsArray;

- (IBAction)deleteSelectedComments:(id)sender;
- (IBAction)approveSelectedComments:(id)sender;
- (IBAction)unapproveSelectedComments:(id)sender;
- (IBAction)spamSelectedComments:(id)sender;

@end
