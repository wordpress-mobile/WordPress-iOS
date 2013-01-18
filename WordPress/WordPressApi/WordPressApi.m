//
//  WordPressApi.m
//  WordPress
//
//  Created by Jorge Bernal on 1/5/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <CTidy.h>
#import "WordPressApi.h"
#import "AFHTTPRequestOperation.h"
#import "AFXMLRPCClient.h"
#import "WPRSDParser.h"

#ifndef WPFLog
#define WPFLog(...) NSLog(__VA_ARGS__)
#endif

@interface WordPressApi ()
@property (readwrite, nonatomic, strong) NSURL *xmlrpc;
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *password;
@property (readwrite, nonatomic, strong) AFXMLRPCClient *client;
+ (void)validateXMLRPCUrl:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *error))failure;
+ (void)logExtraInfo:(NSString *)format, ...;
@end


@implementation WordPressApi {
    NSURL *_xmlrpc;
    NSString *_username;
    NSString *_password;
    AFXMLRPCClient *_client;
}
@synthesize xmlrpc = _xmlrpc;
@synthesize username = _username;
@synthesize password = _password;
@synthesize client = _client;

+ (WordPressApi *)apiWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password {
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

    self.client = [AFXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];

    return self;
}


#pragma mark - Authentication

- (void)authenticateWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [self getBlogsWithSuccess:^(NSArray *blogs) {
        if (success) {
            success();
        }
    } failure:failure];
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
    [self validateXMLRPCUrl:xmlrpcURL success:^{
        if (success) {
            success(xmlrpcURL);
        }
    } failure:^(NSError *error){
        if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
            [self logExtraInfo: [error localizedDescription]];
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
        [self validateXMLRPCUrl:xmlrpcURL success:^{
            if (success) {
                success(xmlrpcURL);
            }
        } failure:^(NSError *error){
            [self logExtraInfo:[error localizedDescription]];
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
                NSArray *matches;
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
                    CTidy *tidy = [CTidy tidy];
                    NSData *cleanedData = [tidy tidyData:operation.responseData inputFormat:CTidyFormatXML outputFormat:CTidyFormatXML encoding:@"utf8" diagnostics:nil error:&htmlError];
                    NSString *cleanedHTML = [[NSString alloc] initWithData:cleanedData encoding:NSUTF8StringEncoding];
                    if(cleanedHTML) {
                        [self logExtraInfo:@"The cleaned doc: %@", cleanedHTML];
                        NSArray *matches = [rsdURLRegExp matchesInString:cleanedHTML options:0 range:NSMakeRange(0, [cleanedHTML length])];
                        if ([matches count]) {
                            NSRange rsdURLRange = [[matches objectAtIndex:0] rangeAtIndex:1];
                            if (rsdURLRange.location != NSNotFound)
                                rsdURL = [cleanedHTML substringWithRange:rsdURLRange];
                        }
                    } else {
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
                                [self validateXMLRPCUrl:xmlrpcURL success:^{
                                    if (success) success(xmlrpcURL);
                                } failure:^(NSError *error){
                                    [self logExtraInfo: [error localizedDescription]];
                                    if (failure) failure(error);
                                }];
                            } else {
                                if (failure) failure(error);
                            }
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            [self logExtraInfo: [error localizedDescription]];
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
                        [self validateXMLRPCUrl:xmlrpcURL success:^{
                            if (success) {
                                success(xmlrpcURL);
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
                [self logExtraInfo:@"Can't fetch the original url: %@", [error localizedDescription]];
                if (failure) failure(error);
            }];
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [queue addOperation:operation];
        }];
    }];
}

#pragma mark - Private Methods

+ (void)validateXMLRPCUrl:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *error))failure {
    AFXMLRPCClient *client = [AFXMLRPCClient clientWithXMLRPCEndpoint:url];
    [client callMethod:@"system.listMethods"
            parameters:[NSArray array]
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
    WPFLog(@"[WordPressApi] < %@", message);
}

@end
