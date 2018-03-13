#import "WPFontManager.h"
#import <CoreText/CoreText.h>


@implementation WPFontManager

static NSString * const FontTypeTTF = @"ttf";
static NSString * const FontTypeOTF = @"otf";

#pragma mark - System Fonts

+ (UIFont *)systemLightFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
}

+ (UIFont *)systemItalicFontOfSize:(CGFloat)size
{
    return [UIFont italicSystemFontOfSize:size];
}

+ (UIFont *)systemBoldFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightBold];
}

+ (UIFont *)systemSemiBoldFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
}

+ (UIFont *)systemRegularFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightRegular];
}

+ (UIFont *)systemMediumFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
}

#pragma mark - Noto Fonts

static NSString* const NotoBoldFontName = @"NotoSerif-Bold";
static NSString* const NotoBoldFileName = @"NotoSerif-Bold";
static NSString* const NotoBoldItalicFontName = @"NotoSerif-BoldItalic";
static NSString* const NotoBoldItalicFileName = @"NotoSerif-BoldItalic";
static NSString* const NotoItalicFontName = @"NotoSerif-Italic";
static NSString* const NotoItalicFileName = @"NotoSerif-Italic";
static NSString* const NotoRegularFontName = @"NotoSerif";
static NSString* const NotoRegularFileName = @"NotoSerif-Regular";

+ (void)loadNotoFontFamily
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self loadFontNamed:NotoRegularFontName resourceNamed:NotoRegularFileName withExtension:FontTypeTTF];
        [self loadFontNamed:NotoBoldFileName resourceNamed:NotoBoldFileName withExtension:FontTypeTTF];
        [self loadFontNamed:NotoBoldItalicFontName resourceNamed:NotoBoldItalicFileName withExtension:FontTypeTTF];
        [self loadFontNamed:NotoItalicFontName resourceNamed:NotoItalicFileName withExtension:FontTypeTTF];
    });
}

+ (UIFont *)notoBoldFontOfSize:(CGFloat)size
{
    return [self fontNamed:NotoBoldFontName resourceName:NotoBoldFileName fontType:FontTypeTTF size:size];
}

+ (UIFont *)notoBoldItalicFontOfSize:(CGFloat)size;
{
    return [self fontNamed:NotoBoldItalicFontName resourceName:NotoBoldItalicFileName fontType:FontTypeTTF size:size];
}

+ (UIFont *)notoItalicFontOfSize:(CGFloat)size;
{
    return [self fontNamed:NotoItalicFontName resourceName:NotoItalicFileName fontType:FontTypeTTF size:size];
}

+ (UIFont *)notoRegularFontOfSize:(CGFloat)size
{
    return [self fontNamed:NotoRegularFontName resourceName:NotoRegularFileName fontType:FontTypeTTF size:size];
}


#pragma mark - Private Methods

+ (UIFont *)fontNamed:(NSString *)fontName resourceName:(NSString *)resourceName fontType:(NSString *)fontType size:(CGFloat)size
{
    UIFont *font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        [[self class] loadFontResourceNamed:resourceName withExtension:fontType];
        font = [UIFont fontWithName:fontName size:size];

        // safe fallback
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }

    return font;
}

+ (void)loadFontNamed:(NSString *)fontName resourceNamed:(NSString *)resourceName withExtension:(NSString *)extension {
    UIFont *font = [UIFont fontWithName:fontName size:UIFont.systemFontSize];
    if (!font) {
        [self loadFontResourceNamed:resourceName withExtension:FontTypeTTF];
    }
}

+ (void)loadFontResourceNamed:(NSString *)name withExtension:(NSString *)extension
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:name withExtension:extension];

    CFErrorRef error;
    if (!CTFontManagerRegisterFontsForURL((CFURLRef)url, kCTFontManagerScopeProcess, &error)) {
        CFStringRef errorDescription = CFErrorCopyDescription(error);
        NSLog(@"Failed to load font: %@", errorDescription);
        CFRelease(errorDescription);
    }

    return;
}

@end
