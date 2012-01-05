//
//  WordPressApi.m
//  WordPress
//
//  Created by Jorge Bernal on 1/5/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WordPressApi.h"
#import "AFHTTPRequestOperation.h"
#import "AFXMLRPCClient.h"
#import "TouchXML.h"
#import "RegexKitLite.h"

@interface WordPressApi ()
@property (readwrite, nonatomic, retain) NSURL *xmlrpc;
@property (readwrite, nonatomic, retain) NSString *username;
@property (readwrite, nonatomic, retain) NSString *password;
@property (readwrite, nonatomic, retain) AFXMLRPCClient *client;

+ (void)validateXMLRPCUrl:(NSURL *)url success:(void (^)())success failure:(void (^)())failure;
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
    return [[[self alloc] initWithXMLRPCEndpoint:xmlrpc username:username password:password] autorelease];
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

- (void)dealloc {
    [_xmlrpc release];
    [_username release];
    [_password release];
    [_client release];
    [super dealloc];
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
                      failure:(void (^)())failure {
    __block NSURL *xmlrpcURL;
    __block NSString *xmlrpc;
    // ------------------------------------------------
    // 0. Is an empty url? Sorry, no psychic powers yet
    // ------------------------------------------------
    if (url == nil || [url isEqualToString:@""]) {
        return failure ? failure() : nil;
    }
    
    // ------------------------------------------------------------------------
    // 1. Assume the given url is the home page and XML-RPC sits at /xmlrpc.php
    // ------------------------------------------------------------------------
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
        return failure ? failure() : nil;
    }
    [self validateXMLRPCUrl:xmlrpcURL success:^{
        if (success) {
            success(xmlrpcURL);
        }
    } failure:^{
        // -------------------------------------------
        // 2. Try the given url as an XML-RPC endpoint
        // -------------------------------------------
        xmlrpcURL = [NSURL URLWithString:url];
        [self validateXMLRPCUrl:xmlrpcURL success:^{
            if (success) {
                success(xmlrpcURL);
            }
        } failure:^{
            // ---------------------------------------------------
            // 3. Fetch the original url and look for the RSD link
            // ---------------------------------------------------
            NSURLRequest *request = [NSURLRequest requestWithURL:xmlrpcURL];
            AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString *rsdURL = [operation.responseString stringByMatching:@"<link rel=\"EditURI\" type=\"application/rsd\\+xml\" title=\"RSD\" href=\"([^\"]*)\"[^/]*/>" capture:1];

                if (rsdURL == nil) {
                    //the RSD link not found using RegExp, try to find it again on a "cleaned" HTML document
                    NSError *htmlError;
                    CXMLDocument *rsdHTML = [[[CXMLDocument alloc] initWithXMLString:operation.responseString options:CXMLDocumentTidyXML error:&htmlError] autorelease];
                    if(!htmlError) {
                        NSString *cleanedHTML = [rsdHTML XMLStringWithOptions:CXMLDocumentTidyXML];
                        rsdURL = [cleanedHTML stringByMatching:@"<link rel=\"EditURI\" type=\"application/rsd\\+xml\" title=\"RSD\" href=\"([^\"]*)\"[^/]*/>" capture:1];
                    }
                }
                
                if (rsdURL != nil) {
                    void (^parseBlock)(void) = ^() {
                        // -------------------------
                        // 5. Parse the RSD document
                        // -------------------------
                        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:rsdURL]];
                        AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
                        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                            NSError *rsdError;
                            CXMLDocument *rsdXML = [[[CXMLDocument alloc] initWithXMLString:operation.responseString options:CXMLDocumentTidyXML error:&rsdError] autorelease];
                            if (!rsdError) {
                                @try {
                                    CXMLElement *serviceXML = [[[rsdXML rootElement] children] objectAtIndex:1];
                                    for(CXMLElement *api in [[[serviceXML elementsForName:@"apis"] objectAtIndex:0] elementsForName:@"api"]) {
                                        if([[[api attributeForName:@"name"] stringValue] isEqualToString:@"WordPress"]) {
                                            // Bingo! We found the WordPress XML-RPC element
                                            xmlrpc = [[api attributeForName:@"apiLink"] stringValue];
                                            xmlrpcURL = [NSURL URLWithString:xmlrpc];
                                            [self validateXMLRPCUrl:xmlrpcURL success:^{
                                                if (success) success(xmlrpcURL);
                                            } failure:^{
                                                if (failure) failure();
                                            }];
                                        }
                                    }
                                }
                                @catch (NSException *exception) {
                                    if (failure) failure();
                                }
                            }
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            if (failure) failure();
                        }];
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
                        } failure:^{
                            parseBlock();
                        }];
                    } else {
                        parseBlock();
                    }
                } else {
                    if (failure)
                        failure();
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure) failure();
            }];
            NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
            [queue addOperation:operation];
        }];
    }];
}

#pragma mark - Private Methods

+ (void)validateXMLRPCUrl:(NSURL *)url success:(void (^)())success failure:(void (^)())failure {
    AFXMLRPCClient *client = [AFXMLRPCClient clientWithXMLRPCEndpoint:url];
    [client callMethod:@"system.listMethods"
            parameters:[NSArray array]
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (success) {
                       success();
                   }
               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   if (failure) {
                       failure();
                   }
               }];
}

@end
