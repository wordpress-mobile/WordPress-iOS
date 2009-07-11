#import <UIKit/UIKit.h>
#import "WPSelectionTableViewController.h"
#import "BlogDataManager.h"

#define kParentCategoriesContext ((void *)999)

@interface WPAddCategoryViewController : UIViewController {
    IBOutlet UITableView *catTableView;

    IBOutlet UITextField *newCatNameField;
    IBOutlet UITextField *parentCatNameField;

    IBOutlet UITableViewCell *newCatNameCell;
    IBOutlet UITableViewCell *parentCatNameCell;

    IBOutlet UIBarButtonItem *saveButtonItem;
    IBOutlet UIBarButtonItem *cancelButtonItem;
}

- (IBAction)cancelAddCategory:(id)sender;
- (IBAction)saveAddCategory:(id)sender;

@end
