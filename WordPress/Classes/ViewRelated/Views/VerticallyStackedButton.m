#import "VerticallyStackedButton.h"

static const CGFloat ImageLabelSeparation = 2.f;

@implementation VerticallyStackedButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self.titleLabel setLineBreakMode: NSLineBreakByTruncatingTail];
        [self setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateNormal];
        [self setTitleColor:[WPStyleGuide midnightBlue] forState:UIControlStateHighlighted];
        [self setTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.titleLabel setFont:[WPStyleGuide labelFontNormal]];
    
    CGSize imageSize    = self.imageView.image.size;
    CGSize maxTitleSize = CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - (imageSize.height));
    CGSize titleSize    = [self.titleLabel sizeThatFits:maxTitleSize];
    
    self.imageView.frame = CGRectIntegral(CGRectMake((CGRectGetWidth(self.frame) - imageSize.width) * 0.5f,
                                                     (CGRectGetHeight(self.frame) - (imageSize.height + titleSize.height)) * 0.5f,
                                                     imageSize.width,
                                                     imageSize.height));
    
    self.titleLabel.frame = CGRectIntegral(CGRectMake((CGRectGetWidth(self.frame) - titleSize.width) * 0.5f,
                                                      CGRectGetMaxY(self.imageView.frame) + ImageLabelSeparation,
                                                      titleSize.width,
                                                      titleSize.height));
    
    self.contentEdgeInsets = UIEdgeInsetsMake(5.0f, 0.0f, 5.0f, 0.0f);
}

@end
