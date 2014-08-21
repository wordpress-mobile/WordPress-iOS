#import "WPFontManager.h"
#import <CoreText/CoreText.h>

@implementation WPFontManager

static NSString * const kBundle = @"WordPress-iOS-Shared.bundle";

+ (UIFont *)openSansLightFontOfSize:(CGFloat)size
{
    NSString *resourceName = @"OpenSans-Light";
    NSString *fontName = @"OpenSans-Light";
    UIFont *font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        [[self class] dynamicallyLoadFontResourceNamed:resourceName];
        font = [UIFont fontWithName:fontName size:size];
        
        // safe fallback
        if (!font) font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (UIFont *)openSansItalicFontOfSize:(CGFloat)size
{
    NSString *resourceName = @"OpenSans-Italic";
    NSString *fontName = @"OpenSans-Italic";
    UIFont *font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        [[self class] dynamicallyLoadFontResourceNamed:resourceName];
        font = [UIFont fontWithName:fontName size:size];
        
        // safe fallback
        if (!font) font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (UIFont *)openSansLightItalicFontOfSize:(CGFloat)size
{
    NSString *resourceName = @"OpenSans-LightItalic";
    NSString *fontName = @"OpenSans-LightItalic";
    UIFont *font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        [[self class] dynamicallyLoadFontResourceNamed:resourceName];
        font = [UIFont fontWithName:fontName size:size];
        
        // safe fallback
        if (!font) font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (UIFont *)openSansBoldFontOfSize:(CGFloat)size
{
    NSString *resourceName = @"OpenSans-Bold";
    NSString *fontName = @"OpenSans-Bold";
    UIFont *font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        [[self class] dynamicallyLoadFontResourceNamed:resourceName];
        font = [UIFont fontWithName:fontName size:size];
        
        // safe fallback
        if (!font) font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (UIFont *)openSansBoldItalicFontOfSize:(CGFloat)size
{
    NSString *resourceName = @"OpenSans-BoldItalic";
    NSString *fontName = @"OpenSans-BoldItalic";
    UIFont *font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        [[self class] dynamicallyLoadFontResourceNamed:resourceName];
        font = [UIFont fontWithName:fontName size:size];
        
        // safe fallback
        if (!font) font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (UIFont *)openSansRegularFontOfSize:(CGFloat)size
{
    NSString *resourceName = @"OpenSans-Regular";
    NSString *fontName = @"OpenSans";
    UIFont *font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        [[self class] dynamicallyLoadFontResourceNamed:resourceName];
        font = [UIFont fontWithName:fontName size:size];
        
        // safe fallback
        if (!font) font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (void)dynamicallyLoadFontResourceNamed:(NSString *)name
{
    NSString *resourceName = [NSString stringWithFormat:@"%@/%@", kBundle, name];
    NSURL *url = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@"ttf"];
    NSData *fontData = [NSData dataWithContentsOfURL:url];
    
    if (fontData) {
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            DDLogError(@"Failed to load font: %@", errorDescription);
            CFRelease(errorDescription);
        }
        CFRelease(font);
        CFRelease(provider);
    }
}
@end
