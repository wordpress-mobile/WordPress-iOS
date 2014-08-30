#import "WPLegacyKeyboardToolbarButtonItem.h"
#import <QuartzCore/QuartzCore.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>

@implementation WPLegacyKeyboardToolbarButtonItem
@synthesize actionTag, actionName;


+ (id)button {
    return [WPLegacyKeyboardToolbarButtonItem buttonWithType:UIButtonTypeCustom];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide keyboardColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)setImageName:(NSString *)imageName {
    [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", imageName]] forState:UIControlStateNormal];
    self.imageView.contentMode = UIViewContentModeCenter;
}

- (void)setImageName:(NSString *)imageName withColor:(UIColor *)tintColor highlightColor:(UIColor *)highlightColor {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", imageName]];
    if (tintColor) {
        image = [self createImage:image withColor:tintColor];
    }
    [self setImage:image forState:UIControlStateNormal];

    if (highlightColor) {
        image = [self createImage:image withColor:highlightColor];
        [self setImage:image forState:UIControlStateHighlighted];
    }
    self.imageView.contentMode = UIViewContentModeCenter;
}

- (UIImage *)createImage:(UIImage *)image withColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return coloredImage;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        [self setBackgroundColor:[WPStyleGuide wordPressBlue]];
    } else {
        [self setBackgroundColor:[WPStyleGuide keyboardColor]];
    }
}


@end
