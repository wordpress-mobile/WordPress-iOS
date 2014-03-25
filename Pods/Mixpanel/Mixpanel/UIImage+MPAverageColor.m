#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIImage+MPAverageColor.h"

@implementation UIImage (MPAverageColor)

- (UIColor *)mp_averageColor
{
	CGSize size = {1, 1};
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
	[self drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
	uint8_t *data = CGBitmapContextGetData(ctx);
	UIColor *color = [UIColor colorWithRed:data[2] / 255.0f
									 green:data[1] / 255.0f
									  blue:data[0] / 255.0f
									 alpha:1];
	UIGraphicsEndImageContext();
	return color;
}

- (UIColor *)mp_importantColor
{
    UIGraphicsBeginImageContext(self.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [self drawInRect:(CGRect){.size = self.size} blendMode:kCGBlendModeCopy alpha:1];
    uint8_t *data = CGBitmapContextGetData(ctx);

    NSUInteger indexes = 262144;
    char colorIndices[262144] = {0};

    // only attempt to quantize the header
    NSUInteger l = (NSUInteger) ceil(self.size.width * 124.0f);
    for (NSUInteger i = 40 * 640; i < l; i++) {
        uint8_t red = data[i * 4 + 2];
        uint8_t green = data[i * 4 + 1];
        uint8_t blue = data[i * 4 + 0];
        NSInteger hexColor = (red >> 2) + ((green >> 2) << 6) + ((blue >> 2) << 12);

        if (hexColor > 0 && hexColor < 2621443 && red + green + blue < 255 + 255 + 200 && red != blue && blue != green && green != red) {
            colorIndices[hexColor]++;
        }
    }

    NSUInteger index = 0;
    char max = 0;
    for (NSUInteger i = 0; i < indexes; i++) {
        if (colorIndices[i] > max) {
            max = colorIndices[i];
            index = i;
        }
    }

    UIColor *color = [UIColor colorWithRed:(((index & 63) << 2) + 3) / 255.0f
									 green:(((index >> 4) & 252) + 3) / 255.0f
									  blue:(((index >> 10) & 252) + 3) / 255.0f
									 alpha:1];
	UIGraphicsEndImageContext();
	return color;
}

@end
