#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@class WPXMLRPCRequestOperation, WPXMLRPCRequest;

extern NSString *const WPXMLRPCClientErrorDomain;

/**
 `AFXMLRPCClient` binds together AFNetworking and eczarny's XML-RPC library to interact with XML-RPC based APIs
 */
@interface WPXMLRPCClient : NSObject

///---------------------------------------
/// @name Accessing HTTP Client Properties
///---------------------------------------

/**
 The url used as the XML-RPC endpoint
 */
@property (readonly, nonatomic, strong) NSURL *xmlrpcEndpoint;

/**
 The operation queue which manages operations enqueued by the HTTP client.
 */
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

///------------------------------------------------
/// @name Creating and Initializing XML-RPC Clients
///------------------------------------------------

/**
 Creates and initializes an `AFXMLRPCClient` object with the specified base URL.

 @param xmlrpcEndpoint The XML-RPC endpoint URL for the XML-RPC client. This argument must not be nil.

 @return The newly-initialized XML-RPC client
 */
+ (WPXMLRPCClient *)clientWithXMLRPCEndpoint:(NSURL *)xmlrpcEndpoint;

/**
 Initializes an `AFXMLRPCClient` object with the specified base URL.

 @param xmlrpcEndpoint The XML-RPC endpoint URL for the XML-RPC client. This argument must not be nil.

 @return The newly-initialized XML-RPC client
 */
- (id)initWithXMLRPCEndpoint:(NSURL *)xmlrpcEndpoint;

///----------------------------------
/// @name Managing HTTP Header Values
///----------------------------------

/**
 Returns the value for the HTTP headers set in request objects created by the HTTP client.

 @param header The HTTP header to return the default value for

 @return The default value for the HTTP header, or `nil` if unspecified
 */
- (NSString *)defaultValueForHeader:(NSString *)header;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.

 @param header The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil
 */
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a token-based authentication value, such as an OAuth access token. This overwrites any existing value for this header.

 @param token The authentication token
 */
- (void)setAuthorizationHeaderWithToken:(NSString *)token;

/**
 Clears any existing value for the "Authorization" HTTP header.
 */
- (void)clearAuthorizationHeader;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates a `NSMutableURLRequest` object with the specified XML-RPC method and parameters.

 @param method The XML-RPC method for the request.
 @param parameters The XML-RPC parameters to be set as the request body.

 @return A `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                parameters:(NSArray *)parameters;

/**
 Creates a `NSMutableURLRequest` object with the specified XML-RPC method and parameters, but uses streaming to encode and send the XML-RPC request.

 @param method The XML-RPC method for the request.
 @param parameters The XML-RPC parameters to be set as the request body.
 @param filePathForCache The path wehere the streaming request will be cached. This file can only be delete after 
 @return A `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)streamingRequestWithMethod:(NSString *)method
                                         parameters:(NSArray *)parameters
                              usingFilePathForCache:(NSString *)filePath;

/**
 Creates an `AFXMLRPCRequest` object with the specified XML-RPC method and parameters.

 @param method The XML-RPC method for the request.
 @param parameters The XML-RPC parameters to be set as the request body.

 @return An `AFXMLRPCRequest` object
 */
- (WPXMLRPCRequest *)XMLRPCRequestWithMethod:(NSString *)method
                                  parameters:(NSArray *)parameters;

///-------------------------------
/// @name Creating HTTP Operations
///-------------------------------

/**
 Creates an `AFHTTPRequestOperation`

 @param request The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFXMLRPCRequestOperation`

 @param request The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (WPXMLRPCRequestOperation *)XMLRPCRequestOperationWithRequest:(WPXMLRPCRequest *)request
                                                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` combining multiple XML-RPC calls in a single request using `system.multicall`

 @param operations An array of `AFXMLRPCRequestOperation` objects
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (AFHTTPRequestOperation *)combinedHTTPRequestOperationWithOperations:(NSArray *)operations
                                                               success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

///----------------------------------------
/// @name Managing Enqueued HTTP Operations
///----------------------------------------

/**
 Enqueues an `AFHTTPRequestOperation` to the XML-RPC client's operation queue.

 @param operation The XML-RPC request operation to be enqueued.
 */
- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation;

/**
 Enqueues an `AFXMLRPCRequestOperation` to the XML-RPC client's operation queue.

 @param operation The XML-RPC request operation to be enqueued.
 */
- (void)enqueueXMLRPCRequestOperation:(WPXMLRPCRequestOperation *)operation;

/**
 Cancels all operations in the HTTP client's operation queue.
 */
- (void)cancelAllHTTPOperations;


///------------------------------
/// @name Making XML-RPC requests
///------------------------------

/**
 Creates an `AFHTTPRequestOperation` with a `XML-RPC` request, and enqueues it to the HTTP client's operation queue.

 @param method The XML-RPC method.
 @param parameters The XML-RPC parameters to be set as the request body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.

 @see HTTPRequestOperationWithRequest:success:failure
 */
- (void)callMethod:(NSString *)method
        parameters:(NSArray *)parameters
           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
