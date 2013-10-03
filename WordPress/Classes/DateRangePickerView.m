//
//  DateRangePickerView.m
//  WordPress
//
//  Created by DX074-XL on 2013-09-16.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "DateRangePickerView.h"
#import "InputViewButton.h"

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
    
    UILabel *fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 0, self.frame.size.height)];
    fromLabel.text = NSLocalizedString(@"FROM", @"");
    fromLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
    fromLabel.textColor = [WPStyleGuide whisperGrey];
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
    [self.startDatePicker addTarget:self action:@selector(startDatePicked) forControlEvents:UIControlEventValueChanged];

    self.endDatePicker = [[UIDatePicker alloc] init];
    self.endDatePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [self.endDatePicker setDatePickerMode:UIDatePickerModeDate];
    self.endDatePicker.frame = CGRectMake(0, 0, 0, 100);
    [self.endDatePicker addTarget:self action:@selector(endDatePicked) forControlEvents:UIControlEventValueChanged];

    
    //Create Date Textfields
    self.startDate = [[InputViewButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(fromLabel.frame) + 10, 10, self.bounds.size.width/2 - fromLabel.frame.size.width - 20, 24.0f)];
    [self.startDate.layer setCornerRadius:4.0f];
    [self.startDate.titleLabel setTextColor:[WPStyleGuide itsEverywhereGrey]];
    [self.startDate.titleLabel setFont:[WPStyleGuide tableviewSectionHeaderFont]];
    [self.startDate setBackgroundColor:[WPStyleGuide whisperGrey]];
    [self.startDate addTarget:self action:@selector(showStartDatePicker) forControlEvents:UIControlEventTouchUpInside];
    self.startDate.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.startDate.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    self.startDate.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.startDate.inputView = self.startDatePicker;
    
    
    UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_startDate.frame) + 10, fromLabel.frame.origin.y, 0, self.frame.size.height)];
    toLabel.text = NSLocalizedString(@"TO", @"");
    toLabel.textColor = [WPStyleGuide whisperGrey];
    toLabel.font = fromLabel.font;
    toLabel.backgroundColor = fromLabel.backgroundColor;
    [toLabel sizeToFit];
    toLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:toLabel];
    
    self.endDate = [[InputViewButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(toLabel.frame) + 10, 10, self.frame.size.width - CGRectGetMaxX(toLabel.frame) - 20, 24.0f)];
    [self.endDate.titleLabel setTextColor:[WPStyleGuide itsEverywhereGrey]];
    [self.endDate.layer setCornerRadius:4.0f];
    [self.endDate.titleLabel setFont:[WPStyleGuide tableviewSectionHeaderFont]];
    [self.endDate setBackgroundColor:[WPStyleGuide whisperGrey]];
    [self.endDate addTarget:self action:@selector(showEndDatePicker) forControlEvents:UIControlEventTouchUpInside];
    self.endDate.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.endDate.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    self.endDate.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.endDate.inputView = self.endDatePicker;
    
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
        if (!self.startDate.titleLabel.text) {
            [_startDate setTitle:[formatter stringFromDate:_startDatePicker.minimumDate] forState:UIControlStateNormal];
            self.startDatePicker.date = min;
        }
        if (!self.endDate.titleLabel.text) {
            [_endDate setTitle:[formatter stringFromDate:_endDatePicker.maximumDate] forState:UIControlStateNormal];
        }
    }
}

- (void)showStartDatePicker {
    [self.startDate becomeFirstResponder];
}

- (void)showEndDatePicker {
    [self.endDate becomeFirstResponder];
}

- (void)startDatePicked {
    [self.endDatePicker setMinimumDate:self.startDatePicker.date];
    [self.startDatePicker setMaximumDate:self.endDatePicker.date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    formatter.dateFormat = @"yyyy-MM-dd";
    [_startDate setTitle:[formatter stringFromDate:_startDatePicker.date] forState:UIControlStateNormal];
}

- (void)endDatePicked {
    [self.endDatePicker setMinimumDate:self.startDatePicker.date];
    [self.startDatePicker setMaximumDate:self.endDatePicker.date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    formatter.dateFormat = @"yyyy-MM-dd";
    [_endDate setTitle:[formatter stringFromDate:_endDatePicker.date] forState:UIControlStateNormal];
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