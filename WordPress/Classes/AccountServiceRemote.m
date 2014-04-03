//
//  AccountServiceRemote.m
//  WordPress
//
//  Created by Aaron Douglas on 4/3/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "AccountServiceRemote.h"
#import <WordPressApi/WordPressApi.h>

@interface AccountServiceRemote ()

@property (nonatomic, strong) WordPressXMLRPCApi *api;

@end

@implementation AccountServiceRemote

- (id)initWithRemoteApi:(WordPressXMLRPCApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }
    
    return self;
}

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure
{
    [self.api getBlogsWithSuccess:success failure:failure];
}

@end
