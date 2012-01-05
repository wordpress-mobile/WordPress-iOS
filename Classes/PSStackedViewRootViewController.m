//
//  PSStackedViewRootViewController.m
//  WordPress
//
//  Created by Brad Angelcyk on 1/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "PSStackedViewRootViewController.h"

@implementation PSStackedViewRootViewController
@synthesize blogsViewController, delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    [rootView setBackgroundColor:[UIColor clearColor]];
    
    leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panel_menu_width, self.view.frame.size.height)];
    leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    blogsViewController = [[BlogsViewController alloc] init];
    [blogsViewController.view setFrame:CGRectMake(0, 0, leftMenuView.frame.size.width, leftMenuView.frame.size.height)];
    [blogsViewController.view setBackgroundColor:[UIColor clearColor]];
    [blogsViewController viewWillAppear:FALSE];
    [blogsViewController viewDidAppear:FALSE];
    [leftMenuView addSubview:blogsViewController.view];
    
//    rightSlideView = [[UIView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, 0, rootView.frame.size.width - leftMenuView.frame.size.width, rootView.frame.size.height)];
//    rightSlideView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
//    [delegate.stackScrollViewController.view setFrame:CGRectMake(0, 0, rightSlideView.frame.size.width, rightSlideView.frame.size.height)];
//    [delegate.stackScrollViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight];
//    [delegate.stackScrollViewController viewWillAppear:FALSE];
//    [delegate.stackScrollViewController viewDidAppear:FALSE];
//    [rightSlideView addSubview:delegate.stackScrollViewController.view];
    
    [rootView addSubview:leftMenuView];
//    [rootView addSubview:rightSlideView];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"fabric.png"]]];
    [self.view addSubview:rootView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
