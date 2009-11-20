//
//  XMLRPCConnection+Authentication.h
//  WordPress
//
//  Created by Jeff Stieler on 11/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "XMLRPCConnection.h"

@class XMLRPCResponse;

@interface XMLRPCConnection (Authentication)

+ (XMLRPCResponse *)sendSynchronousXMLRPCRequest:(XMLRPCRequest *)request withUsername:(NSString *)username andPassword:(NSString *)password;

@end
