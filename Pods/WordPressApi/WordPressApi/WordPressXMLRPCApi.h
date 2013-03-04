// WordPressApi.h
//
// Copyright (c) 2011 Automattic.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WordPressBaseApi.h"

/**
 WordPress API for iOS 
*/
@interface WordPressXMLRPCApi : NSObject <WordPressBaseApi>

///-----------------------------------------
/// @name Accessing WordPress API properties
///-----------------------------------------

@property (readonly, nonatomic, retain) NSURL *xmlrpc;

///-------------------------------------------------------
/// @name Creating and Initializing a WordPress API Client
///-------------------------------------------------------

/**
 Creates and initializes a `WordPressAPI` client using password authentication.
 
 @param xmlrpc The XML-RPC endpoint URL, e.g.: https://en.blog.wordpress.com/xmlrpc.php
 @param username The user name
 @param password The password
 */
+ (WordPressXMLRPCApi *)apiWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password;

/**
 Initializes a `WordPressAPI` client using password authentication.
 
 @param xmlrpc The XML-RPC endpoint URL, e.g.: https://en.blog.wordpress.com/xmlrpc.php
 @param username The user name
 @param password The password
 */
- (id)initWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password;

///-------------------
/// @name Authenticate
///-------------------

/**
 Performs a XML-RPC test call just to verify that the credentials are correct.
 
 @param success A block object to execute when the credentials are valid. This block has no return value.
 @param failure A block object to execute when the credentials can't be verified. This block has no return value and takes one argument: a NSError object with details on the error.
 */
- (void)authenticateWithSuccess:(void (^)())success
                        failure:(void (^)(NSError *error))failure;

/**
 Authenticates and returns a list of the blogs which the user can access

 @param success A block object to execute when the login is successful. This block has no return value and takes one argument: an array with the blogs list.
 @param failure A block object to execute when the login failed. This block has no return value and takes one argument: a NSError object with details on the error.
 */
- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;

///--------------
/// @name Helpers
///--------------

/**
 Given a site URL, tries to guess the URL for the XML-RPC endpoint
 
 When asked for a site URL, sometimes users type the XML-RPC url, or the xmlrpc.php has been moved/renamed. This method would try a few methods to find the proper XML-RPC endpoint:
 
 * Try to load the given URL adding `/xmlrpc.php` at the end. This is the most common use case for proper site URLs
 * If that fails, try a test XML-RPC request given URL, maybe it was the XML-RPC URL already
 * If that fails, fetch the given URL and search for an `EditURI` link pointing to the XML-RPC endpoint
 
 For additional URL typo fixing, see [NSURL-Guess](https://github.com/koke/NSURL-Guess)
 
 @param url what the user entered as the URL, e.g.: myblog.com
 @param success A block object to execute when the method finds a suitable XML-RPC endpoint on the site provided. This block has no return value and takes two arguments: the original site URL, and the found XML-RPC endpoint URL.
 @param failure A block object to execute when the method doesn't find a suitable XML-RPC endpoint on the site. This block has no return value and takes one argument: a NSError object with details on the error.
 */
+ (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure;


@end
