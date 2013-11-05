/*
 * WPXMLRPCIncrementalStoreClient.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <AFNetworking/AFHTTPClient.h>
#import <AFIncrementalStore/AFIncrementalStore.h>

@interface WPXMLRPCIncrementalStoreClient : AFHTTPClient <AFIncrementalStoreHTTPClient>

+ (instancetype)sharedClient;

@end
