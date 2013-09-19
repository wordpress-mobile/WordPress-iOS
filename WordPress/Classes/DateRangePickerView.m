//
//  DateRangePickerView.m
//  WordPress
//
//  Created by DX074-XL on 2013-09-16.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "DateRangePickerView.h"

@interface DateRangePickerView ()

@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UIDatePicker *endDatePicker;
@property (nonatomic, weak) UIView *currentFirstResponder;

@end

@implementation DateRangePickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    self.backgroundColor = [WPStyleGuide allTAllShadeGrey];
    
    UILabel *fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, self.frame.size.height)];
    fromLabel.text = NSLocalizedString(@"FROM:", @"");
    fromLabel.font = [WPStyleGuide subtitleFont];
    fromLabel.textColor = [UIColor whiteColor];
    fromLabel.backgroundColor = [UIColor clearColor];
    [fromLabel sizeToFit];
    fromLabel.frame = (CGRect) {
        .size = fromLabel.frame.size,
        .origin = CGPointMake(fromLabel.frame.origin.x+5, (self.frame.size.height - fromLabel.frame.size.height)/2)
    };
    [self addSubview:fromLabel];

    //Create Date Pickers
    self.startDatePicker = [[UIDatePicker alloc] init];
    self.startDatePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [self.startDatePicker setDatePickerMode:UIDatePickerModeDate];
    self.startDatePicker.frame = CGRectMake(0,0,0,100);
    
    self.endDatePicker = [[UIDatePicker alloc] init];
    self.endDatePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [self.endDatePicker setDatePickerMode:UIDatePickerModeDate];
    self.endDatePicker.frame = CGRectMake(0, 0, 0, 100);

    
    //Create Date Textfields
    self.startDate = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(fromLabel.frame), 0, self.bounds.size.width/2 - fromLabel.frame.size.width, 44.0f)];
    self.startDate.delegate = self;
    [self.startDate setTextColor:[UIColor whiteColor]];
    [self.startDate setFont:[WPStyleGuide subtitleFont]];
    [self.startDate setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [self.startDate setTag:100];
    self.startDate.adjustsFontSizeToFitWidth = YES;
    self.startDate.clearButtonMode = UITextFieldViewModeAlways;
    self.startDate.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    self.startDate.inputView = self.startDatePicker;
    self.startDate.textAlignment = NSTextAlignmentCenter;
    
    UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_startDate.frame), fromLabel.frame.origin.y, 0, self.frame.size.height)];
    toLabel.text = NSLocalizedString(@"TO:", @"");
    toLabel.textColor = fromLabel.textColor;
    toLabel.font = fromLabel.font;
    toLabel.backgroundColor = fromLabel.backgroundColor;
    [toLabel sizeToFit];
    toLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:toLabel];
    
    self.endDate = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(toLabel.frame), 0, self.frame.size.width - CGRectGetMaxX(toLabel.frame), 44.0f)];
    self.endDate.delegate = self;
    [self.endDate setTextColor:[UIColor whiteColor]];
    [self.endDate setFont:[WPStyleGuide subtitleFont]];
    [self.endDate setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [self.endDate setTag:101];
    self.endDate.adjustsFontSizeToFitWidth = YES;
    self.endDate.clearButtonMode = UITextFieldViewModeAlways;
    self.endDate.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    self.endDate.inputView = self.endDatePicker;
    self.endDate.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:self.startDate];
    [self addSubview:self.endDate];
    
}

- (void)setDateRangeMin:(NSDate*)min andMax:(NSDate*)max {
    if (min && max) {
        self.startDatePicker.minimumDate = min;
        self.endDatePicker.maximumDate = [NSDate date];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        if ([self.startDate.text isEqualToString:@""]) {
            _startDate.text = [formatter stringFromDate:_startDatePicker.minimumDate];
            self.startDatePicker.date = min;
        }
        if ([self.endDate.text isEqualToString:@""]) {
            _endDate.text = [formatter stringFromDate:_endDatePicker.maximumDate];
            self.endDatePicker.date = max;
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    [self.endDatePicker setMinimumDate:self.startDatePicker.date];
    [self.startDatePicker setMaximumDate:self.endDatePicker.date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    formatter.dateFormat = @"yyyy-MM-dd";
    
    if (textField.tag == 100) {
        if ([_startDate.text isEqualToString:@""]) {
            _startDate.text = [formatter stringFromDate:_startDatePicker.minimumDate];
        } else {
            _startDate.text = [formatter stringFromDate:_startDatePicker.date];
        }
    } else {
        if ([_endDate.text isEqualToString:@""]) {
            _endDate.text = [formatter stringFromDate:_endDatePicker.maximumDate];
        } else {
            _endDate.text = [formatter stringFromDate:_endDatePicker.date];
        }
    }
}

- (BOOL)isFirstResponder {
    return _startDate.isFirstResponder || _endDate.isFirstResponder;
}

- (BOOL)resignFirstResponder {
    _currentFirstResponder = nil;
    if (_startDate.isFirstResponder) {
        _currentFirstResponder = _startDate;
        return [_startDate resignFirstResponder];
    }
    _currentFirstResponder = _endDate;
    return [_endDate resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [_currentFirstResponder becomeFirstResponder];
}

@end
