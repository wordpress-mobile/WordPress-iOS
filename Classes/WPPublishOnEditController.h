#import <UIKit/UIKit.h>

@class WPPostSettingsController;

@interface WPPublishOnEditController : UIViewController {
    IBOutlet UILabel *dateLabel;
    IBOutlet UIDatePicker *datePicker;
    NSDateFormatter *dateFormatter;

    WPPostSettingsController *settingController;
}

@property (nonatomic, assign) WPPostSettingsController *settingController;

- (NSDate *)currentSelectedDate;
- (IBAction)datePickerValueChanged:(id)sender;

@end
