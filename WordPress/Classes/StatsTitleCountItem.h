//
//  StatsTitleCountItem.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatsTitleCountItem : NSObject

@property (nonatomic, strong) NSString *title; //subclasses can return attributed strings
@property (nonatomic, strong) NSNumber *count;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *siteId;

+ (NSArray *)titleCountItemsFromData:(NSDictionary *)data withKey:(NSString *)key siteId:(NSNumber *)siteId;

@end
