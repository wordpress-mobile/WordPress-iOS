//
//  WPImageViewController.m
//  WordPress
//
//  Created by Eric J on 5/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPImageViewController.h"
#import "WordPressAppDelegate.h"

@interface WPImageViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *url;

- (void)handleImageTapped:(UITapGestureRecognizer *)tgr;
- (void)handleImageDoubleTapped:(UITapGestureRecognizer *)tgr;

@end

@implementation WPImageViewController


+ (id)presentAsModalWithImage:(UIImage *)image {
	UIViewController *controller = [[self alloc] initWithImage:image];
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] presentViewController:controller animated:YES completion:nil];
	return controller;
}


+ (id)presentAsModalWithURL:(NSURL *)url {
	UIViewController *controller = [[self alloc] initWithURL:url];
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] presentViewController:controller animated:YES completion:nil];
	return controller;
}


+ (id)presentAsModalWithImage:(UIImage *)image andURL:(NSURL *)url {
	UIViewController *controller = [[self alloc] initWithImage:image andURL:url];
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] presentViewController:controller animated:YES completion:nil];
	return controller;
}


#pragma mark - LifeCycle Methods

- (id)initWithImage:(UIImage *)image {
	self = [self init];
	if(self) {
		self.image = [image copy];
	}
	
	return self;
}


- (id)initWithURL:(NSURL *)url {
	self = [self init];
	if(self) {
		self.url = url;
	}
	
	return self;
}


- (id)initWithImage:(UIImage *)image andURL:(NSURL *)url {
	self = [self init];
	if (self) {
		self.image = [image copy];
		self.url = url;
	}
	return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];

	CGRect frame = self.view.frame;
	frame = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
	self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
	_scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	_scrollView.maximumZoomScale = 4.0f;
	_scrollView.minimumZoomScale = 0.1f;
	_scrollView.scrollsToTop = NO;
	_scrollView.delegate = self;
	[self.view addSubview:_scrollView];
	
	self.imageView = [[UIImageView alloc] initWithFrame:frame];
	_imageView.userInteractionEnabled = YES;
	[_scrollView addSubview:_imageView];
	
	UITapGestureRecognizer *tgr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageDoubleTapped:)];
	[tgr2 setNumberOfTapsRequired:2];
	[_imageView addGestureRecognizer:tgr2];
	
	UITapGestureRecognizer *tgr1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapped:)];
	[tgr1 setNumberOfTapsRequired:1];
	[tgr1 requireGestureRecognizerToFail:tgr2];
    [_scrollView addGestureRecognizer:tgr1];
	
	if(self.image != nil) {
		_imageView.image = self.image;
		[_imageView sizeToFit];
		_scrollView.contentSize = _imageView.image.size;
		[self centerImage];
		
	} else if(self.url) {
		
		__weak UIImageView *imageViewRef = _imageView;
		__weak UIScrollView *scrollViewRef = _scrollView;
		__weak WPImageViewController *selfRef = self;
		[_imageView setImageWithURLRequest:[NSURLRequest requestWithURL:self.url]
						 placeholderImage:self.image
								  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
									  imageViewRef.image = image;
									  [imageViewRef sizeToFit];
									  scrollViewRef.contentSize = imageViewRef.image.size;
									  [selfRef centerImage];
								  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
									  // TODO: doH!
								  }];
	}
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
	[self centerImage];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self centerImage];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - Instance Methods

- (void)centerImage {
	CGFloat scaleWidth = _scrollView.frame.size.width / _imageView.image.size.width;
	CGFloat scaleHeight = _scrollView.frame.size.height / _imageView.image.size.height;

	_scrollView.minimumZoomScale = MIN(scaleWidth, scaleHeight);
	_scrollView.zoomScale = _scrollView.minimumZoomScale;

	[self scrollViewDidZoom:_scrollView];
}


- (void)handleImageTapped:(UITapGestureRecognizer *)tgr {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)handleImageDoubleTapped:(UITapGestureRecognizer *)tgr {

	if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
		[_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
		return;
	}
	
	CGPoint point = [tgr locationInView:_imageView];
	CGSize size = _scrollView.frame.size;
	
	CGFloat w = size.width / _scrollView.maximumZoomScale;
	CGFloat h = size.height / _scrollView.maximumZoomScale;
	CGFloat x = point.x - (w / 2.0f);
	CGFloat y = point.y - (h / 2.0f);
	
	CGRect rect = CGRectMake(x, y, w, h);
	[_scrollView zoomToRect:rect animated:YES];
}


#pragma mark - UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _imageView;
}


- (void)scrollViewDidZoom:(UIScrollView *)scrollView {

    CGSize size = scrollView.frame.size;
    CGRect frame = _imageView.frame;
	
    if (frame.size.width < size.width) {
        frame.origin.x = (size.width - frame.size.width) / 2;
    } else {
        frame.origin.x = 0;
	}
    
    if (frame.size.height < size.height) {
        frame.origin.y = (size.height - frame.size.height) / 2;
    } else {
        frame.origin.y = 0;
	}
	
    _imageView.frame = frame;
}


@end
