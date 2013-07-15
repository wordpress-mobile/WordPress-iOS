//
//  ReaderVideoView.m
//  WordPress
//
//  Created by Eric J on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderVideoView.h"
#import "WordPressComApi.h"

@interface ReaderVideoView()

@property (readwrite, nonatomic, assign) ReaderVideoContentType contentType;

+ (AFHTTPClient *)sharedYoutubeClient;
+ (AFHTTPClient *)sharedVimeoClient;
+ (AFHTTPClient *)sharedDailyMotionClient;

- (void)getYoutubeThumb:(NSString *)vidId
				success:(void (^)(id videoView))success
				failure:(void (^)(id videoView, NSError *error))failure;
- (void)getVimeoThumb:(NSString *)vidId
			  success:(void (^)(id videoView))success
			  failure:(void (^)(id videoView, NSError *error))failure;
- (void)getDailyMotionThumb:(NSString *)vidId
					success:(void (^)(id videoView))success
					failure:(void (^)(id videoView, NSError *error))failure;

@end

@implementation ReaderVideoView

+ (AFHTTPClient *)sharedYoutubeClient {
	static AFHTTPClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
		_sharedClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://gdata.youtube.com"]];
	});
	return _sharedClient;
}


+ (AFHTTPClient *)sharedVimeoClient {
	static AFHTTPClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
		_sharedClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://vimeo.com"]];
	});
	return _sharedClient;
}


+ (AFHTTPClient *)sharedDailyMotionClient {
	static AFHTTPClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
		_sharedClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://api.dailymotion.com"]];
	});
	return _sharedClient;
}


#pragma mark - Lifecycle Methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self.imageView setImage:[UIImage imageNamed:@"wp_vid_placeholder"]];
		self.isShowingPlaceholder = YES;
    }
    return self;
}


#pragma mark - Instance Methods

- (void)setContentURL:(NSURL *)url
			   ofType:(ReaderVideoContentType)type
			  success:(void (^)(id videoView))success
			  failure:(void (^)(id videoView, NSError *error))failure {
	
	self.contentType = type;
	self.contentURL = url;

	NSString *path = [self.contentURL path];
	NSRange rng = [path rangeOfString:@"/" options:NSBackwardsSearch];
	NSString *vidId = [path substringFromIndex:rng.location + 1];
	
	if (NSNotFound != [[self.contentURL absoluteString] rangeOfString:@"youtube.com/embed"].location) {
		[self getYoutubeThumb:vidId success:success failure:failure];
	} else if (NSNotFound != [[self.contentURL absoluteString] rangeOfString:@"vimeo.com/video"].location) {
		[self getVimeoThumb:vidId success:success failure:failure];
	} else if (NSNotFound != [[self.contentURL absoluteString] rangeOfString:@"dailymotion.com/embed/video"].location) {
		[self getDailyMotionThumb:vidId success:success failure:failure];
	}

}


- (void)getYoutubeThumb:(NSString *)vidId
				success:(void (^)(id videoView))success
				failure:(void (^)(id videoView, NSError *error))failure {
	
	__weak ReaderVideoView *selfRef = self;
	NSString *path = [NSString stringWithFormat:@"/feeds/api/videos/%@?v=2&alt=json", vidId];
	[[ReaderVideoView sharedYoutubeClient] getPath:path
										parameters:nil
										   success:^(AFHTTPRequestOperation *operation, id responseObject) {
											   
											   NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
											   NSDictionary *mediaGroup = [[dict objectForKey:@"entry"] objectForKey:@"media$group"];
											   
											   selfRef.title = [[mediaGroup objectForKey:@"media$title"] objectForKey:@"$t"];
											   
											   NSArray *thumbs = [mediaGroup objectForKey:@"media$thumbnail"];
											   NSDictionary *thumb = [thumbs objectAtIndex:3];
											   NSString *url = [thumb objectForKey:@"url"];
											   [selfRef setImageWithURL:[NSURL URLWithString:url]
													   placeholderImage:[UIImage imageNamed:@"wp_vid_placeholder.png"]
																success:success
																failure:failure];
											   
										   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
											   if (failure) {
												   failure(selfRef, error);
											   }
										   }];

}


- (void)getVimeoThumb:(NSString *)vidId
			  success:(void (^)(id videoView))success
			  failure:(void (^)(id videoView, NSError *error))failure {

	__weak ReaderVideoView *selfRef = self;
	NSString *path = [NSString stringWithFormat:@"/api/v2/video/%@.json", vidId];
	[[ReaderVideoView sharedVimeoClient] getPath:path
									  parameters:nil
										 success:^(AFHTTPRequestOperation *operation, id responseObject) {
											 
											 NSArray *arr = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
											 NSDictionary *dict = [arr objectAtIndex:0];
											 selfRef.title = [dict objectForKey:@"title"];
											 NSString *url = [dict objectForKey:@"thumbnail_large"];
											 [selfRef setImageWithURL:[NSURL URLWithString:url]
													 placeholderImage:[UIImage imageNamed:@"wp_vid_placeholder.png"]
															  success:success
															  failure:failure];
											 
										 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
											 if (failure) {
												 failure(selfRef, error);
											 }
										 }];
}


- (void)getDailyMotionThumb:(NSString *)vidId
					success:(void (^)(id videoView))success
					failure:(void (^)(id videoView, NSError *error))failure {
	
	__weak ReaderVideoView *selfRef = self;
	NSString *path = [NSString stringWithFormat:@"/video/%@?fields=thumbnail_large_url", vidId];
	[[ReaderVideoView sharedDailyMotionClient] getPath:path
											parameters:nil
											   success:^(AFHTTPRequestOperation *operation, id responseObject) {
												   
												   NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
												   NSString *url = [dict objectForKey:@"thumbnail_large_url"];
												   [selfRef setImageWithURL:[NSURL URLWithString:url]
														   placeholderImage:[UIImage imageNamed:@"wp_vid_placeholder.png"]
																	success:success
																	failure:failure];
												   
											   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
												   if (failure) {
													   failure(selfRef, error);
												   }
											   }];
}

@end
