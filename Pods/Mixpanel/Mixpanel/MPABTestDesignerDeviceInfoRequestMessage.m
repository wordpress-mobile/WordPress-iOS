//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPABTestDesignerDeviceInfoRequestMessage.h"
#import "MPABTestDesignerDeviceInfoResponseMessage.h"
#import "MPABTestDesignerConnection.h"
#import "MPTweakStore.h"
#import "MPTweak.h"

NSString *const MPABTestDesignerDeviceInfoRequestMessageType = @"device_info_request";

@implementation MPABTestDesignerDeviceInfoRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerDeviceInfoRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong MPABTestDesignerConnection *conn = weak_connection;

        MPABTestDesignerDeviceInfoResponseMessage *deviceInfoResponseMessage = [MPABTestDesignerDeviceInfoResponseMessage message];

        dispatch_sync(dispatch_get_main_queue(), ^{
            UIDevice *currentDevice = [UIDevice currentDevice];

            deviceInfoResponseMessage.systemName = currentDevice.systemName;
            deviceInfoResponseMessage.systemVersion = currentDevice.systemVersion;
            deviceInfoResponseMessage.deviceName = currentDevice.name;
            deviceInfoResponseMessage.deviceModel = currentDevice.model;
            deviceInfoResponseMessage.appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
            deviceInfoResponseMessage.appRelease = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
            deviceInfoResponseMessage.mainBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
            deviceInfoResponseMessage.availableFontFamilies = [self availableFontFamilies];
            deviceInfoResponseMessage.tweaks = [self getTweaks];
        });

        [conn sendMessage:deviceInfoResponseMessage];
    }];

    return operation;
}

- (NSArray *)availableFontFamilies
{
    NSMutableDictionary *fontFamilies = [[NSMutableDictionary alloc] init];

    // Get all the font families and font names.
    for (NSString *familyName in [UIFont familyNames]) {
        fontFamilies[familyName] = [self fontDictionaryForFontFamilyName:familyName fontNames:[UIFont fontNamesForFamilyName:familyName]];
    }

    // For the system fonts update the font families.
    NSArray *systemFonts = @[[UIFont systemFontOfSize:17.0f],
            [UIFont boldSystemFontOfSize:17.0f],
            [UIFont italicSystemFontOfSize:17.0f]];

    for (UIFont *systemFont in systemFonts) {
        NSString *familyName = systemFont.familyName;
        NSString *fontName = systemFont.fontName;

        NSMutableDictionary *font = fontFamilies[familyName];
        if (font) {
            NSMutableArray *fontNames = font[@"font_names"];
            if ([fontNames containsObject:fontName] == NO) {
                [fontNames addObject:fontName];
            }
        } else {
            fontFamilies[familyName] = [self fontDictionaryForFontFamilyName:familyName fontNames:@[fontName]];
        }
    }

    return [fontFamilies allValues];
}

- (NSMutableDictionary *)fontDictionaryForFontFamilyName:(NSString *)familyName fontNames:(NSArray *)fontNames
{
    return [@{
        @"family" : familyName,
        @"font_names" : [fontNames mutableCopy]
    } mutableCopy];
}

- (NSArray *)getTweaks
{
    NSMutableArray *tweaks = [NSMutableArray array];
    for (MPTweak *t in [MPTweakStore sharedInstance].tweaks) {
        [tweaks addObject:@{@"name": t.name,
                            @"encoding": t.encoding,
                            @"value": t.currentValue ?: [NSNull null],
                            @"default": t.defaultValue ?: [NSNull null],
                            @"minimum": t.minimumValue ?: [NSNull null],
                            @"maximum": t.maximumValue ?: [NSNull null]
                            }];
    }
    return [tweaks copy];
}

@end
