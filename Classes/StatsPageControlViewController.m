//
//  StatsPageControlViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 10/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "StatsPageControlViewController.h"
#import "StatsChartViewController.h"


@implementation StatsPageControlViewController
@synthesize scrollView, pageControl, viewControllers, chart1URL, chart2URL, chart3URL, chart1Error, chart2Error, chart3Error;
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc {
    [viewControllers release];
    [scrollView release];
    [pageControl release];
    [super dealloc];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
	NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < 3; i++) {
        [controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    [controllers release];
	
    // a page is the width of the scroll view
    scrollView.pagingEnabled = YES;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * 3, scrollView.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
    scrollView.delegate = self;
    
    scrollView.isAccessibilityElement = YES;
    scrollView.accessibilityLabel = @"Stats";       // required for UIAutomation for iOS4
    if ([scrollView respondsToSelector:@selector(setAccessibilityIdentifier:)]) {
        scrollView.accessibilityIdentifier = @"Stats";  // required for UIAutomation for iOS5
    }
	
    pageControl.numberOfPages = 3;
    pageControl.currentPage = 0;
	
    // load the 3 pages
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
	[self loadScrollViewWithPage:2];
	
}

- (void)loadScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= 3) return;
	
    // replace the placeholder if necessary
    StatsChartViewController *controller = [viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null]) {
        controller = [[StatsChartViewController alloc] initWithPageNumber:page];
        [viewControllers replaceObjectAtIndex:page withObject:controller];
        [controller release];
    }
	
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [scrollView addSubview:controller.view];
    }
}

- (void)refreshImage:(int)chartID{
	StatsChartViewController *controller = [viewControllers objectAtIndex:chartID-1];
	/*if ((NSNull *)controller == [NSNull null]) {
		StatsChartViewController *newController = [[StatsChartViewController alloc] initWithPageNumber:chartID-1];
        [viewControllers replaceObjectAtIndex:chartID-1 withObject:newController];
        [newController release];
	}*/
	
	switch (chartID){
		case 1:
			if (chart1Error)
			{
				[controller showError];
			}
			else {
				[controller loadImageFromURL: chart1URL];
			}
			break;
		case 2:
			if (chart2Error)
			{
				[controller showError];
			}
			else {
				[controller loadImageFromURL: chart2URL];
			}
			break;	
		case 3:
			if (chart3Error)
			{
				[controller showError];
			}
			else {
				[controller loadImageFromURL: chart3URL];
			}
			//WPLog(@"Chart 3: %@", chart3URL);
			break;
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed) {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;
	
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
	
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

- (IBAction)changePage:(id)sender {
    int page = pageControl.currentPage;
	
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    
	// update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


@end
