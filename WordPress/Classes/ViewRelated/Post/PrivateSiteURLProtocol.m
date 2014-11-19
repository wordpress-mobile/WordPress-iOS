#import "PrivateSiteURLProtocol.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"

@interface PrivateSiteURLProtocol()
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation PrivateSiteURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *token = [self bearerToken];
    NSString *authHeader = [request.allHTTPHeaderFields stringForKey:@"Authorization"];
    if (token && (!authHeader || [authHeader rangeOfString:@"Bearer"].location == NSNotFound)) {
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
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSString *token = [[service defaultWordPressComAccount] authToken];
    return token;
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
