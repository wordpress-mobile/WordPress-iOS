#import "WPDeviceIdentification.h"

@implementation WPDeviceIdentification

+ (BOOL)isiPhone {
    return ![self isiPad];
}

+ (BOOL)isiPad {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

@end
