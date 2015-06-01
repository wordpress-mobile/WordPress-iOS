#import <Foundation/Foundation.h>

@interface NSDate (StringFormatting)

/**
 Returns a short localized representation of the date, typically a number and a
 single character suffix for past dates, or prepended with the preposition "In"
 for future dates.
 Examples: 1s, 1d, 1y.  In 1d. In 1y.
 */
- (NSString *)shortString;

@end
