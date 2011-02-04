//
//  StatsChartViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 10/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatsChartViewController : UIViewController {
	NSString *chartURL;
    UILabel *chartTitleLabel;
	UIImageView *chart;
    int pageNumber;
	UIActivityIndicatorView *spinner;
	NSURLConnection* connection; //keep a reference to the connection so we can cancel download in dealloc
	NSMutableData* imgData; //keep reference to the data so we can collect it as it downloads
}

@property (nonatomic, retain) IBOutlet UILabel *chartTitleLabel;
@property (nonatomic, retain) IBOutlet UIImageView *chart;
@property (nonatomic, retain) IBOutlet NSString *chartURL;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;


- (id)initWithPageNumber:(int)page;
- (void)refreshImage;
- (void)loadImageFromURL:(NSString*)url;
- (void)showError;
@end
