#import "PostMetaButton.h"

@implementation PostMetaButton

- (CGSize)intrinsicContentSize
{
    CGSize newSize = [super intrinsicContentSize];
    newSize.width += (self.imageEdgeInsets.left + self.imageEdgeInsets.right);
    newSize.width += (self.titleEdgeInsets.left + self.titleEdgeInsets.right);
    return newSize;
}

@end
