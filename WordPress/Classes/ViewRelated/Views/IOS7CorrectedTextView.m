// Original Gist https://gist.github.com/agiletortoise/a24ccbf2d33aafb2abc1
// Discussion: https://devforums.apple.com/message/889840

#import "IOS7CorrectedTextView.h"

@implementation IOS7CorrectedTextView

- (CGRect)firstRectForRange:(UITextRange *)range
{
    CGRect r1= [self caretRectForPosition:[self positionWithinRange:range farthestInDirection:UITextLayoutDirectionRight]];
    CGRect r2= [self caretRectForPosition:[self positionWithinRange:range farthestInDirection:UITextLayoutDirectionLeft]];
    return CGRectUnion(r1,r2);
}

- (NSUInteger)characterIndexForPoint:(CGPoint)point
{
    if (self.text.length == 0) {
        return 0;
    }

    CGRect r1;
    if ([[self.text substringFromIndex:self.text.length-1] isEqualToString:@"\n"]) {
        r1 = [super caretRectForPosition:[super positionFromPosition:self.endOfDocument offset:-1]];
        CGRect sr = [super caretRectForPosition:[super positionFromPosition:self.beginningOfDocument offset:0]];
        r1.origin.x = sr.origin.x;
        r1.origin.y += self.font.lineHeight;
    } else {
        r1 = [super caretRectForPosition:[super positionFromPosition:self.endOfDocument offset:0]];
    }

    if ((point.x > r1.origin.x && point.y >= r1.origin.y) || point.y >= r1.origin.y+r1.size.height) {
        return [super offsetFromPosition:self.beginningOfDocument toPosition:self.endOfDocument];
    }

    CGFloat fraction;
    NSUInteger index = [self.textStorage.layoutManagers[0] characterIndexForPoint:point inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:&fraction];

    return index;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    point.y -= self.textContainerInset.top;
    point.y -= self.font.lineHeight/2;
    NSUInteger index = [self characterIndexForPoint:point];
    UITextPosition *pos = [self positionFromPosition:self.beginningOfDocument offset:index];
    return pos;
}

- (void)scrollRangeToVisible:(NSRange)range
{
    [super scrollRangeToVisible:range];

    if (self.layoutManager.extraLineFragmentTextContainer != nil && self.selectedRange.location == range.location) {
        CGRect caretRect = [self caretRectForPosition:self.selectedTextRange.start];
        [self scrollRectToVisible:caretRect animated:YES];
    }
}

@end
