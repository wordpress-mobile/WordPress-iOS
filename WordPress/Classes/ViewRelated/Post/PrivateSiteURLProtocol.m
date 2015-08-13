#import "PrivateSiteURLProtocol.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "Blog.h"

@interface PrivateSiteURLProtocol()
@property (nonatomic, strong) NSURLConnection *connection;
@end

static NSInteger regcount = 0;
static NSString const * mutex = @"PrivateSiteURLProtocol-Mutex";
static NSString *cachedToken;

@implementation PrivateSiteURLProtocol

+ (void)registerPrivateSiteURLProtocol
{
    @synchronized(mutex) {
        if (regcount == 0) {
            [NSURLProtocol registerClass:[self class]];
        }
        regcount++;
    }
}

+ (void)unregisterPrivateSiteURLProtocol
{
    @synchronized(mutex) {
        cachedToken = nil;
        regcount--;
        if (regcount == 0) {
            [NSURLProtocol unregisterClass:[self class]];
        }
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{    
    NSString *authHeader = [request.allHTTPHeaderFields stringForKey:@"Authorization"];
    if (authHeader && [authHeader rangeOfString:@"Bearer"].location != NSNotFound){
        return NO;
    }
    if (![self requestGoesToWPComSite:request]){
        return NO;
    }
    if (![self bearerToken]) {
        return NO;
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (NSString *)bearerToken
{
    if (cachedToken) {
        return cachedToken;
    }
    // Thread Safety: Make sure we're running on the Main Thread
    if ([NSThread isMainThread]) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *service         = [[AccountService alloc] initWithManagedObjectContext:context];
        return service.defaultWordPressComAccount.authToken;
    }

    // Otherwise, let's use a Derived Context
    __block NSString *authToken     = nil;
    NSManagedObjectContext *derived = [[ContextManager sharedInstance] newDerivedContext];
    AccountService *service         = [[AccountService alloc] initWithManagedObjectContext:derived];
    
    [derived performBlockAndWait:^{
        authToken = service.defaultWordPressComAccount.authToken;
    }];
    cachedToken = authToken;
    return cachedToken;
}

+ (BOOL)requestGoesToWPComSite:(NSURLRequest *)request
{
    if ([request.URL.scheme isEqualToString:@"https"] && [request.URL.host hasSuffix:@".wordpress.com"]) {
        return YES;
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
