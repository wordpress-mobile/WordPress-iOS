//
//  StatsTableViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 10/12/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "StatsTableViewController.h"
#import "StatsTableCell.h"
#import "UITableViewActivityCell.h"
#import "WPcomLoginViewController.h"
#import "WPReachability.h"
#import "CPopoverManager.h"


@implementation StatsTableViewController

@synthesize viewsData, postViewsData, referrersData, searchTermsData, clicksData, reportTitle,
currentBlog, currentProperty, rootTag, 
statsTableData, leftColumn, rightColumn, xArray, yArray, xValues, yValues, wpcomLoginTable, 
statsPageControlViewController, apiKeyConn, viewsConn, postViewsConn, referrersConn, 
searchTermsConn, clicksConn, daysConn, weeksConn, monthsConn;
@synthesize blog;
#define LABEL_TAG 1 
#define VALUE_TAG 2 
#define FIRST_CELL_IDENTIFIER @"TrailItemCell" 
#define SECOND_CELL_IDENTIFIER @"RegularCell" 

- (void)dealloc {
	[viewsData release];
	[postViewsData release];
	[referrersData release];
	[searchTermsData release];
	[clicksData release];
	[reportTitle release];
	[currentBlog release];
	[xArray release];
	[yArray release];
	[wpcomLoginTable release];
	[statsPageControlViewController release];
	[apiKeyConn release];
	[viewsConn release];
	[postViewsConn release];
	[referrersConn release];
	[searchTermsConn release];
	[clicksConn release];
	[daysConn release];
	[weeksConn release];
	[monthsConn release];
    self.rootTag = nil;
    self.currentProperty = nil;
    self.leftColumn = nil;
    self.rightColumn = nil;
    self.statsTableData = nil;
    self.xValues = nil;
    self.yValues = nil;
    self.blog = nil;
	[super dealloc];
}

- (void)viewDidLoad {
	[FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidLoad];

	loadMorePostViews = 10;
	loadMoreReferrers = 10;
	loadMoreSearchTerms = 10;
	loadMoreClicks = 10;
	
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	self.view.frame = CGRectMake(0, 0, 320, 460);
	self.tableView.sectionHeaderHeight = 30;
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	statsPageControlViewController = [[StatsPageControlViewController alloc] init];
	connectionToInfoMapping = CFDictionaryCreateMutable(
														kCFAllocatorDefault,
														0,
														&kCFTypeDictionaryKeyCallBacks,
														&kCFTypeDictionaryValueCallBacks);
	
	if (_refreshHeaderView == nil) {
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		view.delegate = self;
		[self.tableView addSubview:view];
		_refreshHeaderView = view;
		[view release];
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
		
	/*if (DeviceIsPad() == YES) {
		[self.view removeFromSuperview];
		[statsPageControlViewController initWithNibName:@"StatsPageControlViewController-iPad" bundle:nil];
		[self initWithNibName:@"StatsTableViewConroller-iPad" bundle:nil];
		[appDelegate showContentDetailViewController:self];
	}*/
	[self.tableView setBackgroundColor:[[[UIColor alloc] initWithRed:221.0f/255.0f green:221.0f/255.0f blue:221.0f/255.0f alpha:1.0] autorelease]];
}



- (void) viewWillAppear:(BOOL)animated {
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillAppear:) name:@"didDismissWPcomLogin" object:nil];
    
    //reset booleans
    apiKeyFound = NO;
    isRefreshingStats = NO;
    canceledAPIKeyAlert =  NO;
    
    if (DeviceIsPad())
        [appDelegate showContentDetailViewController:nil];
    
	if([[WPReachability sharedReachability] internetConnectionStatus] == NotReachable) {
		UIAlertView *errorView = [[UIAlertView alloc] 
								  initWithTitle: @"Communication Error" 
								  message: @"The internet connection appears to be offline." 
								  delegate: self 
								  cancelButtonTitle: @"OK" otherButtonTitles: nil];
		[errorView show];
		[errorView autorelease];
	}
	else
	{
		if (DeviceIsPad() == YES) {
			//[[[CPopoverManager instance] currentPopoverController] dismissPopoverAnimated:YES];
			//[appDelegate showContentDetailViewController:self];
		}
		
		//get this party started!
		if (!canceledAPIKeyAlert && !foundStatsData && !displayedLoginView)
			[self initStats]; 
	}
}

- (void)loadView {
    [super loadView];
    
	
}

-(void) initStats {
	
	NSString *apiKey = blog.apiKey;
	if (apiKey == nil){
		//first run or api key was deleted
		[self getUserAPIKey];
	}
	else {
		statsRequest = YES;
        //refresh stats
		[self showLoadingDialog];
	}
}

-(void) showLoadingDialog{
	CGPoint offset = self.tableView.contentOffset;
	offset.y = - 65.0f;
	self.tableView.contentOffset = offset;
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
}

-(void) hideLoadingDialog{
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

-(void)getUserAPIKey {
	if ([blog isWPcom] || dotorgLogin == YES)
	{
		[self showLoadingDialog];
		apiKeyConn = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://public-api.wordpress.com/get-user-blogs/1.0"]] delegate:self];
		
		CFDictionaryAddValue(
							 connectionToInfoMapping,
							 apiKeyConn,
							 [NSMutableDictionary
							  dictionaryWithObject:[NSMutableData data]
							  forKey:@"apiKeyData"]);
	}
	else 
	{
		BOOL presentDialog = YES;
		if (dotorgLogin == YES && ![blog isWPcom])
		{
			presentDialog = NO;
			dotorgLogin = NO;
		}
		
		if (presentDialog) {
			dotorgLogin = YES;
		
		if(DeviceIsPad() == YES) {
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController-iPad-stats" bundle:nil];	
            wpComLogin.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			wpComLogin.modalPresentationStyle = UIModalPresentationFormSheet;
            wpComLogin.isStatsInitiated = YES;
			[appDelegate.splitViewController presentModalViewController:wpComLogin animated:YES];			
            [wpComLogin release];
		}
		else {
			dotorgLogin = YES;
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController" bundle:nil];	
			[appDelegate.navigationController presentModalViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WordPress.com Stats", @"")
														 message:NSLocalizedString(@"To load stats for your blog you will need to have the WordPress.com stats plugin installed and correctly configured as well as your WordPress.com login.", @"") 
														delegate:self cancelButtonTitle:NSLocalizedString(@"Learn More", @"") otherButtonTitles:nil] autorelease];
		alert.tag = 1;
		[alert addButtonWithTitle:NSLocalizedString(@"I'm Ready!", @"")];
		[alert show];
		}
		
	}
	
}

- (void) refreshStats: (int) titleIndex reportInterval: (int) intervalIndex {
    //make sure we have the apiKey
    if (blog.apiKey == nil){
        statsRequest = NO;
		[self getUserAPIKey];
        return;
	}
    
    
	//load stats into NSMutableArray objects
	isRefreshingStats = YES;
	//[self showLoadingDialog];
	foundStatsData = NO;
	
    //This block can be used for adding custom controls if desired by users down the road to load their own reports
    /*
    int days = -1;
	NSString *report;
	NSString *period;
	switch (intervalIndex) {
		case 0:
			days = 7;
			break;
		case 1:
			days = 30;
			break;
		case 2:
			days = 90;
			break;
		case 3:
			days = 365;
			break;
		case 4:
			days = -1;
			break;
	}
	
	if (days == 90){
		period = @"&period=week";
		days = 12;
	}
	else if (days == 365){
		period = @"&period=month";
		days = 11;
	}
	else if (days == -1){
		period = @"&period=month";
	}
	
	switch (titleIndex) {
		case 0:
			report = @"views";
			break;
		case 1:
			report = @"postviews";
			break;
		case 2:
			report = @"referrers";
			break;
		case 3:
			report = @"searchterms";
			break;
		case 4:
			report = @"clicks";
			break;
	}	
    */
	NSString *apiKey = blog.apiKey;
    
    NSString *idType;
	
    if ([blog isWPcom])
        idType = [NSString stringWithFormat:@"blog_id=%@", blog.blogID];
    else
        idType = [NSString stringWithFormat:@"blog_uri=%@", blog.url];

	//request the 5 reports for display in the UITableView
    
	NSString *requestURL;
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	//views
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@", apiKey, idType, @"views", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	viewsConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 viewsConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"viewsData"]);
	
	//postviews
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@&summarize", apiKey, idType, @"postviews", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	postViewsConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 postViewsConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"postViewsData"]);
	
	//referrers
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@&summarize", apiKey, idType, @"referrers", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	referrersConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 referrersConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"referrersData"]);
	
	//search terms
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@&summarize", apiKey, idType, @"searchterms", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	searchTermsConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 searchTermsConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"searchTermsData"]);
	
	//clicks
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@&summarize", apiKey, idType, @"clicks", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	clicksConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 clicksConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"clicksData"]);
	
	
	//get the three header chart images
	statsRequest = YES;
	
	// 7 days
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@", apiKey, idType, @"views", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	daysConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 daysConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"chartDaysData"]);
	// 10 weeks
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@", apiKey, idType, @"views", 10, @"&period=week"];	
	[request setURL:[NSURL URLWithString:requestURL]];
	weeksConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 weeksConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"chartWeeksData"]);
	// 11 months
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&%@&format=xml&table=%@&days=%d%@", apiKey, idType, @"views", 11, @"&period=month"];	
	[request setURL:[NSURL URLWithString:requestURL]];
	[request setValue:@"wp-iphone" forHTTPHeaderField:@"User-Agent"];
	monthsConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 monthsConn,
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"chartMonthsData"]);
	[request release];
	statsRequest = YES;
}

- (void) startParsingStats: (NSString*) xmlString withReportType: (NSString*) reportType {
	self.statsTableData = nil;
	self.statsTableData = [NSMutableArray array];
	xArray = [[NSMutableArray alloc] init];
	yArray = [[NSMutableArray alloc] init];
	NSData *data = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
	NSXMLParser *statsParser = [[NSXMLParser alloc] initWithData:data];
	statsParser.delegate = self;
	[statsParser parse];
	[statsParser release];
	if ([xArray count] > 0){
		//set up the new data in the UI
		foundStatsData = YES;
		if ([reportType isEqualToString:@"chartDaysData"] || [reportType isEqualToString:@"chartWeeksData"] || [reportType isEqualToString:@"chartMonthsData"]){
			[self hideLoadingDialog];
			self.blog.lastStatsSync = [NSDate date];
			self.xValues = [xArray componentsJoinedByString:@","];
			NSArray *sorted = [xArray sortedArrayUsingSelector:@selector(compare:)];
			
			//calculate some variables for the google chart
			int maxValue = [[sorted objectAtIndex:[sorted count] - 1] intValue];
			
            //calculate some variables for the google chart
            int power = log(maxValue) / log(10);
            int factor = pow(10, power);
            int maxBuffer = 0;
            int minBuffer = 0;
            int yInterval = 0;
            if (factor == 0)
                factor = 1;
            if (maxValue == 1) {
                yInterval = 1;
                maxBuffer = 2;
            }
            else {
                maxBuffer = (maxValue / factor) * factor;
                yInterval = maxBuffer / 4;
                maxBuffer += yInterval;
                
                if (yInterval == 0)
                    yInterval = 1;
            
                while (maxBuffer <= maxValue){
                    maxBuffer += yInterval;
                }
            
                if (maxValue < 10)
                    maxBuffer = 10;
            }
            
            if (yInterval > 5 && yInterval < 10) {
                yInterval = 10;
                maxBuffer = 50;
            }
            else if (yInterval > 10 && yInterval < 15) {
                yInterval = 15;
                maxBuffer = 75;
            }
            else if (yInterval > 15 && yInterval < 20) {
                yInterval = 20;
                maxBuffer = 100;
            }
            
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];  
            [formatter setLocale:[NSLocale currentLocale]];

            [formatter setGroupingSeparator:[[formatter groupingSeparator] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];

            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            NSString *yAxisValues = @"";
            int stepCtr = 0;
            for (int i = 0; i <= maxBuffer; i += yInterval) {
                stepCtr++;
                yAxisValues = [yAxisValues stringByAppendingFormat:@"%@|", [formatter stringFromNumber:[NSNumber numberWithInt:i]]];
            
            }
            yAxisValues = [yAxisValues substringToIndex:[yAxisValues length] - 1];
            
            [formatter release];
            
			NSMutableArray *dateCSV = [[NSMutableArray alloc] init];
            NSString *bgData = @"";
			if ([reportType isEqualToString:@"chartDaysData"]){
                bgData = @"|";
				for (NSString *dateVal in yArray) {
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
					[df setDateFormat:@"yyyy-MM-dd"];
					NSDate *tempDate = [df dateFromString: dateVal];
					NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
					NSDateComponents *dateComponents = [gregorian components:(NSWeekdayCalendarUnit) fromDate:tempDate];
                    
					NSInteger day = [dateComponents weekday];
                    
                    [df setDateFormat:@"E"];
                    [df setLocale:[NSLocale currentLocale]];
                    NSString *weekdayName = [[[df stringFromDate:tempDate] substringToIndex:1] capitalizedString];
                    [df release];
                    
                    [dateCSV addObject: weekdayName];
                    if (day == 1 || day == 7) //show the grey bg in the chart if it's a weekend day
                        bgData = [NSString stringWithFormat:@"%@%d,", bgData, maxBuffer];
                    else
                        bgData = [NSString stringWithFormat:@"%@%@", bgData, @"0,"];


					[gregorian release];
					
				}
                bgData = [bgData substringToIndex:[bgData length] - 1];
			}
			else if ([reportType isEqualToString:@"chartWeeksData"])
			{
				for (NSString *dateVal in yArray) {
                    if ([dateVal length] >= 7)
                        [dateCSV addObject: [dateVal substringWithRange: NSMakeRange (5, 2)]];
                    else
                        [dateCSV addObject: @""];
				}
				
			}
			else if ([reportType isEqualToString:@"chartMonthsData"]){
				isRefreshingStats = NO;
				for (NSString *dateVal in yArray) {
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
					[df setDateFormat:@"yyyy-MM"];
					NSDate *tempDate = [df dateFromString: dateVal];
                    [df release];
					NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
					NSDateComponents *dateComponents = [gregorian components:(NSMonthCalendarUnit) fromDate:tempDate];
					NSInteger i_month = [dateComponents month];
                    
                    NSString * dateString = [NSString stringWithFormat: @"%d", i_month];
                    
                    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"MM"];
                    NSDate* myDate = [dateFormatter dateFromString:dateString];
                    [dateFormatter release];
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"MMM"];
                    NSString *stringFromDate = [[formatter stringFromDate:myDate] capitalizedString];
                    
                    
                    [dateCSV addObject: stringFromDate];
                    [formatter release];
					[gregorian release];
				}
				
			}
            float stepSize;
            if (stepCtr > 0) {
                stepCtr--;
                stepSize = 100.0f/stepCtr;
            }
            else
                stepSize = 1;
            
            NSString* formattedStepSize = [NSString stringWithFormat:@"%.06f", stepSize];
            
			NSString *dateValues = [[NSString alloc] initWithString:[dateCSV componentsJoinedByString:@"|"]];
			NSString *chartViewURL = [[[NSString alloc] initWithFormat: @"http://chart.apis.google.com/chart?chts=464646,20&cht=bvs&chg=100,%@,1,0&chbh=a&chd=t:%@%@&chs=560x320&chxl=0:|%@|1:|%@&chxt=y,x&chds=%d,%d&chxr=0,%d,%d,%d&chf=c,lg,90,FFFFFF,0,FFFFFF,0.5&chco=a3bcd3,cccccc77&chls=4&chxs=0,464646,20,0,t|1,464646,20,0,t,ffffff&chxtc=0,0", formattedStepSize, self.xValues, bgData, yAxisValues, dateValues, minBuffer,maxBuffer, minBuffer,maxBuffer, yInterval] autorelease];
            chartViewURL = [chartViewURL stringByReplacingOccurrencesOfString:@"|" withString:@"%7c"];
			NSLog(@"google chart url: %@", chartViewURL);
			statsRequest = YES;
			if ([reportType isEqualToString:@"chartDaysData"]) {
				statsPageControlViewController.chart1URL = chartViewURL;
				[statsPageControlViewController refreshImage: 1];
			}
			else if ([reportType isEqualToString:@"chartWeeksData"]){
				statsPageControlViewController.chart2URL = chartViewURL;
				[statsPageControlViewController refreshImage: 2];
			}
			else if ([reportType isEqualToString:@"chartMonthsData"]){
				statsPageControlViewController.chart3URL = chartViewURL;
				[statsPageControlViewController refreshImage: 3];
				//check the other charts
				if (statsPageControlViewController.chart2URL == nil) {
					statsPageControlViewController.chart2Error = YES;
					[statsPageControlViewController refreshImage: 2];
				}
				else if (statsPageControlViewController.chart1URL == nil) {
					statsPageControlViewController.chart1Error = YES;
					[statsPageControlViewController refreshImage: 1];
				}
			}
            [dateCSV release];
            [dateValues release];
		} //end chartData if statement
		else{
			if ([reportType isEqualToString:@"viewsData"]){
				self.viewsData = [[NSArray alloc] initWithArray:self.statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"postViewsData"]){
				self.postViewsData = [[NSArray alloc] initWithArray:self.statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"referrersData"]){
				self.referrersData = [[NSArray alloc] initWithArray:self.statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"searchTermsData"]){
				self.searchTermsData = [[NSArray alloc] initWithArray:self.statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"clicksData"]){
				self.clicksData = [[NSArray alloc] initWithArray:self.statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
		}
	}
	else {
		//NSLog(@"No data returned! oh noes!");
		if (!foundStatsData && ![reportType isEqualToString:@"apiKeyData"]){
			[self showNoDataFoundError];
		}
		
	}
	[self.view setHidden:NO];
	[self hideLoadingDialog];
}

-(void) showNoDataFoundError{
	[self.tableView.tableHeaderView removeFromSuperview];
	UILabel *errorMsg = [[UILabel alloc] init];
	errorMsg.text = NSLocalizedString(@"No stats data found.  Please try again later.", @"");
	self.tableView.tableHeaderView = errorMsg;
}

/*  NSURLConnection Methods  */

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
	else if ([challenge previousFailureCount] <= 1)
	{
		NSURLCredential *newCredential;
		NSString *s_username, *s_password;
		NSError *error = nil;
		
        if ([blog isWPcom]) {
            //use set username/pw for wpcom blogs
            s_username = blog.username;
            s_password = [SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:blog.hostURL error:&error];
        }
        else {
            //use wpcom preference for self-hosted
            s_username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
            s_password = [SFHFKeychainUtils getPasswordForUsername:s_username andServiceName:@"WordPress.com" error:&error];
            dotorgLogin = YES;
        }
        
        if (s_username != nil || s_password != nil) {
            newCredential=[NSURLCredential credentialWithUser:s_username
												 password:s_password
											  persistence:NSURLCredentialPersistenceForSession];
            [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
        }
        else {
            //stop this train.
            [connection cancel];
            isRefreshingStats = NO;
            dotorgLogin = NO;
            statsRequest = YES;
            [self hideLoadingDialog];
        }
	}
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	//add the data to the corresponding NSURLConnection object
	const NSMutableDictionary *connectionInfo = CFDictionaryGetValue(connectionToInfoMapping, connection);
	if ([connectionInfo objectForKey:@"apiKeyData"] != nil)
		[[connectionInfo objectForKey:@"apiKeyData"] appendData:data];
	else if ([connectionInfo objectForKey:@"postViewsData"] != nil)
		[[connectionInfo objectForKey:@"postViewsData"] appendData:data];
	else if ([connectionInfo objectForKey:@"referrersData"] != nil)
		[[connectionInfo objectForKey:@"referrersData"] appendData:data];
	else if ([connectionInfo objectForKey:@"searchTermsData"] != nil)
		[[connectionInfo objectForKey:@"searchTermsData"] appendData:data];
	else if ([connectionInfo objectForKey:@"clicksData"] != nil)
		[[connectionInfo objectForKey:@"clicksData"] appendData:data];
	else if ([connectionInfo objectForKey:@"viewsData"] != nil)
		[[connectionInfo objectForKey:@"viewsData"] appendData:data];
	else if ([connectionInfo objectForKey:@"chartDaysData"] != nil)
		[[connectionInfo objectForKey:@"chartDaysData"] appendData:data];
	else if ([connectionInfo objectForKey:@"chartWeeksData"] != nil)
		[[connectionInfo objectForKey:@"chartWeeksData"] appendData:data];
	else if ([connectionInfo objectForKey:@"chartMonthsData"] != nil)
		[[connectionInfo objectForKey:@"chartMonthsData"] appendData:data];
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection {
	const NSMutableDictionary *connectionInfo = CFDictionaryGetValue(connectionToInfoMapping, connection);
	//get the key name
	NSArray *keys = [connectionInfo allKeys];
	id aKey = [keys objectAtIndex:0];
	NSString *reportType = aKey;
	//format the xml response
	NSString *xmlString = [[[NSString alloc] initWithData:[connectionInfo objectForKey:aKey] encoding:NSUTF8StringEncoding] autorelease];
	[xmlString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	[xmlString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	WPLog(@"xml string = %@", xmlString);
	NSRange textRange;
	textRange =[xmlString rangeOfString:@"Error"];
	if ( xmlString != nil && textRange.location == NSNotFound ) {
		self.tableView.tableHeaderView = statsPageControlViewController.view;
		[self.tableView.tableHeaderView setHidden:NO];
		[self startParsingStats: xmlString withReportType: reportType];
	}
	else if (textRange.location != NSNotFound && ([connectionInfo objectForKey:@"viewsData"] != nil)){
		[self.tableView.tableHeaderView setHidden:YES];
		[connection cancel];
		[self hideLoadingDialog];
		//it's the wrong API key, prompt for WPCom login details again
		if(DeviceIsPad() == YES) {
            dotorgLogin = NO;
            isRefreshingStats = NO;
            canceledAPIKeyAlert =  NO;
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController-iPad-stats" bundle:nil];	
            wpComLogin.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			wpComLogin.modalPresentationStyle = UIModalPresentationFormSheet;
            wpComLogin.isStatsInitiated = YES;
			[appDelegate.splitViewController presentModalViewController:wpComLogin animated:YES];			
			[wpComLogin release];
		}
		else {
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController" bundle:nil];	
			[appDelegate.navigationController presentModalViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}
        displayedLoginView = YES;
		if (!statsAPIAlertShowing){
			blog.apiKey = nil;
			[blog dataSave];
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Login Error" 
															 message:@"Please enter an administrator login for this blog and refresh." 
															delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setTag:2];
			[alert show];
			statsAPIAlertShowing = YES;
		}
	}
	else {
		//NSLog(@"no data returned from api");
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	if ([response respondsToSelector:@selector(statusCode)])
	{
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		if (statusCode >= 400)
		{
			[connection cancel];  // stop connecting; no more delegate messages
			NSDictionary *errorInfo
			= [NSDictionary dictionaryWithObject:[NSString stringWithFormat:
												  NSLocalizedString(@"Server returned status code %d",@""),
												  statusCode]
										  forKey:NSLocalizedDescriptionKey];
			NSError *statusError = [NSError errorWithDomain:@"org.wordpress.iphone"
													   code:statusCode
												   userInfo:errorInfo];
			[self connection:connection didFailWithError:statusError];
		}
	}
}

- (void)connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{	
	
	isRefreshingStats = NO;
	[self hideLoadingDialog];
	//UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" 
	//												 message:[error errorInfo] 
	//												delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	//[alert show];
	//NSLog(@"ERROR: %@", [error localizedDescription]);
	
	[connection autorelease];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return YES;
}

/*  XML Parsing  */

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	self.currentProperty = [NSMutableString string];
	if (statsRequest) {
		if ([elementName isEqualToString:@"views"] || [elementName isEqualToString:@"postviews"] || [elementName isEqualToString:@"referrers"] 
			|| [elementName isEqualToString:@"clicks"] || [elementName isEqualToString:@"searchterms"] || [elementName isEqualToString:@"videoplays"] 
			|| [elementName isEqualToString:@"title"]) {
			self.rootTag = elementName;
		}
		else if ([elementName isEqualToString:@"total"]){
			//that'll do pig, that'll do.
			[parser abortParsing];
		}
		else {
			if ([elementName isEqualToString:@"post"]){
				self.leftColumn = [attributeDict objectForKey:@"title"];
			}
			else if ([elementName isEqualToString:@"day"] || [elementName isEqualToString:@"week"] || [elementName isEqualToString:@"month"]){
				self.leftColumn = [attributeDict objectForKey:@"date"];
			}
			else if ([elementName isEqualToString:@"referrer"] || [elementName isEqualToString:@"searchterm"]  || [elementName isEqualToString:@"click"]){
				self.leftColumn = [attributeDict objectForKey:@"value"];
			}
			self.yValues = [self.yValues stringByAppendingString: [self.leftColumn stringByAppendingString: @","]];
			if (self.leftColumn != nil){
				[yArray addObject:self.leftColumn];
			}
		}
	}
	
	//Uncomment for debugging
	/*for (id key in attributeDict) {
		
		NSLog(@"attribute: %@, value: %@", key, [attributeDict objectForKey:key]);
		
	}*/
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if (self.currentProperty) {
        [self.currentProperty appendString:string];
    }
    
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if (statsRequest){
		if ([elementName isEqualToString:@"post"] || [elementName isEqualToString:@"day"] || [elementName isEqualToString:@"referrer"] || 
			[elementName isEqualToString:@"week"] || [elementName isEqualToString:@"month"] || [elementName isEqualToString:@"searchterm"]
			|| [elementName isEqualToString:@"click"]){
			self.rightColumn = self.currentProperty;
			[xArray addObject: [NSNumber numberWithInt:[self.currentProperty intValue]]];
			NSArray *row = [[NSArray alloc] initWithObjects:self.leftColumn, self.rightColumn, nil];
			[self.statsTableData	addObject:row];
            [row release];
		}
	}
	else if ([elementName isEqualToString:@"apikey"]) {
		[blog setValue:self.currentProperty forKey:@"apiKey"];
		[blog dataSave];
		apiKeyFound = YES;
		[parser abortParsing];
		[self showLoadingDialog];
		//this will run the 'views' report for the past 7 days
		[self refreshStats: 0 reportInterval: 0];
	}
	
	self.currentProperty = nil;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && alertView.tag == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://jetpack.me"]];
    }
	else if (buttonIndex == 0 && alertView.tag == 2) {
        statsAPIAlertShowing = NO;
		canceledAPIKeyAlert = YES;
		[appDelegate.navigationController dismissModalViewControllerAnimated: YES];
    }
	else if (buttonIndex == 1 && alertView.tag == 2) {
        statsAPIAlertShowing = NO;
    }
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	//tableView.backgroundColor = [UIColor clearColor];
	int count = 0;
	switch (section) {
		case 0:
			count = [viewsData count];
			break;
		case 1:
			if (loadMorePostViews >= [postViewsData count]){
				count = [postViewsData count];
			}
			else {
				count = loadMorePostViews + 1;
			}
			break;
		case 2:
			if (loadMoreReferrers >= [referrersData count]){
				count = [referrersData count];
			}
			else {
				count = loadMoreReferrers + 1;
			}
			break;
		case 3:
			if (loadMoreSearchTerms >= [searchTermsData count]){
				count = [searchTermsData count];
			}
			else {
				count = loadMoreSearchTerms + 1;
			}
			break;
		case 4:
			if (loadMoreClicks >= [clicksData count]){
				count = [clicksData count];
			}
			else {
				count = loadMoreClicks + 1;
			}
			break;
	}
	return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL addLoadMoreFooter = NO;
	NSArray *row = [[[NSArray alloc] init] autorelease];
	switch (indexPath.section) {
		case 0:
			//reverse order so today is at top
			row = [viewsData objectAtIndex:(viewsData.count - 1) - indexPath.row];
			break;
		case 1:
			if (indexPath.row == loadMorePostViews){
				addLoadMoreFooter = YES;
			}
			else {
				if ((indexPath.row + 1) > [postViewsData count]){
					row = [postViewsData objectAtIndex:(indexPath.row - 1)];
				}
				else {
					row = [postViewsData objectAtIndex:indexPath.row];
				}
			}
			break;
		case 2:
			if (indexPath.row == loadMoreReferrers){
				addLoadMoreFooter = YES;
			}
			else {
				if ((indexPath.row + 1) > [referrersData count]){
					row = [referrersData objectAtIndex:(indexPath.row - 1)];
				}
				else {
					row = [referrersData objectAtIndex:indexPath.row];
				}
			}
			break;
		case 3:
			if (indexPath.row == loadMoreSearchTerms){
				addLoadMoreFooter = YES;
			}
			else {
				if ((indexPath.row + 1) > [searchTermsData count]){
					row = [searchTermsData objectAtIndex:(indexPath.row - 1)];
				}
				else {
					row = [searchTermsData objectAtIndex:indexPath.row];
				}
			}
			break;
		case 4:
			if (indexPath.row == loadMoreClicks){
				addLoadMoreFooter = YES;
			}
			else {
				if ((indexPath.row + 1) > [clicksData count]){
					row = [clicksData objectAtIndex:(indexPath.row - 1)];
				}
				else {
					row = [clicksData objectAtIndex:indexPath.row];
				}
			}
			break;
	}
	
	if (!addLoadMoreFooter){
        self.leftColumn = [[[NSString alloc] initWithString: [row objectAtIndex:0]] autorelease];
        self.rightColumn = [[[NSString alloc] initWithString: [row objectAtIndex:1]] autorelease];
	}

	NSString *MyIdentifier = [NSString stringWithFormat:@"MyIdentifier %i", indexPath.row];
	
	//if (cell == nil) {
		StatsTableCell *cell = [[[StatsTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		if (viewsData != nil) {

		UILabel *label = [[[UILabel	alloc] initWithFrame:CGRectMake(14.0, 0, 210.0, 
																		tableView.rowHeight)] autorelease];
        label.textColor = [UIColor blackColor]; 
			
		if (addLoadMoreFooter){
			[cell addColumn:280];
			label.frame = CGRectMake(14.0, 0, 266.0, tableView.rowHeight);
			label.font = [UIFont systemFontOfSize:14.0]; 
			label.text = NSLocalizedString(@"Show more...", @"");
			label.textAlignment = UITextAlignmentCenter; 
            label.textColor = [[UIColor alloc] initWithRed:40.0 / 255 green:82.0 / 255 blue:137.0 / 255 alpha:1.0];
		}
		else {
			[cell addColumn:210];
			if (indexPath.section == 0 && indexPath.row == 0) {
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"YYYY-MM-dd"];
                NSDate *latestDate = [dateFormat dateFromString:self.leftColumn]; 
                
                NSCalendar *cal = [NSCalendar currentCalendar];
                NSDateComponents *components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
                NSDate *today = [cal dateFromComponents:components];
                components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:latestDate];
                NSDate *otherDate = [cal dateFromComponents:components];
                
                if([today isEqualToDate:otherDate]) {
                    label.text = NSLocalizedString(@"Today", @"");
                }
                else{
                    [dateFormat setDateFormat:@"MMMM d"];
                    label.text = [dateFormat stringFromDate:latestDate]; 
                }
                [dateFormat release];
			}
			else if (indexPath.section == 0 && indexPath.row > 0){
				//special date formatting for first section
				 NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
				 [dateFormat setDateFormat:@"YYYY-MM-dd"];
				 NSDate *date = [dateFormat dateFromString:self.leftColumn];  
				 [dateFormat setDateFormat:@"MMMM d"];
				 label.text = [dateFormat stringFromDate:date];  
				 [dateFormat release];
			}
			else {
				label.text = self.leftColumn;
			}
			
			if (indexPath.section <= 1 || indexPath.section == 3) {
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            else {
                //if the value isn't a url, don't highlight it when tapped
                NSURL *url = [NSURL URLWithString:self.leftColumn];
                if (url == nil){
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                else{
                    label.textColor = [[UIColor alloc] initWithRed:40.0 / 255 green:82.0 / 255 blue:137.0 / 255 alpha:1.0];
                }
            }
			label.font = [UIFont boldSystemFontOfSize:14.0]; 
			label.textAlignment = UITextAlignmentLeft; 
		}
			
		label.tag = LABEL_TAG; 
		if (indexPath.section == 0 || indexPath.section == 1){
			label.numberOfLines = 2;
		}
		
		label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
		UIViewAutoresizingFlexibleHeight; 
		[cell.contentView addSubview:label]; 
		
		label =  [[[UILabel	alloc] initWithFrame:CGRectMake(226.0, 0, 60.0, tableView.rowHeight)] autorelease]; 
		
		if (!addLoadMoreFooter){
			[cell addColumn:70];
			label.tag = VALUE_TAG; 
			label.font = [UIFont systemFontOfSize:16.0]; 
			//add commas
			NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];	
			NSNumber *statDigits = [numberFormatter numberFromString:self.rightColumn];
            [numberFormatter setLocale:[NSLocale currentLocale]];
			[numberFormatter setGroupingSize: 3];
			[numberFormatter setUsesGroupingSeparator: YES];
			label.text = [numberFormatter stringFromNumber: statDigits];
            [numberFormatter release];
			label.textAlignment = UITextAlignmentRight; 
			label.textColor = [[UIColor alloc] initWithRed:40.0 / 255 green:82.0 / 255 blue:137.0 / 255 alpha:1.0]; 
			label.adjustsFontSizeToFitWidth = YES;
			label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
			UIViewAutoresizingFlexibleHeight; 
			[cell.contentView addSubview:label];
		}
		}
	//}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Navigation logic
	switch (indexPath.section) {
		case 1:
			if (indexPath.row == loadMorePostViews){
				loadMorePostViews += 10;
				[self.tableView reloadData];
			}
			break;
		case 2:
			if (indexPath.row == loadMoreReferrers){
				loadMoreReferrers += 10;
				[self.tableView reloadData];
			}
			else {
                [self viewUrl: [[referrersData objectAtIndex:indexPath.row] objectAtIndex:0]];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
		case 3:
			if (indexPath.row == loadMoreSearchTerms){
				loadMoreSearchTerms += 10;
				[self.tableView reloadData];
			}
			break;
		case 4:
			if (indexPath.row == loadMoreClicks){
				loadMoreClicks += 10;
				[self.tableView reloadData];
			}
			else {
                [self viewUrl: [[clicksData objectAtIndex:indexPath.row] objectAtIndex:0]];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
	}
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
{
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(20, 3, tableView.bounds.size.width - 10, 18)] autorelease];
	switch (section) {
		case 0:
			if (viewsData != nil){
				label.text = NSLocalizedString(@"Daily Views", @"");
			}
			break;
		case 1:
			if (postViewsData != nil){
				label.text = NSLocalizedString(@"Post Views (Past 7 Days)", @"");
			}
			break;
		case 2:
			if (referrersData != nil){
				label.text = NSLocalizedString(@"Referrers (Past 7 Days)", @"");
			}
			break;
		case 3:
			if (referrersData != nil){
				label.text = NSLocalizedString(@"Search Terms (Past 7 Days)", @"");
			}
			break;
		case 4:
			if (clicksData != nil){
				label.text = NSLocalizedString(@"Clicks (Past 7 Days)", @"");
			}
			break;
	}
	
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)] autorelease];
	label.textColor = [UIColor colorWithRed:70.0f/255.0f green:70.0f/255.0f blue:70.0f/255.0f alpha:1.0];
	label.backgroundColor = [UIColor clearColor];
	label.shadowColor = [UIColor whiteColor];
	label.shadowOffset = CGSizeMake(1,1);
	label.font = [UIFont boldSystemFontOfSize:16.0];
	[headerView addSubview:label];
	return headerView;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	//cancel all possible connections
	if (viewsConn != nil)
		[viewsConn cancel];
	if (postViewsConn != nil)
		[postViewsConn cancel];
	if (referrersConn != nil)
		[referrersConn cancel];
	if (searchTermsConn != nil)
		[searchTermsConn cancel];
	if (clicksConn != nil)
		[clicksConn cancel];
	if (daysConn != nil)
		[daysConn cancel];
	if (weeksConn != nil)
		[weeksConn cancel];
	if (monthsConn != nil)
		[monthsConn cancel];
}

- (void)viewDidDisappear:(BOOL)animated {
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewUrl:(NSString*) urlString{
	NSURL *url = [NSURL URLWithString: urlString];
	if (url != nil) {
        WPWebViewController *webViewController;
        if (DeviceIsPad()) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        }
        [webViewController setUrl:url];
        if (DeviceIsPad()) {
            [[[CPopoverManager instance] currentPopoverController] dismissPopoverAnimated:NO];
            [appDelegate.detailNavigationController presentModalViewController:webViewController animated:YES];
        }
        else
            [appDelegate.navigationController pushViewController:webViewController animated:YES];
	}
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	if (statsRequest)
		[self refreshStats:0 reportInterval:0];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return isRefreshingStats; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return self.blog.lastStatsSync; // should return date data source was last changed
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

@end

