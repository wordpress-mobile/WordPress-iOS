//
//  WPXMLRPCRequestOperation.h
//  WordPress
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

@class WPXMLRPCRequest;

@interface WPXMLRPCRequestOperation : NSObject
@property (nonatomic, strong) WPXMLRPCRequest *XMLRPCRequest;
@property (nonatomic, copy) void (^success)(AFHTTPRequestOperation *operation, id responseObject);
@property (nonatomic, copy) void (^failure)(AFHTTPRequestOperation *operation, NSError *error);
@end
