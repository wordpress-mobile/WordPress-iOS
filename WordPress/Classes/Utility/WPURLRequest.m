#import "WPURLRequest.h"
#import "NSString+Helpers.h"


@implementation WPURLRequest

+ (NSURLRequest *)requestWithURL:(NSURL *)url userAgent:(NSString *)userAgent
{
    return [self mutableRequestWithURL:url userAgent:userAgent];
}

+ (NSURLRequest *)requestForAuthenticationWithURL:(NSURL *)loginUrl
                                      redirectURL:(NSURL *)redirectURL
                                         username:(NSString *)username
                                         password:(NSString *)password
                                      bearerToken:(NSString *)bearerToken
                                        userAgent:(NSString *)userAgent
{
    NSParameterAssert(loginUrl);
    NSParameterAssert(redirectURL);
    NSParameterAssert(username);
    NSParameterAssert(password != nil || bearerToken != nil);
    
    NSMutableURLRequest *request = [self mutableRequestWithURL:loginUrl userAgent:userAgent];

    NSString *hostname = [loginUrl host];
    if (![hostname isEqualToString:@"wordpress.com"] && ![hostname hasSuffix:@".wordpress.com"]) {
        // Let's make sure we don't send OAuth2 tokens outside of wordpress.com
        bearerToken = nil;
    }
    
    // If we've got a token, let's make sure the password never gets sent
    NSString *encodedPassword = bearerToken.length == 0 ? [password stringByUrlEncoding] : nil;
    encodedPassword = encodedPassword ?: [NSString string];
    
    // Method!
    [request setHTTPMethod:@"POST"];
    
    // Auth Body
    NSString *requestBody = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@",
                             @"log", [username stringByUrlEncoding],
                             @"pwd", encodedPassword,
                             @"redirect_to", [redirectURL.absoluteString stringByUrlEncoding]];
    
    request.HTTPBody = [requestBody dataUsingEncoding:NSUTF8StringEncoding];
    
    // Auth Headers
    [request setValue:[NSString stringWithFormat:@"%d", requestBody.length] forHTTPHeaderField:@"Content-Length"];
    [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    
    // Bearer Token
    if (bearerToken) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", bearerToken] forHTTPHeaderField:@"Authorization"];
    }
    
    return request;
}

#pragma mark - Private Methods

+ (NSMutableURLRequest *)mutableRequestWithURL:(NSURL *)url userAgent:(NSString *)userAgent
{
    NSParameterAssert(url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    if (userAgent) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    return request;
}

@end
