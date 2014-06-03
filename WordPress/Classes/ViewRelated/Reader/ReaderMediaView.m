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
	
	BOOL imageIsAnimated = (image.images != nil);
	
	if (imageIsAnimated)
	{
		_imageView.image = image.images[0];
		_imageView.animationImages = image.images;
		_imageView.animationDuration = image.duration;
		
		// DRM: a delay before starting the animations is necessary.  For some reason calling
		// startAnimating right away seems to cause animations not to start at all.
		//
		double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_imageView startAnimating];
        });
	}
	else
	{
		_imageView.image = image;
	}
	
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
