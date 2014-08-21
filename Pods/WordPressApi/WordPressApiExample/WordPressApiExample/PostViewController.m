//
//  DetailViewController.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 12/20/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import "PostViewController.h"

@interface PostViewController ()
- (void)configureView;
@end

@implementation PostViewController

@synthesize post = _post;
@synthesize postContentView = _postContentView;

#pragma mark - Managing the detail item

- (void)setPost:(NSDictionary *)newPost
{
    if (_post != newPost) {
        _post = newPost;

        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.post) {
        NSString *html = [NSString stringWithFormat:@"<h1>%@</h1>%@",
                          [self.post objectForKey:@"title"],
                          [self.post objectForKey:@"description"]];
        self.title = [self.post objectForKey:@"title"];
        [self.postContentView loadHTMLString:html baseURL:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
