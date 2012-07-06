#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "UITableViewActivityCell.h"
#import "EditPostViewController.h"
#import "CPopoverManager.h"
#import "PostAnnotation.h"

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD                    150.0

@class EditPostViewController;
@interface PostSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate, MKReverseGeocoderDelegate> {
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
    EditPostViewController *postDetailViewController;
    NSArray *statusList;
    NSArray *visibilityList;
    NSArray *formatsList;
    UIPickerView *pickerView;
    UIActionSheet *actionSheet;
    UIDatePicker *datePickerView;
    UIPopoverController *popover;
    BOOL isShowingKeyboard;

	/* Geotagging */
	CLLocationManager *locationManager;
	MKReverseGeocoder *reverseGeocoder;
    UITableViewActivityCell *addGeotagTableViewCell;
    IBOutlet UITableViewCell *mapGeotagTableViewCell;
	UITableViewCell *removeGeotagTableViewCell;
	IBOutlet MKMapView *mapView;
	IBOutlet UILabel *addressLabel;
	IBOutlet UILabel *coordinateLabel;
	PostAnnotation *annotation;
	NSString *address;
	BOOL isUpdatingLocation;
    IBOutlet UILabel *visibilityTitleLabel, *statusTitleLabel, *postFormatTitleLabel;
}

@property (nonatomic, assign) EditPostViewController *postDetailViewController;

- (void)reloadData;
- (void)endEditingAction:(id)sender;

@end
