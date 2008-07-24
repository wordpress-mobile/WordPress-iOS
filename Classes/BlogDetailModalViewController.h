#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class BlogDataManager, WPSelectionTableViewController;

@interface BlogDetailModalViewController : UIViewController <UITextFieldDelegate> {

	IBOutlet UIBarButtonItem *cancelBlogButton;
	IBOutlet UIBarButtonItem *saveBlogButton;

	IBOutlet UITableView *blogEditTable;
	
	IBOutlet UIButton *removeBlogButton;
	
	IBOutlet UITableViewCell *blogURLTableViewCell;
	IBOutlet UITableViewCell *userNameTableViewCell;
	IBOutlet UITableViewCell *passwordTableViewCell;
	IBOutlet UITableViewCell *noOfPostsTableViewCell;

	IBOutlet UITextField *blogURLTextField;
	IBOutlet UITextField *userNameTextField;
	IBOutlet UITextField *passwordTextField;
	IBOutlet UITextField *noOfPostsTextField;

	IBOutlet UILabel *blogURLLabel;
	IBOutlet UILabel *userNameLabel;
	IBOutlet UILabel *passwordLabel;
	IBOutlet UILabel *noOfPostsLabel;

	bool isModal;
	int mode;	// 0 new, 1 edit

	UITextField *currentEditingTextField;
}

@property (nonatomic, assign) UIBarButtonItem *saveBlogButton;
@property (nonatomic, assign) UIBarButtonItem *cancelBlogButton;
@property (nonatomic, assign) UIButton *removeBlogButton;
@property (nonatomic, assign) UITextField *currentEditingTextField;
@property (nonatomic, assign) UITableView *blogEditTable;

@property (nonatomic)	int mode;

@property (nonatomic, assign) bool isModal;

- (IBAction)saveBlog:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)removeBlog:(id)sender;
- (void)updateBlog:(id)sender;

- (void)refreshBlogEdit;
- (void)refreshBlogCompose;

@end
