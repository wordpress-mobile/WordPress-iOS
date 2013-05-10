//
//  WPImageViewController.m
//  WordPress
//
//  Created by Eric J on 5/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPImageViewController.h"
#import "WordPressAppDelegate.h"

@interface WPImageViewController ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *url;

- (void)handleImageTapped:(id)sender;

@end

@implementation WPImageViewController


+ (id)presentAsModalWithImage:(UIImage *)image {
	UIViewController *controller = [[self alloc] initWithImage:image];
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] presentModalViewController:controller animated:YES];
	return controller;
}


+ (id)presentAsModalWithURL:(NSURL *)url {
	UIViewController *controller = [[self alloc] initWithURL:url];
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] presentModalViewController:controller animated:YES];
	return controller;
}


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


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
	CGRect frame = self.view.frame;
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	imageView.userInteractionEnabled = YES;
	if(self.image != nil) {
		imageView.image = self.image;
	} else if(self.url) {
		[imageView setImageWithURL:self.url];
	}

	UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapped:)];
	[imageView addGestureRecognizer:tgr];
	
	[self.view addSubview:imageView];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


- (void)handleImageTapped:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


@end
