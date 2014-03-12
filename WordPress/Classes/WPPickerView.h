//
//  WPPickerView.h
//  WordPress
//
//  Created by Eric Johnson on 3/12/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPPickerView : UIView

/**
 Block that is called when the picker control changes its value.  For UIDatePicker's
 the result is an NSDate object.  For UIPickers the result is either an NSArray
 representing the selected indexes.
 A value of -1 is returned for components without a selection.
 */
@property (nonatomic, copy) void(^onValueChanged)(id result);

/**
 Block that is called when the picker's done button is tapped. Result is the same
 as the onValueChanged block.
 */
@property (nonatomic, copy) void(^onFinished)(id result);

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
 
 @param startingIndexes Optional. An NSArray of NSNumbers corresponding the starting
 selected indexes in the dataSource.
 */
- (id)initWithDataSource:(NSArray *)dataSource andStartingIndexs:(NSArray *)startingIndexes;

/**
 Returns an array of UIBarButtonItems to show in the toolbar. Flexible spacers will
 be automattically added bewteen buttons.
 */
- (NSArray *)buttonsForToolbar;

@end
