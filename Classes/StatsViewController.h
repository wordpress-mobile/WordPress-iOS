//
//  StatsViewController.h
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpHelper.h"
#import "StatsCategoryViewController.h"
#import "StatsCollection.h"

@interface StatsViewController : UIViewController <UIScrollViewDelegate, UITableViewDelegate, HTTPHelperDelegate> {
	BOOL isDownloadingData;
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UIScrollView *scrollView;
	IBOutlet UITableView *tableView;
	IBOutlet UISegmentedControl *scDateRange;
	IBOutlet UIImageView *ivChart;
	IBOutlet UILabel *labelChartDescription, *labelChartPeriod;
	NSString *chartTitle, *chartPeriod, *chartRange;
	StatsCategory *category, *downloadCategory;
	StatsCollection *views, *referrers, *posts, *clicks, *terms;
	
	NSIndexPath *selectedIndexPath;
}

@property (nonatomic, assign) BOOL isDownloadingData;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *scDateRange;
@property (nonatomic, retain) IBOutlet UIImageView *ivChart;
@property (nonatomic, retain) IBOutlet UILabel *labelChartDescription, *labelChartPeriod;
@property (nonatomic, retain) NSString *chartTitle, *chartPeriod, *chartRange;
@property (nonatomic, assign) StatsCategory *category, *downloadCategory;
@property (nonatomic, assign) StatsCollection *views, *referrers, *posts, *clicks, *terms;

@property (nonatomic, retain) NSIndexPath *selectedIndexPath;

- (NSMutableArray *)menuData;
- (IBAction)updateChart:(id)sender;
- (void)refreshStatsData;

@end
