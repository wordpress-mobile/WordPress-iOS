//
//  SPHttpRequest.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/21/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark ====================================================================================
#pragma mark SPHttpRequestDelegate
#pragma mark ====================================================================================

@class SPHttpRequest;
@class SPHttpRequestQueue;

typedef NS_ENUM(NSUInteger, SPHttpRequestMethods) {
	SPHttpRequestMethodsPut,
    SPHttpRequestMethodsGet,
    SPHttpRequestMethodsPost
};

typedef NS_ENUM(NSUInteger, SPHttpRequestErrors) {
	SPHttpRequestErrorsTimeout
};

typedef NS_ENUM(NSUInteger, SPHttpRequestStatus) {
	SPHttpRequestStatusWorking,
	SPHttpRequestStatusDone
};


#pragma mark ====================================================================================
#pragma mark SPHttpRequest
#pragma mark ====================================================================================

@interface SPHttpRequest : NSObject
@property (nonatomic, strong, readonly)  NSURL					*url;
@property (nonatomic, assign, readonly)  SPHttpRequestStatus	status;
@property (nonatomic, assign, readonly)  float					downloadProgress;
@property (nonatomic, assign, readonly)  float					uploadProgress;
@property (nonatomic, assign, readonly)  int					responseCode;
@property (nonatomic, strong, readonly)  NSData					*responseData;
@property (nonatomic, strong, readonly)  NSString				*responseString;
@property (nonatomic, strong, readonly)  NSError				*responseError;

@property (nonatomic, assign, readwrite) SPHttpRequestMethods	method;
@property (nonatomic, strong, readwrite) NSDictionary			*headers;
@property (nonatomic, strong, readwrite) NSDictionary			*userInfo;
@property (nonatomic, strong, readwrite) NSData					*postData;
@property (nonatomic, assign, readwrite) NSTimeInterval			timeout;

@property (nonatomic, weak,   readwrite) id						delegate;
@property (nonatomic, assign, readwrite) SEL					selectorStarted;
@property (nonatomic, assign, readwrite) SEL					selectorSuccess;
@property (nonatomic, assign, readwrite) SEL					selectorFailed;
@property (nonatomic, assign, readwrite) SEL					selectorProgress;

+ (SPHttpRequest *)requestWithURL:(NSURL*)url;

@end
