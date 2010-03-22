#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "LocateXMLRPCViewController.h"

@class BlogDataManager, WPSelectionTableViewController, BlogHTTPAuthenticationViewController;

@interface EditBlogViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UIBarButtonItem *cancelBlogButton;
    IBOutlet UIBarButtonItem *saveBlogButton;

    IBOutlet UITableView *blogEditTable;

    IBOutlet UITableViewCell *blogURLTableViewCell;
    IBOutlet UITableViewCell *userNameTableViewCell;
    IBOutlet UITableViewCell *passwordTableViewCell;
    IBOutlet UITableViewCell *noOfPostsTableViewCell;
	IBOutlet UITableViewCell *blogHTTPAuthTableViewCell;
	IBOutlet UITableViewCell *geotaggingTableViewCell;

    IBOutlet UITextField *blogURLTextField;
    IBOutlet UITextField *userNameTextField;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UITextField *noOfPostsTextField;
	IBOutlet UITextField *blogHTTPAuthTextField;

    IBOutlet UILabel *resizePhotoLabel;
    IBOutlet UITableViewCell *resizePhotoHintTableViewCell;
    IBOutlet UILabel *resizePhotoHintLabel;
    IBOutlet UITableViewCell *resizePhotoViewCell;
    IBOutlet UISwitch *resizePhotoControl;
    IBOutlet UISwitch *geotaggingSwitch;

    IBOutlet UILabel *blogURLLabel;
    IBOutlet UILabel *userNameLabel;
    IBOutlet UILabel *passwordLabel;
    IBOutlet UILabel *noOfPostsLabel;
    IBOutlet UILabel *geotaggingLabel;

    IBOutlet UIView *validationView;

	IBOutlet BlogHTTPAuthenticationViewController *blogHTTPAuthViewController;

    NSDictionary *currentBlog;
	
	
}

@property (nonatomic, assign) UITableView *blogEditTable;
@property (nonatomic, retain) UIView *validationView;

@property (nonatomic, retain) NSDictionary *currentBlog;
@property (nonatomic, retain) UITextField *blogURLTextField;


- (IBAction)saveBlog:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)hideSpinner;
- (void)showLocateXMLRPCModalViewWithAnimation:(BOOL)animate;
- (void)setAuthEnabledText:(BOOL)authEnabled;
- (void)changeGeotaggingSetting;

@end
