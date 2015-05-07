#import <Foundation/Foundation.h>

@interface NSDate (StringFormatting)

/**
 Returns a short localized representation of the date, typically a number and a
 single character suffix for past dates, or prepended with the preposition "In"
 for future dates.
 Examples: 1s, 1d, 1y.  In 1d. In 1y.
 */
- (NSString *)shortString;

/**
 Returns a short localized representation of a date in form of an article or number,
 the name of a calendar unit (day, month, year) and the word "ago".
 Examples A day ago.  3 days ago. 5 months ago. A year ago.
 */
- (NSString *)conciseString;

/**
 Returns the internally used look-up index for a concise string for the specified date.
 @param date A date for which to find a concise string index. If date is nil the
 current date is asumed.
 @return The integer value of the index.
 */
+ (NSInteger)indexForConciseStringForDate:(NSDate *)date;

/**
 Returns the concise string for the specified index, or an empty string if there
 is no matching index. 
 
 @param index The integer value for the look-up index of concise string.
 @return The concise string representation.
 */
+ (NSString *)conciseStringFromIndex:(NSInteger)index;

@end
