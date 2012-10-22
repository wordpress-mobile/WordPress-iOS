#import <UIKit/UIKit.h>
#import "WPSegmentedSelectionTableViewController.h"
#import "Category.h"
#import "Blog.h"

#define kParentCategoriesContext ((void *)999)

@interface WPAddCategoryViewController : UIViewController {
    IBOutlet UITableView *catTableView;

    IBOutlet UITextField *newCatNameField;
    IBOutlet UITextField *parentCatNameField;
    IBOutlet UILabel *parentCatNameLabel;

    IBOutlet UITableViewCell *newCatNameCell;
    IBOutlet UITableViewCell *parentCatNameCell;

    IBOutlet UIBarButtonItem *saveButtonItem;
    IBOutlet UIBarButtonItem *cancelButtonItem;

    Category *parentCat;
}
@property (nonatomic, strong) Blog *blog;

- (IBAction)cancelAddCategory:(id)sender;
- (IBAction)saveAddCategory:(id)sender;
- (void)removeProgressIndicator;

@end
