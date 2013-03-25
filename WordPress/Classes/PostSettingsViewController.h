
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <MTZoomWindow/MTZoomWindow.h>
#import <UIKit/UIKit.h>

#import "CPopoverManager.h"
#import "EditPostViewController.h"
#import "PostAnnotation.h"
#import "UIImageView+AFNetworking.h"
#import "UITableViewActivityCell.h"

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD                    150.0

@class EditPostViewController;
@interface PostSettingsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate, UIActionSheetDelegate> {

    IBOutlet UITableView *tableView;
    IBOutlet UITableViewCell *statusTableViewCell;
    IBOutlet UITableViewCell *visibilityTableViewCell;
    IBOutlet UITableViewCell *publishOnTableViewCell;
    IBOutlet UITableViewCell *postFormatTableViewCell;
    IBOutlet UILabel *statusLabel;
    IBOutlet UILabel *visibilityLabel;
    IBOutlet UILabel *postFormatLabel;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UILabel *publishOnLabel;
    IBOutlet UILabel *publishOnDateLabel;
    EditPostViewController *__weak postDetailViewController;
    NSArray *statusList;
    NSArray *visibilityList;
    NSArray *formatsList;
    UIPickerView *pickerView;
    UIActionSheet *actionSheet;
    UIDatePicker *datePickerView;
    UIPopoverController *popover;
    BOOL isShowingKeyboard, blogSupportsFeaturedImage;

	/* Geotagging */
	CLLocationManager *locationManager;
    CLGeocoder *reverseGeocoder;
    UITableViewActivityCell *addGeotagTableViewCell;
    IBOutlet UITableViewCell *mapGeotagTableViewCell;
	UITableViewCell *removeGeotagTableViewCell;
	IBOutlet MKMapView *mapView;
	IBOutlet UILabel *addressLabel;
	IBOutlet UILabel *coordinateLabel;
	PostAnnotation *annotation;
	NSString *address;
	BOOL isUpdatingLocation, isUploadingFeaturedImage;
    IBOutlet UILabel *visibilityTitleLabel, *statusTitleLabel, *postFormatTitleLabel, *featuredImageLabel;
    IBOutlet UIImageView *featuredImageView;
    UITapGestureRecognizer *tapRecognizerForFeaturedImage;
    IBOutlet UITableViewCell *featuredImageTableViewCell;
    IBOutlet UIActivityIndicatorView *featuredImageSpinner;
}

@property (nonatomic, weak) EditPostViewController *postDetailViewController;
@property (nonatomic, strong) IBOutlet UITableViewCell *postFormatTableViewCell;

- (id)initWithPost:(AbstractPost *)aPost;

- (void)reloadData;
- (void)endEditingAction:(id)sender;
- (UITableViewCell*) getGeolactionCellWithIndexPath: (NSIndexPath*)indexPath;
- (void)featuredImageUploadFailed: (NSNotification *)notificationInfo;
- (void)featuredImageUploadSucceeded: (NSNotification *)notificationInfo;
- (void)showFeaturedImageUploader: (NSNotification *)notificationInfo;

@end
