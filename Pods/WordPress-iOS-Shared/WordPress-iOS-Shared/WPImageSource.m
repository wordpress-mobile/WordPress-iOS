#import <AFNetworking/AFNetworking.h>
#import "WPImageSource.h"

#import "WPAnimatedImageResponseSerializer.h"

static int ddLogLevel = LOG_LEVEL_INFO;

NSString * const WPImageSourceErrorDomain = @"WPImageSourceErrorDomain";

@implementation WPImageSource {
    NSOperationQueue *_downloadingQueue;
    NSMutableSet *_urlDownloadsInProgress;
    NSMutableDictionary *_successBlocks;
    NSMutableDictionary *_failureBlocks;
}

+ (instancetype)sharedSource
{
    static WPImageSource *_sharedSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSource = [[WPImageSource alloc] init];
    });
    return _sharedSource;
}

- (void)dealloc
{
    [_downloadingQueue cancelAllOperations];
}

- (id)init
{
    self = [super init];
    if (self) {
        _downloadingQueue = [[NSOperationQueue alloc] init];
        _urlDownloadsInProgress = [[NSMutableSet alloc] init];
        _successBlocks = [[NSMutableDictionary alloc] init];
        _failureBlocks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)downloadImageForURL:(NSURL *)url withSuccess:(void (^)(UIImage *))success failure:(void (^)(NSError *))failure
{
    [self downloadImageForURL:url authToken:nil withSuccess:success failure:failure];
}

- (void)downloadImageForURL:(NSURL *)url authToken:(NSString *)authToken withSuccess:(void (^)(UIImage *))success failure:(void (^)(NSError *))failure {
    NSParameterAssert(url != nil);
    
    [self addCallbackForURL:url withSuccess:success failure:failure];
    
    if (![_urlDownloadsInProgress containsObject:url]) {
        [_urlDownloadsInProgress addObject:url];
        [self startDownloadForURL:url authToken:authToken];
    }
}

#pragma mark - Downloader

- (void)startDownloadForURL:(NSURL *)url authToken:(NSString *)authToken {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *requestURL = url;
        NSString *token = nil;

        /*
         If the URL is not for a WordPress.com file, pretend we don't have an auth token
         It could potentially get sent to a third party
         */
        if (authToken && [[requestURL host] hasSuffix:@"wordpress.com"]) {
            token = authToken;
        }

        if (token) {
            if (![url.absoluteString hasPrefix:@"https"]) {
                NSString *sslUrl = [url.absoluteString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                requestURL = [NSURL URLWithString:sslUrl];
            }
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        if (token) {
            [request addValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
        }

		AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
		
		operation.responseSerializer = [[WPAnimatedImageResponseSerializer alloc] init];
		operation.responseSerializer.acceptableContentTypes
			= [operation.responseSerializer.acceptableContentTypes setByAddingObject:@"image/jpg"];
		
		[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			UIImage* image = (UIImage*)responseObject;
			
			if (!image) {
				[self downloadSucceededWithNilImageForURL:url response:operation.response];
				return;
			}
			[self downloadedImage:image forURL:url];
		} failure:^(AFHTTPRequestOperation *operation, NSError *error)
		{
			[self downloadFailedWithError:error forURL:url];
		}];
		
        [_downloadingQueue addOperation:operation];
    });
}

- (void)downloadedImage:(UIImage *)image forURL:(NSURL *)url
{
    NSArray *successBlocks = [_successBlocks objectForKey:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeCallbacksForURL:url];
        for (void (^success)(UIImage *) in successBlocks) {
            success(image);
        }
    });
}

- (void)downloadFailedWithError:(NSError *)error forURL:(NSURL *)url
{
    NSArray *failureBlocks = [_failureBlocks objectForKey:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeCallbacksForURL:url];
        for (void (^failure)(NSError *) in failureBlocks) {
            failure(error);
        }
    });
}

- (void)downloadSucceededWithNilImageForURL:(NSURL *)url response:(NSHTTPURLResponse *)response
{
    DDLogError(@"WPImageSource download completed sucessfully but the image was nil. Headers: %@", [response allHeaderFields]);
    NSString *description = [NSString stringWithFormat:@"A download request ended successfully but the image was nil. URL: %@", [url absoluteString]];
    NSError *error = [NSError errorWithDomain:WPImageSourceErrorDomain
                                         code:WPImageSourceErrorNilImage
                                     userInfo:@{NSLocalizedDescriptionKey:description}];
    [self downloadFailedWithError:error forURL:url];
}

#pragma mark - Callback storage

- (void)addCallbackForURL:(NSURL *)url withSuccess:(void (^)(UIImage *))success failure:(void (^)(NSError *))failure
{
    if (success) {
        NSArray *successBlocks = [_successBlocks objectForKey:url];
        if (!successBlocks) {
            successBlocks = @[[success copy]];
        } else {
            successBlocks = [successBlocks arrayByAddingObject:[success copy]];
        }
        [_successBlocks setObject:successBlocks forKey:url];
    }

    if (failure) {
        NSArray *failureBlocks = [_failureBlocks objectForKey:url];
        if (!failureBlocks) {
            failureBlocks = @[[failure copy]];
        } else {
            failureBlocks = [failureBlocks arrayByAddingObject:[failure copy]];
        }
        [_failureBlocks setObject:failureBlocks forKey:url];
    }
}

- (void)removeCallbacksForURL:(NSURL *)url
{
    [_successBlocks removeObjectForKey:url];
    [_failureBlocks removeObjectForKey:url];
    [_urlDownloadsInProgress removeObject:url];
}

@end
