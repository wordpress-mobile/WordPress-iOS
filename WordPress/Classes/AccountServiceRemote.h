//
//  AccountServiceRemote.h
//  WordPress
//
//  Created by Aaron Douglas on 4/3/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WordPressXMLRPCApi;

@interface AccountServiceRemote : NSObject

- (id)initWithRemoteApi:(WordPressXMLRPCApi *)api;

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;

@end
