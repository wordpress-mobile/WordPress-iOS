#import "MixpanelTweaks.h"
#import "Mixpanel/MPTweakInline.h"

@implementation MixpanelTweaks

+ (BOOL)NUXMagicLinksEnabled
{
    return MPTweakValue(@"NUX_MAGICLINKS_ENABLED", NO);
}

@end
