#import "WPWebBridge.h"
#import <CommonCrypto/CommonDigest.h>
#import "UIDevice+WordPressIdentifier.h"

static NSString *const HybridTokenSetting = @"WPWebAppHybridAuthToken";
static NSString *const AuthorizedHybridHost = @"en.wordpress.com";

@implementation WPWebBridge

@synthesize delegate;

+ (WPWebBridge *)bridge {
    WPWebBridge *bridge = [[WPWebBridge alloc] init];
    return bridge;
}

/*
 Adds a token to the querystring of the request and to a request header
 so the HTML portion can authenticate when requesting to call native methods
 */
- (NSURLRequest *)authorizeHybridRequest:(NSMutableURLRequest *)request {
    if( [[self class] isValidHybridURL:request.URL] ){
        // add the token
        request.URL = [[self class] authorizeHybridURL:request.URL];
        [request addValue:self.hybridAuthToken forHTTPHeaderField:@"X-WP-HYBRID-AUTH-TOKEN"];
    }
    return request;
}

+ (NSURL *)authorizeHybridURL:(NSURL *)url
{
    NSString *absoluteURL = [url absoluteString];
    NSString *newURL;
    if ( [absoluteURL rangeOfString:@"?"].location == NSNotFound ){
        // append the query with ?
        newURL = [absoluteURL stringByAppendingFormat:@"?wpcom-hybrid-auth-token=%@", self.hybridAuthToken];
    }else {
        // append the query with &
        newURL = [absoluteURL stringByAppendingFormat:@"&wpcom-hybrid-auth-token=%@", self.hybridAuthToken];
        
    }
    return [NSURL URLWithString:newURL];
    
}

+ (BOOL) isValidHybridURL:(NSURL *)url {
    return [url.host isEqualToString:AuthorizedHybridHost];
}

- (BOOL)requestIsValidHybridRequest:(NSURLRequest *)request {
    
    return [request.URL.host isEqualToString:AuthorizedHybridHost];
    
}

- (NSString *)hybridAuthToken
{
    return [[self class] hybridAuthToken];
}

+ (NSString *)hybridAuthToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults stringForKey:HybridTokenSetting];
    if (token == nil)
    {
        NSString *concat = [NSString stringWithFormat:@"%@--%d", [[UIDevice currentDevice] wordpressIdentifier], arc4random()];
        const char *concat_str = [concat UTF8String];
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5(concat_str, (CC_LONG)strlen(concat_str), result);
        NSMutableString *hash = [NSMutableString string];
        for (int i = 0; i < 16; i++)
            [hash appendFormat:@"%02X", result[i]];
        token = [hash lowercaseString];
        DDLogInfo(@"Generating new hybrid token: %@", token);
        [defaults setValue:token forKey:HybridTokenSetting];
        [defaults synchronize];
        
    }
    return token;
}

#pragma mark - Hybrid Bridge

- (BOOL)handlesRequest:(NSURLRequest *)request {
    
    
    if ( [request.URL.scheme isEqualToString:@"wpios"] && [request.URL.host isEqualToString:@"batch"] ){
        [self executeBatchFromRequest:request];
        return YES;
    }
    
    return NO;

}
/*
 
 Workhorse for the JavaScript to Obj-C bridge
 The payload QS variable is JSON that is url encoded.
 
 This decodes and parses the JSON into a Obj-C object and
 uses the properties to create an NSInvocation that fires
 in the context of the controller.
 
 */
-(void)executeBatchFromRequest:(NSURLRequest *)request {
    if (self.delegate == nil) {
        return;
    }
    NSURL *url = request.URL;
    
    NSArray *components = [url.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:[components count]];
    [components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *pair = [obj componentsSeparatedByString:@"="];
        [params setValue:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
    }];
    
    NSString *payload_data = [(NSString *)[params objectForKey:@"payload"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (![self.hybridAuthToken isEqualToString:[params objectForKey:@"wpcom-hybrid-auth-token"]]) {
        DDLogError(@"Invalid hybrid token received %@ (expected: %@)", [params objectForKey:@"wpcom-hybrid-auth-token"], self.hybridAuthToken);
        return;
    }
    
    id payload = [NSJSONSerialization JSONObjectWithData:[payload_data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    [payload enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *action = (NSDictionary *)obj;
        NSArray *args = (NSArray *)[action objectForKey:@"args"];
        NSString *method = (NSString *)[action objectForKey:@"method"];
        NSString *methodName = [method stringByPaddingToLength:([method length] + [args count]) withString:@":" startingAtIndex:0];
        SEL aSelector = NSSelectorFromString(methodName);
        NSMethodSignature *signature = [[self.delegate class] instanceMethodSignatureForSelector:aSelector];
        NSInvocation *invocation = nil;
        if (signature) {
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation retainArguments];
            invocation.selector = aSelector;
            invocation.target = self.delegate;
            [args enumerateObjectsUsingBlock:^(__unsafe_unretained id obj, NSUInteger idx, BOOL *stop) {
                [invocation setArgument:&obj atIndex:idx + 2];
            }];
        }
        
        if (invocation && [self.delegate respondsToSelector:aSelector]) {
            @try {
                [invocation invoke];
                DDLogInfo(@"Hybrid: %@ %@", self.delegate, methodName);
            }
            @catch (NSException *exception) {
                DDLogError(@"Hybrid exception on %@ %@", self.delegate, methodName);
                DDLogError(@"%@ %@", [exception name], [exception reason]);
                DDLogError(@"%@", [[exception callStackSymbols] componentsJoinedByString:@"\n"]);
            }
        } else {
            DDLogWarn(@"Hybrid controller doesn't know how to run method: %@ %@", self.delegate, methodName);
        }
        
    }];
    
}


@end
