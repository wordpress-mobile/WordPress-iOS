//
//  DateRangePickerView.h
//  WordPress
//
//  Created by DX074-XL on 2013-09-16.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InputViewButton;

@interface DateRangePickerView : UIView <UITextFieldDelegate>

@property (nonatomic, strong) InputViewButton *startDate;
@property (nonatomic, strong) InputViewButton *endDate;

- (void)setDateRangeMin:(NSDate*)min andMax:(NSDate*)max;

@end
