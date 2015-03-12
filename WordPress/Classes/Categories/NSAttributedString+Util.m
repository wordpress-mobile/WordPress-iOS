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

- (void)applyFont:(UIFont *)font
{
    NSParameterAssert(font);
    
    NSRange range = NSMakeRange(0, self.length);
    [self addAttribute:NSFontAttributeName value:font range:range];
}

- (void)applyForegroundColor:(UIColor *)color
{
    NSParameterAssert(color);
    
    NSRange range = NSMakeRange(0, self.length);
    [self addAttribute:NSForegroundColorAttributeName value:color range:range];
}

- (void)applyUnderline
{
    NSRange range = NSMakeRange(0, self.length);
    [self addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
}

@end
