//
//  ReaderImageView.m
//  WordPress
//
//  Created by Eric J on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderImageView.h"

@interface ReaderImageView()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ReaderImageView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.edgeInsets = UIEdgeInsetsZero;
		self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
		_imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[self addSubview:_imageView];
		
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


- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
	_edgeInsets = edgeInsets;
	[self setNeedsLayout];
}


- (UIImage *)image {
	return _imageView.image;
}


- (void)setImage:(UIImage *)image {
	_imageView.image = image;
}


- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderImageView *))success
				failure:(void (^)(ReaderImageView *, NSError *))failure {
	
	self.contentURL = url;
	
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


@end
