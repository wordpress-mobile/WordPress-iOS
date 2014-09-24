//
//  MPABTestDesignerClearResponseMessage.h
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 3/7/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "MPAbstractABTestDesignerMessage.h"

@interface MPABTestDesignerClearResponseMessage : MPAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *status;

@end
