//
//  AFXMLRPCRequest.h
//  WordPress
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `WPXMLRPCRequest` represents a XML-RPC request.
 
 It is designed to combine multiple requests using `system.multicall` but can also be used for single requests
 */
@interface WPXMLRPCRequest : NSObject

/**
 Initializes a `WPXMLRPCRequest` object with the specified method and parameters.

 @param method the XML-RPC method for this request
 @param parameters an array containing the parameters for the request. If you want to support streaming, you can use either `NSInputStream` or `NSFileHandle` to encode binary data

 @return The newly-initialized XML-RPC request
 */
- (id)initWithMethod:(NSString *)method andParameters:(NSArray *)parameters;

/**
 The XML-RPC method for this request.

 This is a *read-only* property, as requests can't be reused.
 */
@property (nonatomic, readonly) NSString *method;

/**
 The XML-RPC parameters for this request.

 This is a *read-only* property, as requests can't be reused.
 */
@property (nonatomic, readonly) NSArray *parameters;

@end