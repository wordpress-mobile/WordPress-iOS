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


#import "WordPressXMLRPCApi.h"
#import "WPXMLRPCClient.h"
#import "WPRSDParser.h"

NSString *const WordPressXMLRPCApiErrorDomain = @"WordPressXMLRPCApiError";

@interface WordPressXMLRPCApi ()
@property (readwrite, nonatomic, retain) NSURL *xmlrpc;
@property (readwrite, nonatomic, retain) NSString *username;
@property (readwrite, nonatomic, retain) NSString *password;
@property (readwrite, nonatomic, retain) WPXMLRPCClient *client;

- (NSArray *)buildParametersWithExtra:(id)extra;

@end

@implementation WordPressXMLRPCApi {
    NSURL *_xmlrpc;
    NSString *_username;
    NSString *_password;
    WPXMLRPCClient *_client;
}
@synthesize xmlrpc = _xmlrpc;
@synthesize username = _username;
@synthesize password = _password;
@synthesize client = _client;

+ (WordPressXMLRPCApi *)apiWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password {
    return [[self alloc] initWithXMLRPCEndpoint:xmlrpc username:username password:password];
}

- (id)initWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.xmlrpc = xmlrpc;
    self.username = username;
    self.password = password;

    self.client = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];

    return self;
}

#pragma mark - Authentication


- (void)authenticateWithSuccess:(void (^)())success
                        failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [NSArray arrayWithObjects:self.username, self.password, nil];
    [self.client callMethod:@"wp.getUsersBlogs"
                 parameters:parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if (success) {
                            success();
                        }
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (failure) {
                            failure(error);
                        }
                    }];
}

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure {
    [self.client callMethod:@"wp.getUsersBlogs"
                 parameters:[NSArray arrayWithObjects:self.username, self.password, nil]
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if (success) {
                            success(responseObject);
                        }
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (failure) {
                            failure(error);
                        }
                    }];
}

- (void)getBlogOptionsWithSuccess:(void (^)(id options))success failure:(void (^)(NSError *error))failure
{
    [self.client callMethod:@"wp.getOptions"
                 parameters:[NSArray arrayWithObjects:@(1), self.username, self.password, nil]
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if (success) {
                            success(responseObject);
                        }
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (failure) {
                            failure(error);
                        }
                    }];
}

#pragma mark - Publishing a post

- (void)publishPostWithText:(NSString *)content title:(NSString *)title success:(void (^)(NSUInteger, NSURL *))success failure:(void (^)(NSError *))failure {
    NSDictionary *postParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    title, @"post_title",
                                    content, @"post_content",
                                    @"publish", @"post_status",
                                    nil];
    NSArray *parameters = [self buildParametersWithExtra:postParameters];
    [self.client callMethod:@"wp.newPost"
                 parameters:parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if (success) {
                            success([responseObject intValue], nil);
                        }
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (failure) {
                            failure(error);
                        }
                    }];
}

- (void)publishPostWithImage:(UIImage *)image
                 description:(NSString *)content
                       title:(NSString *)title
                     success:(void (^)(NSUInteger postId, NSURL *permalink))success
                     failure:(void (^)(NSError *error))failure {
    [self publishPostWithText:content title:title success:success failure:failure];
}

- (void)publishPostWithGallery:(NSArray *)images
                   description:(NSString *)content
                         title:(NSString *)title
                       success:(void (^)(NSUInteger postId, NSURL *permalink))success
                       failure:(void (^)(NSError *error))failure {
    [self publishPostWithText:content title:title success:success failure:failure];
}

- (void)publishPostWithVideo:(NSString *)videoPath
                 description:(NSString *)content
                       title:(NSString *)title
                     success:(void (^)(NSUInteger postId, NSURL *permalink))success
                     failure:(void (^)(NSError *error))failure {
    [self publishPostWithText:content title:title success:success failure:failure];
}

#pragma mark - Managing posts

- (void)getPosts:(NSUInteger)count
         success:(void (^)(NSArray *posts))success
         failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self buildParametersWithExtra:nil];
    [self.client callMethod:@"metaWeblog.getRecentPosts"
                 parameters:parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if (success) {
                            success((NSArray *)responseObject);
                        }
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (failure) {
                            failure(error);
                        }
                    }];
}

#pragma mark - Helpers

+ (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure {
    __block NSURL *xmlrpcURL;
    __block NSString *xmlrpc;

    // ------------------------------------------------
    // 0. Is an empty url? Sorry, no psychic powers yet
    // ------------------------------------------------
    if (url == nil || [url isEqualToString:@""]) {
        NSError *error = [NSError errorWithDomain:@"org.wordpress.api" code:0 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Empty URL", @"") forKey:NSLocalizedDescriptionKey]];
        [self logExtraInfo: [error localizedDescription] ];
        return failure ? failure(error) : nil;
    }

    // ------------------------------------------------------------------------
    // 1. Assume the given url is the home page and XML-RPC sits at /xmlrpc.php
    // ------------------------------------------------------------------------
    [self logExtraInfo: @"1. Assume the given url is the home page and XML-RPC sits at /xmlrpc.php" ];
    if(![url hasPrefix:@"http"])
        url = [NSString stringWithFormat:@"http://%@", url];

    if ([url hasSuffix:@"xmlrpc.php"])
        xmlrpc = url;
    else
        xmlrpc = [NSString stringWithFormat:@"%@/xmlrpc.php", url];

    xmlrpcURL = [NSURL URLWithString:xmlrpc];
    if (xmlrpcURL == nil) {
        // Not a valid URL. Could be a bad protocol (htpp://), syntax error (http//), ...
        // See https://github.com/koke/NSURL-Guess for extra help cleaning user typed URLs
        NSError *error = [NSError errorWithDomain:@"org.wordpress.api" code:1 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Invalid URL", @"") forKey:NSLocalizedDescriptionKey]];
        [self logExtraInfo: [error localizedDescription]];
        return failure ? failure(error) : nil;
    }
    [self logExtraInfo: @"Trying the following URL: %@", xmlrpcURL ];
    [self validateXMLRPCUrl:xmlrpcURL success:^(NSURL *validatedXmlrpcURL){
        if (success) {
            success(validatedXmlrpcURL);
        }
    } failure:^(NSError *error){
        [self logError:error];
        if (([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication)
            || ([error.domain isEqual:WordPressXMLRPCApiErrorDomain] && error.code == WordPressXMLRPCApiMobilePluginRedirectedError)) {
            if (failure) {
                failure(error);
            }
            return;
        }
        // -------------------------------------------
        // 2. Try the given url as an XML-RPC endpoint
        // -------------------------------------------
        [self logExtraInfo:@"2. Try the given url as an XML-RPC endpoint"];
        xmlrpcURL = [NSURL URLWithString:url];
        [self logExtraInfo: @"Trying the following URL: %@", url];
        [self validateXMLRPCUrl:xmlrpcURL success:^(NSURL *validatedXmlrpcURL){
            if (success) {
                success(validatedXmlrpcURL);
            }
        } failure:^(NSError *error){
            [self logError:error];
            if ([error.domain isEqual:WordPressXMLRPCApiErrorDomain] && error.code == WordPressXMLRPCApiMobilePluginRedirectedError) {
                if (failure) {
                    failure(error);
                }
                return;
            }
            // ---------------------------------------------------
            // 3. Fetch the original url and look for the RSD link
            // ---------------------------------------------------
            [self logExtraInfo:@"3. Fetch the original url and look for the RSD link by using RegExp"];
            NSURLRequest *request = [NSURLRequest requestWithURL:xmlrpcURL];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSError *error = NULL;
                NSRegularExpression *rsdURLRegExp = [NSRegularExpression regularExpressionWithPattern:@"<link\\s+rel=\"EditURI\"\\s+type=\"application/rsd\\+xml\"\\s+title=\"RSD\"\\s+href=\"([^\"]*)\"[^/]*/>" options:NSRegularExpressionCaseInsensitive error:&error];
                NSString *responseString = operation.responseString;
                // Workaround for https://github.com/AFNetworking/AFNetworking/pull/638
                // remove when it's fixed upstream. See http://ios.trac.wordpress.org/ticket/1516
                if (responseString == nil && operation.responseData != nil) {
                    responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSISOLatin1StringEncoding];
                }
                NSArray *matches = nil;
                if (responseString) {
                    matches = [rsdURLRegExp matchesInString:responseString options:0 range:NSMakeRange(0, [responseString length])];
                }
                NSString *rsdURL = nil;
                if ([matches count]) {
                    NSRange rsdURLRange = [[matches objectAtIndex:0] rangeAtIndex:1];
                    if(rsdURLRange.location != NSNotFound)
                        rsdURL = [responseString substringWithRange:rsdURLRange];
                }

                if (rsdURL == nil) {
                    //the RSD link not found using RegExp, try to find it again on a "cleaned" HTML document
                    [self logExtraInfo:@"The RSD link not found using RegExp, on the following doc: %@", responseString];
                    [self logExtraInfo:@"Try to find it again on a cleaned HTML document"];
                    NSError *htmlError;

                    NSString *cleanedHTML = nil;
                    id _CTidyClass = NSClassFromString(@"CTidy");
                    SEL _CTidySelector = NSSelectorFromString(@"tidy");
                    SEL _CTidyTidyStringSelector = NSSelectorFromString(@"tidyString:inputFormat:outputFormat:encoding:diagnostics:error:");

                    if (_CTidyClass && [_CTidyClass respondsToSelector:_CTidySelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        id _CTidyInstance = [_CTidyClass performSelector:_CTidySelector];
#pragma clang diagnostic pop

                        if (_CTidyInstance && [_CTidyInstance respondsToSelector:_CTidyTidyStringSelector]) {
                            typedef NSString *(*_CTidyTidyStringMethodType)(id, SEL, NSString *, int, int, NSString *, NSError **);
                            _CTidyTidyStringMethodType _CTidyTidyStringMethod;
                            _CTidyTidyStringMethod = (_CTidyTidyStringMethodType)[_CTidyInstance methodForSelector:_CTidyTidyStringSelector];

                            cleanedHTML = _CTidyTidyStringMethod(_CTidyInstance, _CTidyTidyStringSelector, operation.responseString, 1, 1, @"utf8", &htmlError);
                        }
                    }

                    if(cleanedHTML) {
                        [self logExtraInfo:@"The cleaned doc: %@", cleanedHTML];
                        NSArray *matches = [rsdURLRegExp matchesInString:cleanedHTML options:0 range:NSMakeRange(0, [cleanedHTML length])];
                        if ([matches count]) {
                            NSRange rsdURLRange = [[matches objectAtIndex:0] rangeAtIndex:1];
                            if (rsdURLRange.location != NSNotFound)
                                rsdURL = [cleanedHTML substringWithRange:rsdURLRange];
                        }
                    } else if (_CTidyClass) {
                        [self logExtraInfo:@"The cleaning function reported the following error: %@", [htmlError localizedDescription]];
                    }
                }

                if (rsdURL != nil) {
                    void (^parseBlock)(void) = ^() {
                        [self logExtraInfo:@"5. Parse the RSD document at the following URL: %@", rsdURL];
                        // -------------------------
                        // 5. Parse the RSD document
                        // -------------------------
                        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:rsdURL]];
                        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                            NSError *error;
                            WPRSDParser *parser = [[WPRSDParser alloc] initWithXmlString:operation.responseString];
                            NSString *parsedEndpoint = [parser parsedEndpointWithError:&error];
                            if (parsedEndpoint) {
                                xmlrpc = parsedEndpoint;
                                xmlrpcURL = [NSURL URLWithString:xmlrpc];
                                [self logExtraInfo:@"Bingo! We found the WordPress XML-RPC element: %@", xmlrpcURL];
                                [self validateXMLRPCUrl:xmlrpcURL success:^(NSURL *validatedXmlrpcURL){
                                    if (success) success(validatedXmlrpcURL);
                                } failure:^(NSError *error){
                                    [self logError:error];
                                    if (failure) failure(error);
                                }];
                            } else {
                                if (failure) failure(error);
                            }
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            [self logError:error];
                            if (failure) failure(error);
                        }];
                        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
                        [queue addOperation:operation];
                    };
                    // ----------------------------------------------------------------------------
                    // 4. Try removing "?rsd" from the url, it should point to the XML-RPC endpoint
                    // ----------------------------------------------------------------------------
                    xmlrpc = [rsdURL stringByReplacingOccurrencesOfString:@"?rsd" withString:@""];
                    if (![xmlrpc isEqualToString:rsdURL]) {
                        xmlrpcURL = [NSURL URLWithString:xmlrpc];
                        [self validateXMLRPCUrl:xmlrpcURL success:^(NSURL *validatedXmlrpcURL){
                            if (success) {
                                success(validatedXmlrpcURL);
                            }
                        } failure:^(NSError *error){
                            parseBlock();
                        }];
                    } else {
                        parseBlock();
                    }
                } else {
                    if (failure)
                        failure(error);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self logError:error];
                if (failure) failure(error);
            }];
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [queue addOperation:operation];
        }];
    }];}

#pragma mark - Private Methods

- (NSArray *)buildParametersWithExtra:(id)extra {
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:@"1"];
    [result addObject:self.username];
    [result addObject:self.password];
    if ([extra isKindOfClass:[NSArray class]]) {
        [result addObjectsFromArray:extra];
    } else if ([extra isKindOfClass:[NSDictionary class]]) {
        [result addObject:extra];
    }

    return [NSArray arrayWithArray:result];
}

+ (void)validateXMLRPCUrl:(NSURL *)url success:(void (^)(NSURL *validatedXmlrpURL))success failure:(void (^)(NSError *error))failure {
    WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:url];
    NSURLRequest *request = [client requestWithMethod:@"system.listMethods" parameters:@[]];
    __block BOOL isRedirected = NO;
    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *methods = responseObject;
        if ([methods isKindOfClass:[NSArray class]] && [methods containsObject:@"wp.getUsersBlogs"]) {
            NSURL *xmlrpcURL = operation.response.URL;
            [self logExtraInfo:@"Found XML-RPC endpoint at %@", xmlrpcURL];
            if (success) {
                success(xmlrpcURL);
            }
        } else {
            if (failure) {
                NSError *error = [NSError errorWithDomain:WordPressXMLRPCApiErrorDomain code:WordPressXMLRPCApiNotWordPressError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"That doesn't look like a WordPress site", @"WordPressApi", nil)}];
                failure(error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (isRedirected) {
            if (operation.responseString != nil
                && ([operation.responseString rangeOfString:@"<meta name=\"GENERATOR\" content=\"www.dudamobile.com\">"].location != NSNotFound
                 || [operation.responseString rangeOfString:@"dm404Container"].location != NSNotFound)) {
                error = [NSError errorWithDomain:WordPressXMLRPCApiErrorDomain code:WordPressXMLRPCApiMobilePluginRedirectedError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"You seem to have installed a mobile plugin from DudaMobile which is preventing the app to connect to your blog", @"WordPressApi", nil)}];
            }
        }
        if (failure) {
            failure(error);
        }
    }];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *redirectRequest, NSURLResponse *redirectResponse) {
        isRedirected = YES;

        if (redirectResponse) {
            [self logExtraInfo:@"Redirected to %@", redirectRequest.URL];
            NSMutableURLRequest *postRequest = postRequest = [client requestWithMethod:@"system.listMethods" parameters:@[]];
            [postRequest setURL:redirectRequest.URL];
            return postRequest;
        }

        return redirectRequest;
    }];

    [client enqueueHTTPRequestOperation:operation];
}

+ (void)logExtraInfo:(NSString *)format, ... {
    BOOL extraDebugIsActive = NO;
    NSNumber *extra_debug = [[NSUserDefaults standardUserDefaults] objectForKey:@"extra_debug"];
    if ([extra_debug boolValue]) {
        extraDebugIsActive = YES;
    }
#ifdef DEBUG
    extraDebugIsActive = YES;
#endif

    if( extraDebugIsActive == NO ) return;

    va_list ap;
	va_start(ap, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
    NSLog(@"[WordPressApi] < %@", message);
}

+ (void)logError:(NSError *)error {
    [self logExtraInfo:@"Error: %@", error];
}

@end
