//
//  NSDate+Simperium.m
//  Simperium
//
//  Created by Michael Johnston on 11-06-03.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "NSDate+Simperium.h"

@implementation NSDate(NSDate_Simperium)

- (NSString *)sp_stringBeforeNow {
    // TODO: localize
    NSDate *now = [NSDate date];
    double time = [self timeIntervalSinceDate:now];
    time *= -1;
    if (time < 60) {
        return @"just now";
    } else if (time < 3600) {
        int diff = round(time / 60);
        if (diff == 1) 
            return [NSString stringWithFormat:@"1 minute ago"];
        return [NSString stringWithFormat:@"%d minutes ago", diff];
    } else if (time < 86400) {
        int diff = round(time / 60 / 60);
        if (diff == 1)
            return [NSString stringWithFormat:@"1 hour ago"];
        return [NSString stringWithFormat:@"%d hours ago", diff];
    } else if (time < 604800) {
        int diff = round(time / 60 / 60 / 24);
        if (diff == 1) 
            return [NSString stringWithFormat:@"yesterday"];
        if (diff == 7) 
            return [NSString stringWithFormat:@"last week"];
        return[NSString stringWithFormat:@"%d days ago", diff];
    } else {
        int diff = round(time / 60 / 60 / 24 / 7);
        if (diff == 1)
            return [NSString stringWithFormat:@"last week"];
        return [NSString stringWithFormat:@"%d weeks ago", diff];
    }   
}
@end
