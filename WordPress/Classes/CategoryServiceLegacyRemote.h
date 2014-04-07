/*
 * CategoryServiceRemote.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

#import "CategoryServiceRemote.h"

@class WPXMLRPCClient;

@interface CategoryServiceLegacyRemote : NSObject<CategoryServiceRemoteAPI>

- (id)initWithApi:(WPXMLRPCClient *)api
         username:(NSString *)username
         password:(NSString *)password;

@end
