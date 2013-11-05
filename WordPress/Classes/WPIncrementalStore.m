/*
 * WPIncrementalStore.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "WPIncrementalStore.h"
#import "WPXMLRPCIncrementalStoreClient.h"

@implementation WPIncrementalStore

+ (void)initialize {
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type {
    return NSStringFromClass(self);
}

+ (NSManagedObjectModel *)model {
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WordPress" withExtension:@"xcdatamodeld"]];
}

- (AFHTTPClient<AFIncrementalStoreHTTPClient> *)HTTPClient {
    return [WPXMLRPCIncrementalStoreClient sharedClient];
}

@end
