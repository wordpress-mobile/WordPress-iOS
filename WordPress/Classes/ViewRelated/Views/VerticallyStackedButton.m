#import "VerticallyStackedButton.h"

@implementation VerticallyStackedButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self.titleLabel setLineBreakMode: NSLineBreakByTruncatingTail];
        [self setTitleColor:[WPStyleGuide littleEddieGrey] forState:UIControlStateNormal];
        [self setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateHighlighted];
        [self setTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.titleLabel setFont:[WPStyleGuide labelFontNormal]];
    
    CGFloat spacing = 1.0f;
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(self.frame.size.width, self.frame.size.height - (imageSize.height + spacing))];
    self.imageView.frame = CGRectMake((self.frame.size.width - imageSize.width) / 2, (self.frame.size.height - (imageSize.height+spacing+titleSize.height)) / 2, imageSize.width, imageSize.height);
    self.titleLabel.frame = CGRectMake((self.frame.size.width - titleSize.width) / 2, CGRectGetMaxY(self.imageView.frame)+spacing, titleSize.width, titleSize.height);
}

@end
