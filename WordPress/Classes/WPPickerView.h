#import <UIKit/UIKit.h>

@protocol WPPickerViewDelegate;

@interface WPPickerView : UIView

@property (nonatomic, weak) id<WPPickerViewDelegate> delegate;

/**
 Create a WPPickerViewController with a UIDatePicker starting at the specified date.
 
 @param date The currently selected date.
 */
- (id)initWithDate:(NSDate *)date;

/**
 Create a WPPickerViewController with a UIPicker using the provided array as its
 datasource.
 
 @param dataSource Accepts an NSArray of NSArrays of NSStrings. The picker displays
 one compontent for each array of strings.
 
 @param startingIndexes Optional. An NSIndexPath corresponding the starting
 selected indexes in the dataSource.
 */
- (id)initWithDataSource:(NSArray *)dataSource andStartingIndexes:(NSIndexPath *)indexPath;

/**
 Returns an array of UIBarButtonItems to show in the toolbar. Flexible spacers will
 be automattically added bewteen buttons.
 */
- (NSArray *)buttonsForToolbar;

/**
 Returns the starting value assigned to the control, either an NSDate object or 
 an NSIndexPath.
 */
- (id)startingValue;

/**
 Returns the current value of the control, either an NSDate object or an NSIndexPath.
 */
- (id)currentValue;

@end

@protocol WPPickerViewDelegate <NSObject>

@optional

/**
 Called on the delegate when the picker control changes its value.  For UIDatePicker's
 the result is an NSDate object.  For UIPickers the result is an NSIndexPath.
 A value of -1 is returned for components without a selection.
 */
- (void)pickerView:(WPPickerView *)pickerView didChangeValue:(id)value;

/**
 Called on the delegate when the picker's done button is tapped. Result is the same
 as pickerView:didChangeValue:.
 */
- (void)pickerView:(WPPickerView *)pickerView didFinishWithValue:(id)value;

@end
