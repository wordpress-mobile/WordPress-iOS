//
//  StatsTableViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 10/12/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"
#import "StatsTableViewController.h"
#import <Foundation/Foundation.h>
#import "WPProgressHUD.h"
#import "StatsPageControlViewController.h"


@interface StatsTableViewController : UITableViewController <UIAlertViewDelegate, NSXMLParserDelegate>{
	
	NSMutableArray *viewsData;
	NSMutableArray *postViewsData;
	NSMutableArray *referrersData;
	NSMutableArray *searchTermsData;
	NSMutableArray *clicksData;
	NSString *reportTitle;
	NSMutableDictionary *currentBlog;
	WordPressAppDelegate *appDelegate;
	NSMutableData *statsData;
	NSMutableString *currentProperty;
	NSString *rootTag, *leftColumn, *rightColumn;
	BOOL apiKeyFound, loginActive, dotorgLogin, statsRequest;
	IBOutlet UIView *container, *statsView, *loginView, *wpcomLogin;
	NSMutableArray *statsTableData;
	NSMutableArray *reportTitles, *reportIntervals;
	UIActionSheet *actionSheet;
	UIPickerView *pickerView;
	WPProgressHUD *spinner;
	NSString *yValues;
	NSMutableArray *xArray, *yArray;
	IBOutlet UITableView *wpcomLoginTable;
	StatsPageControlViewController *statsPageControlViewController;
	int requestType;
	CFMutableDictionaryRef connectionToInfoMapping;
	BOOL foundStatsData, statsAPIAlertShowing, canceledAPIKeyAlert;
	UIBarButtonItem *refreshButtonItem;
	int loadMorePostViews, loadMoreReferrers, loadMoreSearchTerms, loadMoreClicks;
	NSURLConnection *apiKeyConn, *viewsConn, *postViewsConn, *referrersConn, *searchTermsConn, *clicksConn, *daysConn, *weeksConn, *monthsConn;
}

@property (nonatomic, retain) NSMutableArray *viewsData;
@property (nonatomic, retain) NSMutableArray *postViewsData;
@property (nonatomic, retain) NSMutableArray *referrersData;
@property (nonatomic, retain) NSMutableArray *searchTermsData;
@property (nonatomic, retain) NSMutableArray *clicksData;
@property (nonatomic, retain) NSString *reportTitle;
@property (nonatomic, copy, readonly) NSMutableDictionary *currentBlog;
@property (nonatomic, retain) NSMutableData *statsData;
@property (nonatomic, retain) NSMutableString *currentProperty;
@property (nonatomic, retain) NSString *rootTag;
@property (nonatomic, retain) NSMutableArray *statsTableData;
@property (nonatomic, retain) NSString *rightColumn;
@property (nonatomic, retain) NSString *leftColumn;
@property (nonatomic, retain) WPProgressHUD *spinner;
@property (nonatomic, retain) NSString *xValues;
@property (nonatomic, retain) NSString *yValues;
@property (nonatomic, retain) NSMutableArray *xArray;
@property (nonatomic, retain) NSMutableArray *yArray;
@property (nonatomic, retain) UITableView *wpcomLoginTable;
@property (nonatomic, retain) StatsPageControlViewController *statsPageControlViewController;
@property (readonly) UIBarButtonItem *refreshButtonItem;
@property (nonatomic, retain) NSURLConnection *apiKeyConn, *viewsConn, *postViewsConn, *referrersConn, *searchTermsConn, *clicksConn, *daysConn, *weeksConn, *monthsConn;
- (void) initStats;
- (void) getUserAPIKey;
- (void) startParsingStats: (NSString*) xmlString withReportType: (NSString*) reportType;
- (void) refreshStats: (int) titleIndex reportInterval: (int) intervalIndex;
- (void) showNoDataFoundError;
@end
