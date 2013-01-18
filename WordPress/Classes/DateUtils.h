//
//  DateUtils.h
//  WordPress
//
//  Created by Danilo Ercoli on 03/02/11.
//  Copyright 2011 WordPress. All rights reserved.
//


@interface DateUtils : NSObject {

}
+ (NSDate *) currentGMTDate;
+ (NSDate *) GMTDateTolocalDate:(NSDate *)gmtDate;
+ (NSDate *) localDateToGMTDate:(NSDate *)localDate;

@end
