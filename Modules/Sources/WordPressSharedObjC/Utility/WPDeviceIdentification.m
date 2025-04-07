#import "WPDeviceIdentification.h"

@implementation WPDeviceIdentification

+ (BOOL)isiPhone {
    return ![self isiPad];
}

+ (BOOL)isiPad {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

+ (BOOL)isUnzoomediPhonePlus
{
    CGRect bounds = UIScreen.mainScreen.fixedCoordinateSpace.bounds;
    CGFloat unzoomediPhonePlusHeight = 736.0;

    return UIScreen.mainScreen.scale == 3.0 && bounds.size.height == unzoomediPhonePlusHeight;
}

@end
