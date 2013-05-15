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

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *playButton;
@property (readwrite, nonatomic, strong) NSURL *contentURL;
@property (readwrite, nonatomic, assign) ReaderVideoContentType contentType;

+ (AFHTTPClient *)sharedYoutubeClient;
+ (AFHTTPClient *)sharedVimeoClient;
+ (AFHTTPClient *)sharedDailyMotionClient;

- (void)handlePlayButtonTapped:(id)sender;
- (void)getYoutubeThumb:(NSString *)vidId
				success:(void (^)(ReaderVideoView *videoView))success
				failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure;
- (void)getVimeoThumb:(NSString *)vidId
			  success:(void (^)(ReaderVideoView *videoView))success
			  failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure;
- (void)getDailyMotionThumb:(NSString *)vidId
					success:(void (^)(ReaderVideoView *videoView))success
					failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure;

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
		frame.origin.x = 0.0f;
		frame.origin.y = 0.0f;
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
		[_imageView setImage:[UIImage imageNamed:@"reader-video-placholder.png"]];
		_imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_imageView.backgroundColor = [UIColor blackColor];
		[self addSubview:_imageView];
		
		self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_playButton.frame = frame;
		_playButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_playButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
		[_playButton setImage:[UIImage imageNamed:@""] forState:UIControlStateHighlighted];
		[_playButton addTarget:self action:@selector(handlePlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}


- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
	if (UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, _edgeInsets)) {
		_imageView.frame = frame;
	} else {
		CGFloat width = frame.size.width - (_edgeInsets.left + _edgeInsets.right);
		frame.size.width = width;
		frame.origin.x = _edgeInsets.left;
	}
	_imageView.frame = frame;
}


#pragma mark - Instance Methods

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
	_edgeInsets = edgeInsets;
	[self setNeedsLayout];
}


- (void)handlePlayButtonTapped:(id)sender {
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
}


- (UIImage *)image {
	return _imageView.image;
}


- (void)setContentURL:(NSURL *)url
			   ofType:(ReaderVideoContentType)type
			  success:(void (^)(ReaderVideoView *videoView))success
			  failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure {
	
	self.contentType = type;
	self.contentURL = url;
	
	NSString *path = [_contentURL path];
	NSRange rng = [path rangeOfString:@"/" options:NSBackwardsSearch];
	NSString *vidId = [path substringFromIndex:rng.location + 1];
	
	if (NSNotFound != [[_contentURL absoluteString] rangeOfString:@"youtube.com/embed"].location) {
		[self getYoutubeThumb:vidId success:success failure:failure];
	} else if (NSNotFound != [[_contentURL absoluteString] rangeOfString:@"vimeo.com/video"].location) {
		[self getVimeoThumb:vidId success:success failure:failure];
	} else if (NSNotFound != [[_contentURL absoluteString] rangeOfString:@"dailymotion.com/embed/video"].location) {
		[self getDailyMotionThumb:vidId success:success failure:failure];
	}

}


- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderVideoView *videoView))success
				failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure {
	
	// Weak refs to avoid retain loop.
	__weak id selfRef = self;
	__weak UIImageView *imageViewRef = _imageView;
	
	void (^_success)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		imageViewRef.image = image;
		if (success) {
			success(selfRef);
		}
	};
	
	void (^_failure)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		if(failure) {
			failure(selfRef, error);
		}
	};
	
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[_imageView setImageWithURLRequest:req placeholderImage:image success:_success failure:_failure];
}


- (void)getYoutubeThumb:(NSString *)vidId
				success:(void (^)(ReaderVideoView *videoView))success
				failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure {
	
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
											   [selfRef setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil success:success failure:failure];
											   
										   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
											   if (failure) {
												   failure(selfRef, error);
											   }
										   }];

}


- (void)getVimeoThumb:(NSString *)vidId
			  success:(void (^)(ReaderVideoView *videoView))success
			  failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure {

	__weak ReaderVideoView *selfRef = self;
	NSString *path = [NSString stringWithFormat:@"/api/v2/video/%@.json", vidId];
	[[ReaderVideoView sharedVimeoClient] getPath:path
									  parameters:nil
										 success:^(AFHTTPRequestOperation *operation, id responseObject) {
											 
											 NSArray *arr = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
											 NSDictionary *dict = [arr objectAtIndex:0];
											 selfRef.title = [dict objectForKey:@"title"];
											 NSString *url = [dict objectForKey:@"thumbnail_large"];
											 [selfRef setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil success:success failure:failure];
											 
										 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
											 if (failure) {
												 failure(selfRef, error);
											 }
										 }];
}


- (void)getDailyMotionThumb:(NSString *)vidId
					success:(void (^)(ReaderVideoView *videoView))success
					failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure {
	
	__weak ReaderVideoView *selfRef = self;
	NSString *path = [NSString stringWithFormat:@"/video/%@?fields=thumbnail_large_url", vidId];
	[[ReaderVideoView sharedDailyMotionClient] getPath:path
											parameters:nil
											   success:^(AFHTTPRequestOperation *operation, id responseObject) {
												   
												   NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
												   NSString *url = [dict objectForKey:@"thumbnail_large_url"];
												   [selfRef setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil success:success failure:failure];
												   
											   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
												   if (failure) {
													   failure(selfRef, error);
												   }
											   }];
}

@end
