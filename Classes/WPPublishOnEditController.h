#import <UIKit/UIKit.h>



@class PostSettingsViewController;

@interface WPPublishOnEditController : UIViewController {
    IBOutlet UILabel *dateLabel;
    IBOutlet UIDatePicker *datePicker;
    NSDateFormatter *dateFormatter;

    PostSettingsViewController *settingController;
}

@property (nonatomic, assign) PostSettingsViewController *settingController;


- (NSDate *)currentSelectedDate;
- (IBAction)datePickerValueChanged:(id)sender;
- (void) moveDatePickerUp;
- (void) moveDatePickerDown;

@end
