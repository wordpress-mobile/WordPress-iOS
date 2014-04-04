#import "UIImage+Util.h"

@implementation UIImage (Util)

+ (UIImage *)imageWithColor:(UIColor *)color {
    return [self imageWithColor:color havingSize:CGSizeMake(1.0f, 1.0f)];
}

+ (UIImage *)imageWithColor:(UIColor *)color havingSize:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
