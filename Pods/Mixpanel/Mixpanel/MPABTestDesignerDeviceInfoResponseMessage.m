//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPABTestDesignerDeviceInfoResponseMessage.h"

@implementation MPABTestDesignerDeviceInfoResponseMessage

+ (instancetype)message
{
    // TODO: provide a payload
    return [[self alloc] initWithType:@"device_info_response"];
}

- (NSString *)systemName
{
    return [self payloadObjectForKey:@"system_name"];
}

- (void)setSystemName:(NSString *)systemName
{
    [self setPayloadObject:systemName forKey:@"system_name"];
}

- (NSString *)systemVersion
{
    return [self payloadObjectForKey:@"system_version"];
}

- (void)setSystemVersion:(NSString *)systemVersion
{
    [self setPayloadObject:systemVersion forKey:@"system_version"];
}

- (NSString *)appVersion
{
    return [self payloadObjectForKey:@"app_version"];
}

- (void)setAppVersion:(NSString *)appVersion
{
    [self setPayloadObject:appVersion forKey:@"app_version"];
}

- (NSString *)appRelease
{
    return [self payloadObjectForKey:@"app_release"];
}

- (void)setAppRelease:(NSString *)appRelease
{
    [self setPayloadObject:appRelease forKey:@"app_release"];
}

- (NSString *)deviceName
{
    return [self payloadObjectForKey:@"device_name"];
}

- (void)setDeviceName:(NSString *)deviceName
{
    [self setPayloadObject:deviceName forKey:@"device_name"];
}

- (NSString *)deviceModel
{
    return [self payloadObjectForKey:@"device_model"];
}

- (void)setDeviceModel:(NSString *)deviceModel
{
    [self setPayloadObject:deviceModel forKey:@"device_model"];
}

- (NSArray *)availableFontFamilies
{
    return [self payloadObjectForKey:@"available_font_families"];
}

- (void)setAvailableFontFamilies:(NSArray *)availableFontFamilies
{
    [self setPayloadObject:availableFontFamilies forKey:@"available_font_families"];
}

- (NSString *)mainBundleIdentifier
{
    return [self payloadObjectForKey:@"main_bundle_identifier"];
}

- (void)setMainBundleIdentifier:(NSString *)mainBundleIdentifier
{
    [self setPayloadObject:mainBundleIdentifier forKey:@"main_bundle_identifier"];
}

- (void)setTweaks:(NSArray *)tweaks
{
    [self setPayloadObject:tweaks forKey:@"tweaks"];
}

- (NSArray *)tweaks
{
    return [self payloadObjectForKey:@"tweaks"];
}

@end
