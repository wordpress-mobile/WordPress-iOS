//
//  ReaderMediaView.m
//  WordPress
//
//  Created by Eric J on 5/15/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderMediaView.h"

@implementation ReaderMediaView

#pragma mark - LifeCycle Methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.edgeInsets = UIEdgeInsetsZero;
		self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
		_imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_imageView.contentMode = UIViewContentModeScaleAspectFit;
		
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
	
	if (_imageView.image.size.width < frame.size.width && _imageView.image.size.height < frame.size.height) {
		_imageView.contentMode = UIViewContentModeCenter;
	} else {
		_imageView.contentMode = UIViewContentModeScaleAspectFill;
	}
}


#pragma mark - Instance Methods

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
				success:(void (^)(ReaderMediaView *))success
				failure:(void (^)(ReaderMediaView *, NSError *))failure {
	
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
