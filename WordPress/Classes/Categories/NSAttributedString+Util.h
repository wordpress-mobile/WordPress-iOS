#import <Foundation/Foundation.h>



@interface NSMutableAttributedString (Util)

- (void)applyAttributesToQuotes:(NSDictionary *)attributes;
- (void)applyAttributes:(NSDictionary *)attributes untilKeywords:(NSArray *)keywords;

@end
