#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface WordPressRestApiJSONRequestOperationManager : AFHTTPRequestOperationManager

/**
 *	@brief		Default initializer.
 */
- (id)initWithBaseURL:(NSURL *)url
				token:(NSString*)token;

@end
