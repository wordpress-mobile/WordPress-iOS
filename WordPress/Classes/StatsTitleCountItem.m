//
//  StatsTitleCountItem.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTitleCountItem.h"

@implementation StatsTitleCountItem

+ (NSArray *)titleCountItemsFromData:(NSDictionary *)data siteId:(NSNumber *)siteId {
    NSMutableArray *finalArray = [NSMutableArray array];
    for (NSArray *titleCountArray in data) {
        StatsTitleCountItem *titleCountItem = [[StatsTitleCountItem alloc] initWithData:titleCountArray siteId:siteId];
        [finalArray addObject:titleCountItem];
    }
    return finalArray;
}

- (id)initWithData:(NSArray *)data siteId:(NSNumber *)siteId {
    self = [super init];
    if (self) {
        self.title = data[0];
        self.count = data[1];
        self.siteId = siteId;
    }
    return self;
}

@end
