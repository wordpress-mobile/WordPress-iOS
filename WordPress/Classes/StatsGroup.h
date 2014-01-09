//
//  StatsGroup.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-07.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StatsTitleCountItem.h"

@interface StatsGroup : StatsTitleCountItem

@property (nonatomic, strong) NSString *group;
@property (nonatomic, strong) NSURL *iconUrl;

@end
