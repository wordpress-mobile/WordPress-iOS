//
//  ViewController.m
//  DTAnimatedGIF Demo
//
//  Created by Oliver Drobnik on 7/2/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "GIFViewController.h"
#import "DTAnimatedGIF.h"

@interface GIFViewController ()

@end

@implementation GIFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
//	UIImage *image = [UIImage imageNamed:@"simpson20.gif"];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"simpson20" ofType:@"gif"];
	
	self.imageView.image = DTAnimatedGIFFromFile(path);
	
	[self.imageView startAnimating];
}


@end
