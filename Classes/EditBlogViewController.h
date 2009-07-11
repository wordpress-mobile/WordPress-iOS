#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class BlogDataManager, WPSelectionTableViewController;

@interface EditBlogViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UIBarButtonItem *cancelBlogButton;
    IBOutlet UIBarButtonItem *saveBlogButton;

    IBOutlet UITableView *blogEditTable;

    IBOutlet UITableViewCell *blogURLTableViewCell;
    IBOutlet UITableViewCell *userNameTableViewCell;
    IBOutlet UITableViewCell *passwordTableViewCell;
    IBOutlet UITableViewCell *noOfPostsTableViewCell;

    IBOutlet UITextField *blogURLTextField;
    IBOutlet UITextField *userNameTextField;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UITextField *noOfPostsTextField;

    IBOutlet UILabel *resizePhotoLabel;
    IBOutlet UITableViewCell *resizePhotoHintTableViewCell;
    IBOutlet UILabel *resizePhotoHintLabel;
    IBOutlet UITableViewCell *resizePhotoViewCell;
    IBOutlet UISwitch *resizePhotoControl;

    IBOutlet UILabel *blogURLLabel;
    IBOutlet UILabel *userNameLabel;
    IBOutlet UILabel *passwordLabel;
    IBOutlet UILabel *noOfPostsLabel;

    IBOutlet UIView *validationView;

    NSDictionary *currentBlog;
}

@property (nonatomic, assign) UITableView *blogEditTable;
@property (nonatomic, retain) UIView *validationView;

@property (nonatomic, retain) NSDictionary *currentBlog;

- (IBAction)saveBlog:(id)sender;
- (IBAction)cancel:(id)sender;

@end
