//
//  WordPressRestApiJSONRequestOperationManager.m
//  WordPressApi
//
//  Created by Diego E. Rey Mendez on 5/7/14.
//  Copyright (c) 2014 Automattic. All rights reserved.
//

#import "WordPressRestApiJSONRequestOperationManager.h"

#import "WordPressRestApiJSONRequestOperation.h"

@implementation WordPressRestApiJSONRequestOperationManager

/**
 *	@brief		This method is not supported by this class.  Use initWithBaseUrl:token: instead.
 */
- (id)initWithBaseURL:(NSURL*)url
{
	[self doesNotRecognizeSelector:_cmd];
	self = nil;
	return self;
}

- (id)initWithBaseURL:(NSURL *)url
				token:(NSString*)token
{
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	NSParameterAssert([token isKindOfClass:[NSString class]]);
	
	self = [super initWithBaseURL:url];
	
	if (self)
	{
		NSString* bearerString = [NSString stringWithFormat:@"Bearer %@", token];
		
		[self.requestSerializer setValue:bearerString forHTTPHeaderField:@"Authorization"];
	}
	
	return self;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    WordPressRestApiJSONRequestOperation *operation = [[WordPressRestApiJSONRequestOperation alloc] initWithRequest:request];
	
	operation.responseSerializer = [[AFJSONResponseSerializer alloc] init];
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;
	
    [operation setCompletionBlockWithSuccess:success failure:failure];
	
    return operation;
}

@end
