#import "PrivateSiteURLProtocol.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "Blog.h"

@interface PrivateSiteURLProtocol()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@end

static NSInteger regcount = 0;
static NSString const * mutex = @"PrivateSiteURLProtocol-Mutex";
static NSString *cachedToken;

@implementation PrivateSiteURLProtocol

+ (void)registerPrivateSiteURLProtocol
{    
    @synchronized(mutex) {
        if (regcount == 0) {
            if (![NSURLProtocol registerClass:[self class]]) {
                NSAssert(YES, @"Unable to register protocol");
                DDLogInfo(@"Unable to register protocol");
            }
        }
        regcount++;
    }
}

+ (void)unregisterPrivateSiteURLProtocol
{
    @synchronized(mutex) {
        cachedToken = nil;
        if (regcount > 0) {
            regcount--;
            if (regcount == 0) {
                [NSURLProtocol unregisterClass:[self class]];
            }
        } else {
            DDLogInfo(@"Detected unbalanced register/unregister private site protocol.");
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

+ (NSURLRequest *)requestForPrivateSiteFromURL:(NSURL *)url
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    //make sure the scheme used is https
    [urlComponents setScheme:@"https"];
    NSURL *httpsURL = [urlComponents URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:httpsURL];
    NSString *bearerToken = [NSString stringWithFormat:@"Bearer %@", [self bearerToken]];
    [request addValue:bearerToken forHTTPHeaderField:@"Authorization"];
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *mRequest = [self.request mutableCopy];
    [mRequest addValue:[NSString stringWithFormat:@"Bearer %@", [[self class] bearerToken]] forHTTPHeaderField:@"Authorization"];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    self.sessionTask = [self.session dataTaskWithRequest:mRequest];
    [self.sessionTask resume];
}

- (void)stopLoading
{
    [self.sessionTask cancel];
    [self.session invalidateAndCancel];
    self.sessionTask = nil;
    self.session = nil;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
    self.sessionTask = nil;
    [self.session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.sessionTask = nil;
    [self.session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

@end
