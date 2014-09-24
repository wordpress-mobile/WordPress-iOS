//
//  MPABTestDesignerTweakResponseMessage.h
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 7/5/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "MPAbstractABTestDesignerMessage.h"

@interface MPABTestDesignerTweakResponseMessage : MPAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *status;

@end
