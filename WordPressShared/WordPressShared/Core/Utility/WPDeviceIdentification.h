#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  @class      WPDeviceIdentification
 *  @brief      Methods for device and iOS identification should go here.
 */
@interface WPDeviceIdentification : NSObject

/**
 *  @brief      Call this method to know if the current device is an iPhone.
 *
 *  @returns    YES if the device is an iPhone.  NO otherwise.
 */
+ (BOOL)isiPhone;

/**
 *  @brief      Call this method to know if the current device is an iPad.
 *
 *  @returns    YES if the device is an iPad.  NO otherwise.
 */
+ (BOOL)isiPad;

/**
 *  @brief      Call this method to know if the current device has a retina screen.
 *
 *  @returns    YES if the device has a retina screen.  NO otherwise.
 */
+ (BOOL)isRetina;

/**
 *  @brief      Call this method to know if the current device is an iPhone6.
 *
 *  @returns    YES if the device is an iPhone6.  NO otherwise.
 */
+ (BOOL)isiPhoneSix;

/**
 *  @brief      Call this method to know if the current device is an iPhone6+.
 *
 *  @returns    YES if the device is an iPhone6+.  NO otherwise.
 */
+ (BOOL)isiPhoneSixPlus;

/**
 *  @brief      Call this method to know if the current device is a Plus sized
 *              phone (6+, 6s+, 7+) , at its native scale.
 *
 *  @returns    YES if the device is a Plus phone. NO otherwise.
 */
+ (BOOL)isUnzoomediPhonePlus;

/**
 *  @brief      Call this method to know if the current device is running iOS version older than 9.
 *
 *  @returns    YES if the device is running iOS version older than 9.  NO otherwise.
 */
+ (BOOL)isiOSVersionEarlierThan9;

/**
 *  @brief      Call this method to know if the current device is running iOS version older than 10.
 *
 *  @returns    YES if the device is running iOS version older than 10.  NO otherwise.
 */
+ (BOOL)isiOSVersionEarlierThan10;

@end
