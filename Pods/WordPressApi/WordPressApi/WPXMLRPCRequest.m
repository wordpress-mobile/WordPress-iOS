//
//  AFXMLRPCRequest.m
//  WordPress
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPXMLRPCRequest.h"

@implementation WPXMLRPCRequest

- (id)initWithMethod:(NSString *)method andParameters:(NSArray *)parameters {
    self = [super init];
    if (self) {
        _method = method;
        _parameters = parameters;
    }
    return self;
}

@end
