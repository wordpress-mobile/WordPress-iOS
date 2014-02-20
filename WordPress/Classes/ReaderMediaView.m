//
//  ReaderMediaView.m
//  WordPress
//
//  Created by Eric J on 5/15/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderMediaView.h"
#import "UIImageView+AFNetworkingExtra.h"

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
		[super setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}


- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
	if (UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, _edgeInsets)) {
		_imageView.frame = frame;
	} else {
		frame.size.width -= (_edgeInsets.left + _edgeInsets.right);
		frame.size.height -= (_edgeInsets.top + _edgeInsets.bottom);
		frame.origin.x = _edgeInsets.left;
		frame.origin.y = _edgeInsets.top;
	}
	_imageView.frame = frame;
}


#pragma mark - Instance Methods

- (void)setBackgroundColor:(UIColor *)backgroundColor {
	[_imageView setBackgroundColor:backgroundColor];
}

- (void)setContentMode:(UIViewContentMode)contentMode {
	[super setContentMode:contentMode];
	_imageView.contentMode = contentMode;
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
	self.isShowingPlaceholder = NO;
}


- (void)setPlaceholder:(UIImage *)image {
	_imageView.image = image;
	self.isShowingPlaceholder = YES;
}


- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderMediaView *))success
				failure:(void (^)(ReaderMediaView *, NSError *))failure {
	if (image) {
        [self setPlaceholder:image];
	}
	// Weak refs to avoid retain loop.
	__weak ReaderMediaView *selfRef = self;
	[_imageView setImageWithURL:url
			   placeholderImage:image
						success:^(UIImage *image) {
							selfRef.isShowingPlaceholder = NO;
							if (success) {
								success(selfRef);
							}
						} failure:^(NSError *error) {
							if(failure) {
								failure(selfRef, error);
							}
						}];
}


@end
