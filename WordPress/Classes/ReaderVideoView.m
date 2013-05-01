//
//  ReaderVideoView.m
//  WordPress
//
//  Created by Eric J on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderVideoView.h"

@interface ReaderVideoView()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *playButton;
@property (readwrite, nonatomic, strong) NSURL *contentURL;
@property (readwrite, nonatomic, strong) NSObject *content;
@property (readwrite, nonatomic, assign) ReaderVideoContentType contentType;

- (void)handlePlayButtonTapped:(id)sender;

@end

@implementation ReaderVideoView

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
NSLog(@"View: %@", self);
NSLog(@"VideoView ImageView : %@", _imageView);
}


- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
	_edgeInsets = edgeInsets;
	[self setNeedsLayout];
}


- (void)setContentURL:(NSURL *)contentURL {
	if ([[contentURL absoluteString] isEqualToString:[_contentURL absoluteString]]) {
		return;
	}
	
	_contentURL = contentURL;
	
	// Time to load a thumbnail if we have one available.
	
}


- (void)handlePlayButtonTapped:(id)sender {
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
}


- (void)setContentURL:(NSURL *)url andContent:(NSObject *)content ofType:(ReaderVideoContentType)type {
	self.contentType = type;
	self.content = content;
	self.contentURL = url;
}


- (UIImage *)image {
	return _imageView.image;
}

@end
