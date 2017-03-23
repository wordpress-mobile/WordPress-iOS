#import "PrivateSiteURLProtocol.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "Blog.h"

@interface PrivateSiteURLProtocolSession: NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (instancetype) sharedInstance;
- (NSURLSessionTask *)createSessionTaskForRequest:(NSURLRequest *)request forProtocol:(NSURLProtocol *)protocol;
- (void)stopSessionTask:(NSURLSessionTask *)sessionTask;

@end

@interface PrivateSiteURLProtocol()

@property (nonatomic, strong) NSURLSessionTask *sessionTask;

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
    self.sessionTask = [[PrivateSiteURLProtocolSession sharedInstance] createSessionTaskForRequest:mRequest forProtocol:self];

}

- (void)stopLoading
{
    [[PrivateSiteURLProtocolSession sharedInstance] stopSessionTask:self.sessionTask];
    self.sessionTask = nil;
}

@end

@interface PrivateSiteURLProtocolSession()

@property (nonatomic, strong) NSMutableDictionary *taskToProtocolMapping;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation PrivateSiteURLProtocolSession

+ (instancetype) sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _taskToProtocolMapping = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSURLSession *)session
{
    if (_session == nil) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    }
    return _session;
}

- (NSURLSessionTask *)createSessionTaskForRequest:(NSURLRequest *)request forProtocol:(NSURLProtocol *)protocol
{
    NSURLSessionTask *sessionTask = [self.session dataTaskWithRequest:request];
    [sessionTask resume];

    self.taskToProtocolMapping[sessionTask] = protocol;
    return sessionTask;
}

- (void)stopSessionTask:(NSURLSessionTask *)sessionTask
{
    if (sessionTask == nil) {
        return;
    }
    [self.taskToProtocolMapping removeObjectForKey:sessionTask];

    [sessionTask cancel];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSURLProtocol *protocol = self.taskToProtocolMapping[dataTask];
    id<NSURLProtocolClient> client = protocol.client;

    [client URLProtocol:protocol didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSURLProtocol *protocol = self.taskToProtocolMapping[task];
    id<NSURLProtocolClient> client = protocol.client;

    if (error) {
        [client URLProtocol:protocol didFailWithError:error];
    } else {
        [client URLProtocolDidFinishLoading:protocol];
    }
    [self.taskToProtocolMapping removeObjectForKey:task];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    if (session == _session) {
        _session = nil;
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSURLProtocol *protocol = self.taskToProtocolMapping[dataTask];
    id<NSURLProtocolClient> client = protocol.client;

    [client URLProtocol:protocol didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSURLProtocol *protocol = self.taskToProtocolMapping[task];
    id<NSURLProtocolClient> client = protocol.client;

    [client URLProtocol:protocol wasRedirectedToRequest:request redirectResponse:response];
    completionHandler(nil);
}

@end
