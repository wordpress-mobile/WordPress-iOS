//
//  NSDate+StringFormatting.m
//  WordPress
//
//  Created by Michael Johnston on 11/17/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NSDate+StringFormatting.h"

@implementation NSDate (StringFormatting)

- (NSString *)shortString {
    NSString *shortString;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                   fromDate:self
                                                     toDate:[NSDate date]
                                                    options:0];

    if (dateComponents.day > 0) {
        shortString = [NSString stringWithFormat:@"%i%@", dateComponents.day, NSLocalizedString(@"d", @"Days single character abbreviation")];
    } else if (dateComponents.hour > 0) {
        shortString = [NSString stringWithFormat:@"%i%@", dateComponents.hour, NSLocalizedString(@"h", @"Hours single character abbreviation")];
    } else if (dateComponents.minute > 0) {
        shortString = [NSString stringWithFormat:@"%i%@", dateComponents.minute, NSLocalizedString(@"m", @"Minutes single character abbreviation")];
    } else {
        shortString = [NSString stringWithFormat:@"%i%@", dateComponents.second, NSLocalizedString(@"s", @"Seconds single character abbreviation")];
    }

    return shortString;
}

@end
