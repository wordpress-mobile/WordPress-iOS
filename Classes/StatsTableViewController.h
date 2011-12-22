//
//  StatsTableViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 10/12/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "StatsTableViewController.h"
#import <Foundation/Foundation.h>
#import "StatsPageControlViewController.h"
#import "EGORefreshTableHeaderView.h"
#import "WPWebViewController.h"

@interface StatsTableViewController : UITableViewController <UIAlertViewDelegate, NSXMLParserDelegate, EGORefreshTableHeaderDelegate, NSURLConnectionDelegate>{
	
    EGORefreshTableHeaderView *_refreshHeaderView;
	NSArray *viewsData;
	NSArray *postViewsData;
	NSArray *referrersData;
	NSArray *searchTermsData;
	NSArray *clicksData;
	NSString *reportTitle;
	NSMutableDictionary *currentBlog;
	WordPressAppDelegate *appDelegate;
	NSMutableString *currentProperty;
	NSString *rootTag, *leftColumn, *rightColumn;
	BOOL apiKeyFound, dotorgLogin, statsRequest, isRefreshingStats, displayedLoginView;
	IBOutlet UIView *container, *statsView, *loginView, *wpcomLogin;
	NSMutableArray *statsTableData;
	NSMutableArray *reportTitles, *reportIntervals;
	UIActionSheet *actionSheet;
	UIPickerView *pickerView;
	NSString *yValues;
	NSMutableArray *xArray, *yArray;
	IBOutlet UITableView *wpcomLoginTable;
	StatsPageControlViewController *statsPageControlViewController;
	int requestType;
	CFMutableDictionaryRef connectionToInfoMapping;
	BOOL foundStatsData, statsAPIAlertShowing, canceledAPIKeyAlert;
	int loadMorePostViews, loadMoreReferrers, loadMoreSearchTerms, loadMoreClicks;
	NSURLConnection *apiKeyConn, *viewsConn, *postViewsConn, *referrersConn, *searchTermsConn, *clicksConn, *daysConn, *weeksConn, *monthsConn;
}

@property (nonatomic, retain) NSArray *viewsData;
@property (nonatomic, retain) NSArray *postViewsData;
@property (nonatomic, retain) NSArray *referrersData;
@property (nonatomic, retain) NSArray *searchTermsData;
@property (nonatomic, retain) NSArray *clicksData;
@property (nonatomic, retain) NSString *reportTitle;
@property (nonatomic, copy, readonly) NSMutableDictionary *currentBlog;
@property (nonatomic, retain) NSMutableString *currentProperty;
@property (nonatomic, retain) NSString *rootTag;
@property (nonatomic, retain) NSMutableArray *statsTableData;
@property (nonatomic, retain) NSString *rightColumn;
@property (nonatomic, retain) NSString *leftColumn;
@property (nonatomic, retain) NSString *xValues;
@property (nonatomic, retain) NSString *yValues;
@property (nonatomic, retain) NSMutableArray *xArray;
@property (nonatomic, retain) NSMutableArray *yArray;
@property (nonatomic, retain) UITableView *wpcomLoginTable;
@property (nonatomic, retain) StatsPageControlViewController *statsPageControlViewController;
@property (nonatomic, retain) NSURLConnection *apiKeyConn, *viewsConn, *postViewsConn, *referrersConn, *searchTermsConn, *clicksConn, *daysConn, *weeksConn, *monthsConn;
@property (nonatomic, retain) Blog *blog;

- (void) initStats;
- (void) getUserAPIKey;
- (void) startParsingStats: (NSString*) xmlString withReportType: (NSString*) reportType;
- (void) refreshStats: (int) titleIndex reportInterval: (int) intervalIndex;
- (void) showNoDataFoundError;
- (void) showLoadingDialog;
- (void) hideLoadingDialog;
- (void) viewUrl: (NSString*) urlString;
@end
