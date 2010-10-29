//
//  StatsChartViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 10/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "StatsChartViewController.h"

@implementation StatsChartViewController

static NSArray *__pageControlColorList = nil;

@synthesize chartTitleLabel, chart, chartURL, spinner;

// Creates the color list the first time this method is invoked. Returns one color object from the list.
+ (UIColor *)pageControlColorWithIndex:(NSUInteger)index {
    if (__pageControlColorList == nil) {
        __pageControlColorList = [[NSArray alloc] initWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor magentaColor],
                                  [UIColor blueColor], [UIColor orangeColor], [UIColor brownColor], [UIColor grayColor], nil];
    }
	
    // Mod the index by the list length to ensure access remains in bounds.
    return [__pageControlColorList objectAtIndex:index % [__pageControlColorList count]];
}

// Load the view nib and initialize the pageNumber ivar.
- (id)initWithPageNumber:(int)page {
    if (self = [super initWithNibName:@"StatsChartViewController" bundle:nil]) {
        pageNumber = page;
		if (chartURL != nil){
		
		}
    }
    return self;
}

- (void)dealloc {
	[spinner release];
	[chartURL release];
	[chart release];
    [chartTitleLabel release];
    [super dealloc];
}

// Set the label and background color when the view has finished loading.
- (void)viewDidLoad {
	//chart = [[UIImageView alloc] initWithImage:chartImage];
	NSString *chartTitle = [[NSString alloc] initWithString:@""];
	switch (pageNumber) {
		case 0:
			chartTitle = @"Days";
			break;
		case 1:
			chartTitle = @"Weeks";
			break;
		case 2:
			chartTitle = @"Months";
			break;
	}
    chartTitleLabel.text = chartTitle;
	[chartTitle release];
    //self.view.backgroundColor = [StatsChartViewController pageControlColorWithIndex:pageNumber];
	
}

- (void)refreshImage {
	/*NSURL *url = [NSURL URLWithString:[NSString stringWithString: chartURL]];
	NSData *data = [NSData dataWithContentsOfURL:url];
	UIImage *image = [[UIImage alloc] initWithData:data cache:NO];
	chart.image = image;*/
}

- (void)loadImageFromURL:(NSString*)url {
    if (connection!=nil) { [connection release]; }
    if (imgData!=nil) { [imgData release]; }
	imgData = [[NSMutableData alloc] init];
	NSURL *url_l = [[NSURL alloc] initWithString: url];
    NSURLRequest* request = [NSURLRequest requestWithURL:url_l
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:40.0];
    connection = [[NSURLConnection alloc]
				  initWithRequest:request delegate:self];
    //TODO error handling, what if connection is nil?
}

-(void) showError{
	if(!spinner.hidden)
		spinner.hidden=YES;
	chartTitleLabel.text = @"No chart data found.";
}

- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
	
    [connection release];
    connection=nil;
	UIImage *image = [[UIImage alloc] initWithData:imgData];
	//add header image to uitable
	chart.image = image;
	if(!spinner.hidden)
		spinner.hidden=YES;


	
    //[imgData release];
    //imgData=nil;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[imgData appendData: data];
}

@end