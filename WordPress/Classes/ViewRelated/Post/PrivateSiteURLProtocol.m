#import "PrivateSiteURLProtocol.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "Blog.h"

@interface PrivateSiteURLProtocol()
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation PrivateSiteURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *token = [self bearerToken];
    NSString *authHeader = [request.allHTTPHeaderFields stringForKey:@"Authorization"];
    if (token && (!authHeader || [authHeader rangeOfString:@"Bearer"].location == NSNotFound) && [self requestGoesToWPComSite:request]) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (NSString *)bearerToken
{
    NSString *token = [[self defaultWPComAccount] authToken];
    return token;
}

+ (WPAccount *)defaultWPComAccount
{
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    return [service defaultWordPressComAccount];
}

+ (BOOL)requestGoesToWPComSite:(NSURLRequest *)request
{
    if ([request.URL.host hasSuffix:@".wordpress.com"]) {
        return YES;
    }

    WPAccount *account = [self defaultWPComAccount];
    for (Blog *blog in account.blogs) {
        if (!blog.isWPcom) {
            continue;
        }
        NSURL *blogURL = [NSURL URLWithString:blog.url];
        if ([request.URL.host isEqualToString:blogURL.host]) {
            return YES;
        }
    }

    return NO;
}

- (void)startLoading
{
    NSMutableURLRequest *mRequest = [self.request mutableCopy];
    [mRequest addValue:[NSString stringWithFormat:@"Bearer %@", [[self class] bearerToken]] forHTTPHeaderField:@"Authorization"];
    self.connection = [NSURLConnection connectionWithRequest:mRequest delegate:self];
}

- (void)stopLoading
{
    [self.connection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}

@end
