#import "VideoThumbnailServiceRemote.h"
#import "WordPressComApi.h"

@implementation VideoThumbnailServiceRemote

+ (AFHTTPRequestOperationManager *)sharedYoutubeClient {
	static AFHTTPRequestOperationManager *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
		_sharedClient = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://gdata.youtube.com"]];
	});
	return _sharedClient;
}


+ (AFHTTPRequestOperationManager *)sharedVimeoClient {
	static AFHTTPRequestOperationManager *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
		_sharedClient = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://vimeo.com"]];
	});
	return _sharedClient;
}


+ (AFHTTPRequestOperationManager *)sharedDailyMotionClient {
	static AFHTTPRequestOperationManager *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
		_sharedClient = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.dailymotion.com"]];
	});
	return _sharedClient;
}


- (void)getThumbnailForVideoAtURL:(NSURL *)url
                          success:(void (^)(NSURL *thumbnailURL, NSString *title))success
                          failure:(void (^)(NSError *error))failure
{
    // correct for relative URLs
    if ([url.absoluteString hasPrefix:@"//"]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http:%@", url]];
    }

	NSString *path = [url path];
	NSRange rng = [path rangeOfString:@"/" options:NSBackwardsSearch];
	NSString *vidId = [path substringFromIndex:rng.location + 1];

    NSString *absolutePath = [url absoluteString];

    if ([absolutePath rangeOfString:@"youtube.com/embed"].location != NSNotFound) {
        [self getYoutubeThumb:vidId success:success failure:failure];

    } else if([absolutePath rangeOfString:@"videos.files.wordpress.com"].location != NSNotFound ||
              [absolutePath rangeOfString:@"videos.videopress.com"].location != NSNotFound) {
        [self getVideoPressThumb:url success:success failure:failure];

    } else if ([absolutePath rangeOfString:@"vimeo.com/video"].location != NSNotFound) {
        [self getVimeoThumb:vidId success:success failure:failure];

    } else if ([absolutePath rangeOfString:@"dailymotion.com/embed/video"].location != NSNotFound) {
        [self getDailyMotionThumb:vidId success:success failure:failure];

    } else if (failure) {
        NSError *error;
        failure(error);
    }
}


- (void)getYoutubeThumb:(NSString *)vidId
                success:(void (^)(NSURL *thumbnailURL, NSString *title))success
                failure:(void (^)(NSError *error))failure
{
	NSString *path = [NSString stringWithFormat:@"/feeds/api/videos/%@?v=2&alt=json", vidId];
	[[[self class] sharedYoutubeClient] GET:path
                                 parameters:nil
                                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        if (!success) {
                                            return;
                                        }

                                        NSDictionary *dict = (NSDictionary *)responseObject;
                                        NSString *title = [dict stringForKeyPath:@"entry.media$group.media$title.$t"];
                                        NSArray *thumbs = [dict objectForKeyPath:@"entry.media$group.media$thumbnail"];
                                        NSDictionary *thumb = [thumbs objectAtIndex:0];
                                        for (NSDictionary *item in thumbs) {
                                            if ([[item numberForKey:@"width"] integerValue] > [[thumb numberForKey:@"width"] integerValue]) {
                                                thumb = item;
                                            }
                                        }
                                        NSString *thumbPath = [thumb stringForKey:@"url"];
                                        NSURL *url = [NSURL URLWithString:thumbPath];
                                        success(url, title);

                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        if (failure) {
                                            failure(error);
                                        }
                                    }];
    
}


- (void)getVideoPressThumb:(NSURL *)url
                   success:(void (^)(NSURL *thumbnailURL, NSString *title))success
                   failure:(void (^)(NSError *error))failure
{

    NSString *urlHost = [url host];
    NSString *urlPath = [[url path] stringByReplacingOccurrencesOfString:@".mp4" withString:@".original.jpg?w=640"];
    NSString *path = [NSString stringWithFormat:@"http://i0.wp.com/%@%@", urlHost, urlPath];

    NSURL *thumbURL = [NSURL URLWithString:path];
    success(thumbURL, nil);
}


- (void)getVimeoThumb:(NSString *)vidId
              success:(void (^)(NSURL *thumbnailURL, NSString *title))success
              failure:(void (^)(NSError *error))failure
{

	NSString *path = [NSString stringWithFormat:@"/api/v2/video/%@.json", vidId];
	[[[self class] sharedVimeoClient] GET:path
                               parameters:nil
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      if (!success) {
                                          return;
                                      }

                                      NSArray *arr = (NSArray *)responseObject;
                                      NSDictionary *dict = [arr objectAtIndex:0];
                                      NSString *title = [dict stringForKey:@"title"];
                                      NSString *thumbPath = [dict objectForKey:@"thumbnail_large"];
                                      NSURL *url = [NSURL URLWithString:thumbPath];
                                      success(url, title);

                                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      if (failure) {
                                          failure(error);
                                      }
                                  }];
}


- (void)getDailyMotionThumb:(NSString *)vidId
                    success:(void (^)(NSURL *thumbnailURL, NSString *title))success
                    failure:(void (^)(NSError *error))failure
{
	NSString *path = [NSString stringWithFormat:@"/video/%@?fields=thumbnail_large_url", vidId];
	[[[self class] sharedDailyMotionClient] GET:path
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            if (!success) {
                                                return;
                                            }

                                            NSDictionary *dict = (NSDictionary *)responseObject;
                                            NSString *thumbPath = [dict objectForKey:@"thumbnail_large_url"];
                                            NSURL *url = [NSURL URLWithString:thumbPath];

                                            success(url, nil);

                                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                            if (failure) {
                                                failure(error);
                                            }
                                        }];
}

@end
