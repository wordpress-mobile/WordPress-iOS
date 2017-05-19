#import "WPDeviceIdentification.h"
#include <sys/utsname.h>

static NSString* const WPDeviceModelNameiPhone6 = @"iPhone 6";
static NSString* const WPDeviceModelNameiPhone6Plus = @"iPhone 6 Plus";
static NSString* const WPDeviceModelNameiPadSimulator = @"iPad Simulator";
static NSString* const WPDeviceModelNameiPhoneSimulator = @"iPhone Simulator";

// Device Names
static NSString* const WPDeviceNameiPad1 = @"iPad 1";
static NSString* const WPDeviceNameiPad2 = @"iPad 2";
static NSString* const WPDeviceNameiPad3 = @"iPad 3";
static NSString* const WPDeviceNameiPad4 = @"iPad 4";
static NSString* const WPDeviceNameiPadAir1 = @"iPad Air 1";
static NSString* const WPDeviceNameiPadAir2 = @"iPad Air 2";
static NSString* const WPDeviceNameiPadMini1 = @"iPad Mini 1";
static NSString* const WPDeviceNameiPadMini2 = @"iPad Mini 2";
static NSString* const WPDeviceNameiPhone1 = @"iPhone 1";
static NSString* const WPDeviceNameiPhone3 = @"iPhone 3";
static NSString* const WPDeviceNameiPhone3gs = @"iPhone 3GS";
static NSString* const WPDeviceNameiPhone4 = @"iPhone 4";
static NSString* const WPDeviceNameiPhone4s = @"iPhone 4S";
static NSString* const WPDeviceNameiPhone5 = @"iPhone 5";
static NSString* const WPDeviceNameiPhone5c = @"iPhone 5C";
static NSString* const WPDeviceNameiPhone5s = @"iPhone 5S";
static NSString* const WPDeviceNameiPhone6 = @"iPhone 6";
static NSString* const WPDeviceNameiPhone6Plus = @"iPhone 6 Plus";
static NSString* const WPDeviceNameiPodTouch1 = @"iPod Touch 1";
static NSString* const WPDeviceNameiPodTouch2 = @"iPod Touch 2";
static NSString* const WPDeviceNameiPodTouch3 = @"iPod Touch 3";
static NSString* const WPDeviceNameiPodTouch4 = @"iPod Touch 4";
static NSString* const WPDeviceNameSimulator = @"Simulator";

@implementation WPDeviceIdentification

#pragma mark - System info

+ (struct utsname)systemInfo
{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    return systemInfo;
}

+ (NSString*)deviceName
{
    // Credits: original list taken from this URL
    // http://stackoverflow.com/questions/26028918/ios-how-to-determine-iphone-model-in-swift
    //
    NSDictionary* devices = @{@"i386":          WPDeviceNameSimulator,
                              @"x86_64":        WPDeviceNameSimulator,
                              @"iPod1,1":       WPDeviceNameiPodTouch1,       // (Original)
                              @"iPod2,1":       WPDeviceNameiPodTouch2,     // (Second Generation)
                              @"iPod3,1":       WPDeviceNameiPodTouch3,     // (Third Generation)
                              @"iPod4,1":       WPDeviceNameiPodTouch4,     // (Fourth Generation)
                              @"iPhone1,1":     WPDeviceNameiPhone1,        // (Original)
                              @"iPhone1,2":     WPDeviceNameiPhone3,        // (3G)
                              @"iPhone2,1":     WPDeviceNameiPhone3gs,      // (3GS)
                              @"iPad1,1":       WPDeviceNameiPad1,          // (Original)
                              @"iPad2,1":       WPDeviceNameiPad2,          //
                              @"iPad3,1":       WPDeviceNameiPad3,          // (3rd Generation)
                              @"iPhone3,1":     WPDeviceNameiPhone4,        //
                              @"iPhone3,2":     WPDeviceNameiPhone4,        //
                              @"iPhone4,1":     WPDeviceNameiPhone4s,       //
                              @"iPhone5,1":     WPDeviceNameiPhone5,        // (model A1428, AT&T/Canada)
                              @"iPhone5,2":     WPDeviceNameiPhone5,        // (model A1429, everything else)
                              @"iPad3,4":       WPDeviceNameiPad4,          // (4th Generation)
                              @"iPad2,5":       WPDeviceNameiPadMini1,      // (Original)
                              @"iPhone5,3":     WPDeviceNameiPhone5c,       // (model A1456, A1532 | GSM)
                              @"iPhone5,4":     WPDeviceNameiPhone5c,       // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1":     WPDeviceNameiPhone5s,       // (model A1433, A1533 | GSM)
                              @"iPhone6,2":     WPDeviceNameiPhone5s,       // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPad4,1":       WPDeviceNameiPadAir1,       // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2":       WPDeviceNameiPadAir2,       // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4":       WPDeviceNameiPadMini2,      // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5":       WPDeviceNameiPadMini2,      // (2nd Generation iPad Mini - Cellular)
                              @"iPhone7,1":     WPDeviceNameiPhone6Plus,    // All iPhone 6 Plus's
                              @"iPhone7,2":     WPDeviceNameiPhone6         // All iPhone 6's
                              };
    
    struct utsname systemInfo = [self systemInfo];
    
    NSString* deviceIdentifier = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    return devices[deviceIdentifier];
}

#pragma mark - Device identification

+ (BOOL)isiPhone {
    return ![self isiPad];
}

+ (BOOL)isiPad {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

+ (BOOL)isRetina {
    return ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] > 1);
}


+ (BOOL)isiPhoneSix
{
    NSString* deviceName = [self deviceName];
    BOOL result = NO;
    
    if ([deviceName isEqualToString:WPDeviceNameSimulator]) {
        // IMPORTANT: this aproximation is only used when testing using the simulator.  It's
        //  basically our best bet at identifying the device in lack of a better method.  This
        //  aproximation may need adjusting when new devices come out.
        //
        result = ([self isiPhone]
                  && [[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)]
                  && [[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)]
                  && [[UIScreen mainScreen] nativeScale] == 2
                  && CGRectGetHeight([[UIScreen mainScreen] nativeBounds]) == 1334);
    } else {
        result = [deviceName isEqualToString:WPDeviceNameiPhone6];
    }
    
    return result;
}

+ (BOOL)isiPhoneSixPlus
{
    NSString* deviceName = [self deviceName];
    BOOL result = NO;
    
    if ([deviceName isEqualToString:WPDeviceNameSimulator]) {
        // IMPORTANT: this aproximation is only used when testing using the simulator.  It's
        //  basically our best bet at identifying the device in lack of a better method.  This
        //  aproximation may need adjusting when new devices come out.
        //
        result = ([self isiPhone]
                  && [[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)]
                  && [[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)]
                  && [[UIScreen mainScreen] nativeScale] > 2.5
                  && CGRectGetHeight([[UIScreen mainScreen] nativeBounds]) == 2208);
    } else {
        result = [deviceName isEqualToString:WPDeviceNameiPhone6Plus];
    }
    
    return result;
}

+ (BOOL)isUnzoomediPhonePlus
{
    CGRect bounds = UIScreen.mainScreen.fixedCoordinateSpace.bounds;
    CGFloat unzoomediPhonePlusHeight = 736.0;

    return UIScreen.mainScreen.scale == 3.0 && bounds.size.height == unzoomediPhonePlusHeight;
}

+ (BOOL)isiOSVersionEarlierThan9
{
    return [[[UIDevice currentDevice] systemVersion] floatValue] < 9.0;
}

+ (BOOL)isiOSVersionEarlierThan10
{
    return [[[UIDevice currentDevice] systemVersion] floatValue] < 10.0;
}

@end
