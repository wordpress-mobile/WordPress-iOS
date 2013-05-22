//
//  FullscreenImageBrowserViewController.m
//  WordPress
//
//  Created by Maxime Biais on 20/05/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "FullscreenImageBrowserViewController.h"

@interface FullscreenImageBrowserViewController ()

@end

@implementation FullscreenImageBrowserViewController


#pragma mark -
#pragma mark Rotation Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark Lifecycle Methods

- (id)init {
    self = [super init];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Single tap gesture to dismiss the view
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    imageView = nil;
}

#pragma mark -
#pragma mark Instance Methods

- (void)setImage:(UIImage *)image {
    imageView.image = image;
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

@end
