//
//  StatsTitleCountItem.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTitleCountItem.h"

@implementation StatsTitleCountItem

+ (NSArray *)titleCountItemsFromData:(NSDictionary *)data {
    NSMutableArray *finalArray = [NSMutableArray array];
    for (NSArray *titleCountArray in data) {
        StatsTitleCountItem *titleCountItem = [[StatsTitleCountItem alloc] initWithData:titleCountArray];
        [finalArray addObject:titleCountItem];
    }
    return finalArray;
}

- (id)initWithData:(NSArray *)data {
    self = [super init];
    if (self) {
        self.title = data[0];
        self.count = data[1];
    }
    return self;
}

@end
