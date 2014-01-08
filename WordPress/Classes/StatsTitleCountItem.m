//
//  StatsTitleCountItem.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTitleCountItem.h"

@implementation StatsTitleCountItem

+ (NSArray *)titleCountItemsFromData:(NSDictionary *)data withKey:(NSString *)key siteId:(NSNumber *)siteId {
    NSArray *dataArray = data[key];
    NSMutableArray *finalArray = [NSMutableArray array];
    for (NSArray *titleCountArray in dataArray) {
        StatsTitleCountItem *titleCountItem = [[StatsTitleCountItem alloc] initWithData:titleCountArray date:data[@"date"] siteId:siteId];
        [finalArray addObject:titleCountItem];
    }
    return finalArray;
}

- (id)initWithData:(NSArray *)data date:(NSDate *)date siteId:(NSNumber *)siteId {
    self.title = data[0];
    self.count = data[1];
    self.date = date;
    self.siteId = siteId;
    return self;
}

@end
