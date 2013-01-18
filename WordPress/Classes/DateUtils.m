//
//  DateUtils.m
//  WordPress
//
//  Created by Danilo Ercoli on 03/02/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "DateUtils.h"


@implementation DateUtils

+ (NSDate *) currentGMTDate {
	NSDate *currentLocalDate = [NSDate date];
	return [DateUtils localDateToGMTDate:currentLocalDate];
}

+ (NSDate *) localDateToGMTDate:(NSDate *)localDate {
 	NSTimeZone* sourceTimeZone = [NSTimeZone systemTimeZone]; 
	NSTimeZone* destinationTimeZone= [NSTimeZone timeZoneWithAbbreviation:@"GMT"]; 
	NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:localDate]; 
	NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:localDate]; 
	NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset; 
	return [[NSDate alloc] initWithTimeInterval:interval sinceDate:localDate];
}

+ (NSDate *) GMTDateTolocalDate:(NSDate *)gmtDate {
	NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"]; 
 	NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone]; 
	NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:gmtDate]; 
	NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:gmtDate]; 
	NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset; 
	return [[NSDate alloc] initWithTimeInterval:interval sinceDate:gmtDate];
}


@end
