//
//  SLDevice.m
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SLDevice.h"

#import "SLTerminal.h"
#import "SLStringUtilities.h"
#import "SLGeometry.h"


@implementation SLDevice

+ (SLDevice *)currentDevice {
    static SLDevice *device;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device = [[SLDevice alloc] init];
    });
    return device;
}

- (void)deactivateAppForDuration:(NSTimeInterval)duration {
    UIDeviceOrientation currentOrientation = [UIDevice currentDevice].orientation;

    [[SLTerminal sharedTerminal] evalWithFormat:@"UIATarget.localTarget().deactivateAppForDuration(%g)", duration];

    // On iPads running iOS 5.1 and 7.1, `UIDevice` forgets its orientation after deactivation.
    // This is not only unexpected but can mess with `-[SLElement isVisible]`.
    // See https://github.com/inkling/Subliminal/pull/180#issuecomment-40891098
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) &&
            ((kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) ||
             (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1))) {
        [self setOrientation:currentOrientation];
    }
}

#pragma mark - Device Rotation

NSString * SLUIADeviceOrientationFromUIDeviceOrientation(UIDeviceOrientation deviceOrientation)
{
    switch (deviceOrientation) {
        case UIDeviceOrientationUnknown:              return @"UIA_DEVICE_ORIENTATION_UNKNOWN";               break;
        case UIDeviceOrientationPortrait:             return @"UIA_DEVICE_ORIENTATION_PORTRAIT";              break;
        case UIDeviceOrientationPortraitUpsideDown:   return @"UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN";   break;
        case UIDeviceOrientationLandscapeLeft:        return @"UIA_DEVICE_ORIENTATION_LANDSCAPELEFT";         break;
        case UIDeviceOrientationLandscapeRight:       return @"UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT";        break;
        case UIDeviceOrientationFaceUp:               return @"UIA_DEVICE_ORIENTATION_FACEUP";                break;
        case UIDeviceOrientationFaceDown:             return @"UIA_DEVICE_ORIENTATION_FACEDOWN";              break;
    }
}

- (void)setOrientation:(UIDeviceOrientation)deviceOrientation
{
    [[SLTerminal sharedTerminal] evalWithFormat:@"UIATarget.localTarget().setDeviceOrientation(%@)", SLUIADeviceOrientationFromUIDeviceOrientation(deviceOrientation)];
    // Delay to ensure that the rotation completes and UIDevice registers the new orientation
    [NSThread sleepForTimeInterval:1.0];
}

#pragma mark - Screenshots

- (void)captureScreenshotWithFilename:(NSString *)filename
{
    [[SLTerminal sharedTerminal] evalWithFormat:@"UIATarget.localTarget().captureScreenWithName(\"%@\")",
                                                [filename slStringByEscapingForJavaScriptLiteral]];
}

- (void)captureScreenshotWithFilename:(NSString *)filename inRect:(CGRect)rect
{
    [[SLTerminal sharedTerminal] evalWithFormat:@"UIATarget.localTarget().captureRectWithName(%@,\"%@\")",
                                                SLUIARectFromCGRect(rect),[filename slStringByEscapingForJavaScriptLiteral]];
}

@end
