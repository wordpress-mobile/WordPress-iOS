#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "WPTableViewActivityCell.h"
#import "PostAnnotation.h"

#import "UIImageView+AFNetworking.h"
#import "EditPostViewController.h"

@class EditPostViewController;
@interface PostSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) EditPostViewController *postDetailViewController;
@property (nonatomic, strong) NSString *statsPrefix;

- (id)initWithPost:(AbstractPost *)aPost;

- (void)reloadData;
- (void)endEditingAction:(id)sender;
- (void)featuredImageUploadFailed: (NSNotification *)notificationInfo;
- (void)featuredImageUploadSucceeded: (NSNotification *)notificationInfo;
- (void)showFeaturedImageUploader: (NSNotification *)notificationInfo;
@end
