#import "WPImageSource.h"
#import "WPSharedLoggingPrivate.h"

NSString * const WPImageSourceErrorDomain = @"WPImageSourceErrorDomain";

@interface WPImageSource()

@property (nonatomic, strong) NSURLSession *downloadsSession;
@property (nonatomic, strong) NSMutableSet *urlDownloadsInProgress;
@property (nonatomic, strong) NSMutableDictionary *successBlocks;
@property (nonatomic, strong) NSMutableDictionary *failureBlocks;

@end

@implementation WPImageSource

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
    [_downloadsSession invalidateAndCancel];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _urlDownloadsInProgress = [[NSMutableSet alloc] init];
        _successBlocks = [[NSMutableDictionary alloc] init];
        _failureBlocks = [[NSMutableDictionary alloc] init];

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _downloadsSession = [NSURLSession sessionWithConfiguration:configuration];
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
    
    if (![self.urlDownloadsInProgress containsObject:url]) {
        [self.urlDownloadsInProgress addObject:url];
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

        NSURLSessionDownloadTask *task = [self.downloadsSession downloadTaskWithRequest:request
            completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (error) {
                    [self downloadFailedWithError:error forURL:url];
                    return;
                }
                NSError *readError;
                NSData *data = [NSData dataWithContentsOfURL:location options:NSDataReadingUncached error:&readError];
                UIImage *image = [UIImage imageWithData:data];
                if (!image) {
                    [self downloadSucceededWithNilImageForURL:url response:response];
                    return;
                }

                [self downloadedImage:image forURL:url];
        }];
        [task resume];
    });
}

- (void)downloadedImage:(UIImage *)image forURL:(NSURL *)url
{
    NSArray *successBlocks = [self.successBlocks objectForKey:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeCallbacksForURL:url];
        for (void (^success)(UIImage *) in successBlocks) {
            success(image);
        }
    });
}

- (void)downloadFailedWithError:(NSError *)error forURL:(NSURL *)url
{
    NSArray *failureBlocks = [self.failureBlocks objectForKey:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeCallbacksForURL:url];
        for (void (^failure)(NSError *) in failureBlocks) {
            failure(error);
        }
    });
}

- (void)downloadSucceededWithNilImageForURL:(NSURL *)url response:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]){
        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
        DDLogError(@"WPImageSource download completed sucessfully but the image was nil. Headers: %@", [httpURLResponse allHeaderFields]);
    }
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
        NSArray *successBlocks = [self.successBlocks objectForKey:url];
        if (!successBlocks) {
            successBlocks = @[[success copy]];
        } else {
            successBlocks = [successBlocks arrayByAddingObject:[success copy]];
        }
        [self.successBlocks setObject:successBlocks forKey:url];
    }

    if (failure) {
        NSArray *failureBlocks = [self.failureBlocks objectForKey:url];
        if (!failureBlocks) {
            failureBlocks = @[[failure copy]];
        } else {
            failureBlocks = [failureBlocks arrayByAddingObject:[failure copy]];
        }
        [self.failureBlocks setObject:failureBlocks forKey:url];
    }
}

- (void)removeCallbacksForURL:(NSURL *)url
{
    [self.successBlocks removeObjectForKey:url];
    [self.failureBlocks removeObjectForKey:url];
    [self.urlDownloadsInProgress removeObject:url];
}

@end
