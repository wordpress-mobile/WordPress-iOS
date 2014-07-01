#import "NSAttributedString+Util.h"
#import "NSScanner+Helpers.h"



@implementation NSMutableAttributedString (Util)

- (void)applyAttributesToQuotes:(NSDictionary *)attributes
{
    NSString *rawText   = self.string;
    NSScanner *scanner  = [NSScanner scannerWithString:rawText];
    NSArray *quotes     = [scanner scanQuotedText];
    
    for (NSString *quote in quotes) {
        NSRange itemRange = [rawText rangeOfString:quote];
        if (itemRange.location != NSNotFound) {
            [self addAttributes:attributes range:itemRange];
        }
    }
}

- (void)applyAttributes:(NSDictionary *)attributes untilKeywords:(NSArray *)keywords
{
    NSString *rawText = self.string;
    
    for (NSString *keyword in keywords) {
        NSRange keywordRange = [rawText rangeOfString:keyword];
        if (keywordRange.location != NSNotFound) {
            [self addAttributes:attributes range:NSMakeRange(0, keywordRange.location)];
            break;
        }
    }
}

@end
