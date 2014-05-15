#import "WPBlogSelectorButton.h"

@implementation WPBlogSelectorButton

- (void)layoutSubviews {
    
    [super layoutSubviews];
    self.titleLabel.frame = [self titleRectForContentRect:self.bounds];
    self.imageView.frame = [self imageRectForContentRect:self.bounds];
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super imageRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMaxX([self titleRectForContentRect:contentRect]) + self.imageEdgeInsets.left;
    return frame;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super titleRectForContentRect:contentRect];
    frame.size.width = MIN(frame.size.width, CGRectGetWidth(contentRect) - CGRectGetWidth([super imageRectForContentRect:contentRect]) - self.imageEdgeInsets.left - self.imageEdgeInsets.right);
    frame.origin.x = CGRectGetMidX(contentRect) - CGRectGetWidth(frame) / 2.0;
    return frame;
}

@end
