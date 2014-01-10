//
//  StatsTitleCountItem.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatsTitleCountItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *count;
@property (nonatomic, strong) NSURL *URL;

+ (NSArray *)titleCountItemsFromData:(NSDictionary *)data;

@end
