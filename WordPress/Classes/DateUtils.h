//
//  DateUtils.h
//  WordPress
//
//  Created by Danilo Ercoli on 03/02/11.
//  Copyright 2011 WordPress. All rights reserved.
//


@interface DateUtils : NSObject

+ (NSDate *)dateFromISOString:(NSString *)isoString;
+ (NSString *)isoStringFromDate:(NSDate *)date;

@end
