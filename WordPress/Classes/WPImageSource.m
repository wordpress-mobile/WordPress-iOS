#import "WPImageSource.h"

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
        if (authToken) {
            if (![url.absoluteString hasPrefix:@"https"]) {
                NSString *sslUrl = [url.absoluteString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                requestURL = [NSURL URLWithString:sslUrl];
            }
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        if (authToken) {
            [request addValue:[NSString stringWithFormat:@"Bearer %@", authToken] forHTTPHeaderField:@"Authorization"];
        }
		// AFMIG:
		/*
        AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
                                                                                  imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                                      if (!image) {
                                                                                          [self downloadSucceededWithNilImageForURL:url response:response];
                                                                                          return;
                                                                                      }
                                                                                      [self downloadedImage:image forURL:url];
                                                                                  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                                      [self downloadFailedWithError:error forURL:url];
                                                                                  }];
		 */
		AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
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
		operation.responseSerializer = [[AFImageResponseSerializer alloc] init];
		operation.responseSerializer.acceptableContentTypes
			= [operation.responseSerializer.acceptableContentTypes setByAddingObject:@"image/jpg"];
		
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
    DDLogError(@"WPImageSource download completed sucessfully but the image was nil. Headers: ", [response allHeaderFields]);
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
