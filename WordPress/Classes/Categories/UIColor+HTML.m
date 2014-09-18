#import "UIColor+HTML.h"

@implementation UIColor (HTML)

- (NSString *)colorToHexString
{
    // Taken from http://stackoverflow.com/questions/8689424/uicolor-to-hexadecimal-web-color
    
    NSString *webColor = nil;
    
    // This method only works for RGB colors
    if (self &&
        CGColorGetNumberOfComponents(self.CGColor) == 4)
    {
        // Get the red, green and blue components
        const CGFloat *components = CGColorGetComponents(self.CGColor);
        
        // These components range from 0.0 till 1.0 and need to be converted to 0 till 255
        CGFloat red, green, blue;
        red = roundf(components[0] * 255.0);
        green = roundf(components[1] * 255.0);
        blue = roundf(components[2] * 255.0);
        
        // Convert with %02x (use 02 to always get two chars)
        webColor = [[NSString alloc]initWithFormat:@"%02x%02x%02x", (NSInteger)red, (NSInteger)green, (NSInteger)blue];
    }
    
    return webColor;
}

@end
