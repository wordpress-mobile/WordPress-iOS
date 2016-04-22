#import "WordPressXMLRPCApi.h"
#import "WPXMLRPCClient.h"
#import "WPRSDParser.h"

NSString *const WordPressXMLRPCApiErrorDomain = @"WordPressXMLRPCApiError";

@interface WordPressXMLRPCApi ()

@property (readwrite, nonatomic, retain) NSURL *xmlrpc;
@property (readwrite, nonatomic, retain) NSString *username;
@property (readwrite, nonatomic, retain) NSString *password;
@property (readwrite, nonatomic, retain) WPXMLRPCClient *client;

@end

@implementation WordPressXMLRPCApi

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

- (NSOperationQueue *)operationQueue
{
    return self.client.operationQueue;
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

+ (NSURL *)urlForXMLRPCFromUrl:(NSString *)url addXMLRPC:(BOOL) addXMLRPC error:(NSError **)error
{
    NSString *xmlrpc;
    // ------------------------------------------------
    // Is an empty url? Sorry, no psychic powers yet
    // ------------------------------------------------
    if (url == nil || [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        *error = [NSError errorWithDomain:WordPressXMLRPCApiErrorDomain
                                     code:WordPressXMLRPCApiEmptyURL
                                 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Empty URL", @"")}];
        return nil;
    }

    // ------------------------------------------------------------------------
    // Check if it's a valid URL
    // Not a valid URL. Could be a bad protocol (htpp://), syntax error (http//), ...
    // See https://github.com/koke/NSURL-Guess for extra help cleaning user typed URLs
    // ------------------------------------------------------------------------
    NSURL *baseURL = [NSURL URLWithString:url];
    if (baseURL == nil) {
        *error = [NSError errorWithDomain:WordPressXMLRPCApiErrorDomain
                                     code:WordPressXMLRPCApiInvalidURL
                                 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid URL", @"")}];
        return nil;
    }
    // ------------------------------------------------------------------------
    // Let's see if a scheme is provided and it's HTTP or HTTPS
    // ------------------------------------------------------------------------
    NSString *scheme = [baseURL.scheme lowercaseString];
    if (!scheme) {
        url = [NSString stringWithFormat:@"http://%@", url];
        scheme = @"http";
    }
    if (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
        *error = [NSError errorWithDomain:WordPressXMLRPCApiErrorDomain
                                             code:WordPressXMLRPCApiInvalidScheme
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Invalid URL scheme inserted, only HTTP and HTTPS are supported.", @"Message to explay to the user he should only use HTTP or HTTPS for is self-hosted WordPress sites")}];
        return nil;
    }

    // ------------------------------------------------------------------------
    // Assume the given url is the home page and XML-RPC sits at /xmlrpc.php
    // ------------------------------------------------------------------------
    [self logExtraInfo: @"Assume the given url is the home page and XML-RPC sits at /xmlrpc.php" ];
    if ([[baseURL lastPathComponent] isEqualToString:@"xmlrpc.php"] || !addXMLRPC) {
        xmlrpc = url;
    } else {
        xmlrpc = [NSString stringWithFormat:@"%@/xmlrpc.php", url];
    }
    return [NSURL URLWithString:xmlrpc];;
}

+ (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure {
    NSError *error = nil;
    NSURL *xmlrpcURL = [self urlForXMLRPCFromUrl:url addXMLRPC:YES error:&error];
    if (xmlrpcURL == nil) {
        [self logExtraInfo: [error localizedDescription]];
        if (failure) {
            failure(error);
        }
        return;
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
        // Try the original given url as an XML-RPC endpoint
        // -------------------------------------------
        NSURL *originalXmlrpcURL = [self urlForXMLRPCFromUrl:url addXMLRPC:NO error:nil];
        [self logExtraInfo: @"Try the given url as an XML-RPC endpoint: %@", originalXmlrpcURL];
        [self validateXMLRPCUrl:originalXmlrpcURL success:^(NSURL *validatedXmlrpcURL){
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
            // Fetch the original url and look for the RSD link
            [self guessXMLRPCURLFromHTMLURL:originalXmlrpcURL success:success failure:failure];
        }];
    }];}

+ (void)guessXMLRPCURLFromHTMLURL:(NSURL *)htmlURL
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure {
    [self logExtraInfo:@"Fetch the original url and look for the RSD link by using RegExp"];
    NSURLRequest *request = [NSURLRequest requestWithURL:htmlURL];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        NSString *responseString = operation.responseString;
        NSArray *matches = nil;
        if (responseString) {
            NSRegularExpression *rsdURLRegExp = [NSRegularExpression regularExpressionWithPattern:@"<link\\s+rel=\"EditURI\"\\s+type=\"application/rsd\\+xml\"\\s+title=\"RSD\"\\s+href=\"([^\"]*)\"[^/]*/>" options:NSRegularExpressionCaseInsensitive error:&error];
            matches = [rsdURLRegExp matchesInString:responseString options:0 range:NSMakeRange(0, [responseString length])];
        }
        NSString *rsdURL = nil;
        if ([matches count]) {
            NSRange rsdURLRange = [[matches objectAtIndex:0] rangeAtIndex:1];
            if(rsdURLRange.location != NSNotFound)
                rsdURL = [responseString substringWithRange:rsdURLRange];
        }

        if (rsdURL == nil) {
            if (failure) {
                if (error == nil) {
                    error = [NSError errorWithDomain:WordPressXMLRPCApiErrorDomain
                                                code:WordPressXMLRPCApiInvalid
                                            userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Cannot find a valid WordPress XMLRPC endpoint", @"Message to show when not valid WordPress XMLRPC endpoint is found on the URL provided")}];
                }
                failure(error);
            }
            return;
        }
        // Try removing "?rsd" from the url, it should point to the XML-RPC endpoint
        NSString *xmlrpc = [rsdURL stringByReplacingOccurrencesOfString:@"?rsd" withString:@""];
        if (![xmlrpc isEqualToString:rsdURL]) {
            NSURL *xmlrpcURL = [NSURL URLWithString:xmlrpc];
            [self validateXMLRPCUrl:xmlrpcURL success:^(NSURL *validatedXmlrpcURL){
                if (success) {
                    success(validatedXmlrpcURL);
                }
            } failure:^(NSError *error){
                [self guessXMLRPCURLFromRSD:rsdURL success:success failure:failure];
            }];
        } else {
            [self guessXMLRPCURLFromRSD:rsdURL success:success failure:failure];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self logError:error];
        if (failure) failure(error);
    }];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

+ (void)guessXMLRPCURLFromRSD:(NSString *)rsd
                         success:(void (^)(NSURL *xmlrpcURL))success
                         failure:(void (^)(NSError *error))failure {
    [self logExtraInfo:@"Parse the RSD document at the following URL: %@", rsd];
    NSURL *rsdURL = [NSURL URLWithString:rsd];
    NSURLRequest *request = [NSURLRequest requestWithURL:rsdURL];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error;
        WPRSDParser *parser = [[WPRSDParser alloc] initWithXmlString:operation.responseString];
        NSString *parsedEndpoint = [parser parsedEndpointWithError:&error];
        if (parsedEndpoint == nil) {
            if (failure) {
                failure(error);
            }
            return;
        }
        NSString *xmlrpc = parsedEndpoint;
        NSURL *xmlrpcURL = [NSURL URLWithString:xmlrpc];
        [self logExtraInfo:@"Bingo! We found the WordPress XML-RPC element: %@", xmlrpcURL];
        [self validateXMLRPCUrl:xmlrpcURL success:^(NSURL *validatedXmlrpcURL){
            if (success) {
                success(validatedXmlrpcURL);
            }
        } failure:^(NSError *error){
            [self logError:error];
            if (failure) failure(error);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self logError:error];
        if (failure) failure(error);
    }];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}
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
