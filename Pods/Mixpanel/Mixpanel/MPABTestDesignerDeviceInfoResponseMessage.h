//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>
#import "MPAbstractABTestDesignerMessage.h"

@interface MPABTestDesignerDeviceInfoResponseMessage : MPAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *systemName;
@property (nonatomic, copy) NSString *systemVersion;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *appRelease;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *deviceModel;
@property (nonatomic, copy) NSArray *availableFontFamilies;
@property (nonatomic, copy) NSString *mainBundleIdentifier;
@property (nonatomic, copy) NSArray *tweaks;

@end
