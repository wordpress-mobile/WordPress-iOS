#import "VerticallyStackedButton.h"

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
    
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(self.frame.size.width, self.frame.size.height - (imageSize.height))];
    self.imageView.frame = CGRectMake((self.frame.size.width - imageSize.width) / 2,
                                      (self.frame.size.height - (imageSize.height + titleSize.height)) / 2, imageSize.width, imageSize.height);
    
    self.titleLabel.frame = CGRectMake((self.frame.size.width - titleSize.width) / 2,
                                       CGRectGetMaxY(self.imageView.frame), titleSize.width, titleSize.height);
    
    self.contentEdgeInsets = UIEdgeInsetsMake(5.0f, 0.0f, 5.0f, 0.0f);
}

@end
