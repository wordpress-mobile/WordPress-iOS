//
//  WordPressRestApiJSONRequestOperationManager.h
//  WordPressApi
//
//  Created by Diego E. Rey Mendez on 5/7/14.
//  Copyright (c) 2014 Automattic. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

@interface WordPressRestApiJSONRequestOperationManager : AFHTTPRequestOperationManager

/**
 *	@brief		Default initializer.
 */
- (id)initWithBaseURL:(NSURL *)url
				token:(NSString*)token;

@end
