//
//  StatsTableViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 10/12/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "StatsTableViewController.h"
#import "StatsTableCell.h"
#import "BlogDataManager.h"
#import "UITableViewActivityCell.h"
#import "WPcomLoginViewController.h"
#import "Reachability.h"
#import "CPopoverManager.h"


@implementation StatsTableViewController

@synthesize viewsData, postViewsData, referrersData, searchTermsData, clicksData, reportTitle,
currentBlog, statsData, currentProperty, rootTag, 
statsTableData, leftColumn, rightColumn, spinner, xArray, yArray, xValues, yValues, wpcomLoginTable, 
statsPageControlViewController, refreshButtonItem, selectedIndexPath;
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
	[statsData release];
	[currentProperty release];
	[rootTag release];
	[statsTableData release];
	[leftColumn release];
	[rightColumn release];
	[spinner release];
	[xArray release];
	[yArray release];
	[xValues release];
	[yValues release];
	[wpcomLoginTable release];
	[statsPageControlViewController release];
	[selectedIndexPath release];
	[super dealloc];
}

- (void)viewDidLoad {
	
	loadMorePostViews = 10;
	loadMoreReferrers = 10;
	loadMoreSearchTerms = 10;
	loadMoreClicks = 10;
	
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	self.view.frame = CGRectMake(0, 0, 320, 460);
	//self.tableView.allowsSelection = NO;
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	//init the spinner
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Retrieving stats..."];
	
	statsPageControlViewController = [[StatsPageControlViewController alloc] init];
	connectionToInfoMapping = CFDictionaryCreateMutable(
														kCFAllocatorDefault,
														0,
														&kCFTypeDictionaryKeyCallBacks,
														&kCFTypeDictionaryValueCallBacks);
	
	refreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(initStats)];
	
	if (DeviceIsPad() == YES) {
		self.navigationItem.rightBarButtonItem = refreshButtonItem;
		[self.view removeFromSuperview];
		[statsPageControlViewController initWithNibName:@"StatsPageControlViewController-iPad" bundle:nil];
		[self initWithNibName:@"StatsTableViewConroller-iPad" bundle:nil];
		[appDelegate showContentDetailViewController:self];
	}
	
}



- (void) viewWillAppear:(BOOL)animated {
	
	selectedIndexPath =  [NSIndexPath indexPathForRow:0 inSection:0];
	if([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
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
			[[[CPopoverManager instance] currentPopoverController] dismissPopoverAnimated:YES];
			[appDelegate showContentDetailViewController:self];
		}
		
		//get this party started!
		if (!canceledAPIKeyAlert && !foundStatsData)
			[self initStats]; 
	}
}

- (void)loadView {
    [super loadView];
    
	
}

-(void) initStats {
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];	
	
	NSString *apiKey = [dm.currentBlog valueForKey:@"api_key"];
	
	if (apiKey == nil){
		//first run or api key was deleted
		[self getUserAPIKey];
	}
	else {
		[spinner show];
		statsRequest = true;
		[self refreshStats: 0 reportInterval: 0];
	}
	
	
}

-(void)getUserAPIKey {
	if (appDelegate.isWPcomAuthenticated)
	{
		[spinner show];
		statsData = [[NSMutableData alloc] init];
		CFDictionaryAddValue(
							 connectionToInfoMapping,
							 [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://public-api.wordpress.com/getuserblogs.php"]] delegate:self],
							 [NSMutableDictionary
							  dictionaryWithObject:[NSMutableData data]
							  forKey:@"apiKeyData"]);
		//[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	}
	else 
	{
		BOOL presentDialog = TRUE;
		if (dotorgLogin == TRUE && appDelegate.isWPcomAuthenticated == FALSE)
		{
			presentDialog = FALSE;
			dotorgLogin = FALSE;
		}
		
		if (presentDialog) {
			dotorgLogin = TRUE;
		
		if(DeviceIsPad() == YES) {
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController-iPad" bundle:nil];	
			[self.navigationController pushViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}
		else {
			dotorgLogin = TRUE;
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController" bundle:nil];	
			[appDelegate.navigationController presentModalViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"WordPress.com Stats" 
														 message:@"To load stats for your blog you will need to have the WordPress.com stats plugin installed and correctly configured as well as your WordPress.com login." 
														delegate:self cancelButtonTitle:@"Learn More" otherButtonTitles:nil] autorelease];
		alert.tag = 1;
		[alert addButtonWithTitle:@"I'm Ready!"];
		[alert show];
		}
		
	}
	
}

- (void) refreshStats: (int) titleIndex reportInterval: (int) intervalIndex {
	//load stats into NSMutableArray objects
	foundStatsData = FALSE;
	int days;
	NSString *report = [[NSString alloc] init];
	NSString *period = [[NSString alloc] init];
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
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *blogURL = [dm.currentBlog valueForKey:@"blog_host_name"];
	NSString *apiKey = [dm.currentBlog valueForKey:@"api_key"];
	
	//request the 5 reports for display in the UITableView
	
	NSString *requestURL = [[NSString alloc] init];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	//views
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@", apiKey, blogURL, @"views", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"viewsData"]);
	
	//postviews
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@&summarize", apiKey, blogURL, @"postviews", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"postViewsData"]);
	
	//referrers
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@&summarize", apiKey, blogURL, @"referrers", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"referrersData"]);
	
	//search terms
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@&summarize", apiKey, blogURL, @"searchterms", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"searchTermsData"]);
	
	//clicks
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@&summarize", apiKey, blogURL, @"clicks", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"clicksData"]);
	
	
	//get the three header chart images
	statsData = [[NSMutableData alloc] init];
	statsRequest = TRUE;
	
	// 7 days
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@", apiKey, blogURL, @"views", 7, @""];	
	[request setURL:[NSURL URLWithString:requestURL]];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"chartDaysData"]);
	// 10 weeks
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@", apiKey, blogURL, @"views", 10, @"&period=week"];	
	[request setURL:[NSURL URLWithString:requestURL]];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"chartWeeksData"]);
	// 12 months
	requestURL = [NSString stringWithFormat: @"http://stats.wordpress.com/csv.php?api_key=%@&blog_uri=%@&format=xml&table=%@&days=%d%@", apiKey, blogURL, @"views", 11, @"&period=month"];	
	[request setURL:[NSURL URLWithString:requestURL]];
	[request setValue:@"wp-iphone" forHTTPHeaderField:@"User-Agent"];
	CFDictionaryAddValue(
						 connectionToInfoMapping,
						 [[NSURLConnection alloc] initWithRequest:request delegate:self],
						 [NSMutableDictionary
						  dictionaryWithObject:[NSMutableData data]
						  forKey:@"chartMonthsData"]);
	[request release];
	statsRequest = TRUE;
}

- (void) startParsingStats: (NSString*) xmlString withReportType: (NSString*) reportType {
	statsTableData = nil;
	statsTableData = [[NSMutableArray alloc] init];
	self.tableView.tableHeaderView = statsPageControlViewController.view;
	xArray = [[NSMutableArray alloc] init];
	yArray = [[NSMutableArray alloc] init];
	NSData *data = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
	NSXMLParser *statsParser = [[NSXMLParser alloc] initWithData:data];
	statsParser.delegate = self;
	[statsParser parse];
	[statsParser release];
	if ([xArray count] > 0){
		//set up the new data in the UI
		foundStatsData = TRUE;
		if ([reportType isEqualToString:@"chartDaysData"] || [reportType isEqualToString:@"chartWeeksData"] || [reportType isEqualToString:@"chartMonthsData"]){
			[spinner dismiss];
			NSString *chartViewURL = [[NSString alloc] init];
			xValues = [[NSString alloc] init];
			xValues = [xArray componentsJoinedByString:@","];
			NSArray *sorted = [xArray sortedArrayUsingSelector:@selector(compare:)];
			
			//calculate some variables for the google chart
			int minValue = [[sorted objectAtIndex:0] intValue];
			int maxValue = [[sorted objectAtIndex:[sorted count] - 1] intValue];
			int minBuffer = round(minValue - (maxValue * .10));
			if (minBuffer < 0){
				minBuffer = 0;
			}
			int maxBuffer = round(maxValue + (maxValue * .10));
			//round to the lowest 10 for prettier charts
			for(int i = 0; i < 9; i++) {
				if(minBuffer % 10 == 0)
					break;
				else{
					minBuffer--;
				}
			}
			
			for(int i = 0; i < 9; i++) {
				if(maxBuffer % 10 == 0)
					break;
				else{
					maxBuffer++;
				}
			}
			
			int yInterval = maxBuffer / 10;
			//round the gap in y axis of the chart
			for(int i = 0; i < 9; i++) {
				if(yInterval % 10 == 0)
					break;
				else{
					yInterval++;
				}
			}
			
			NSMutableArray *dateCSV = [[NSMutableArray alloc] init];
			NSDateFormatter *df = [[NSDateFormatter alloc] init];
			NSString *dateValues = [[NSString alloc] initWithString: @""];
			NSString *tempString = [[NSString alloc] initWithString: @""];
			if ([reportType isEqualToString:@"chartDaysData"]){
				for (NSString *dateVal in yArray) {
					[df setDateFormat:@"yyyy-MM-dd"];
					NSDate *tempDate = [df dateFromString: dateVal];
					NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
					NSDateComponents *dateComponents = [gregorian components:(NSWeekdayCalendarUnit) fromDate:tempDate];
					NSInteger day = [dateComponents weekday];
					[gregorian release];
					if (day == 1 || day == 7){
						tempString = @"S";
					}
					else if (day == 2){
						tempString = @"M";
					}
					else if (day == 3 || day == 5){
						tempString = @"T";
					}
					else if (day == 4){
						tempString = @"W";
					}
					else if (day == 6){
						tempString = @"F";
					}
					
					[dateCSV addObject: tempString];
				}
			}
			else if ([reportType isEqualToString:@"chartWeeksData"])
			{
				for (NSString *dateVal in yArray) {
					[dateCSV addObject: [dateVal substringWithRange: NSMakeRange (5, 2)]];
				}
				
			}
			else if ([reportType isEqualToString:@"chartMonthsData"]){
				for (NSString *dateVal in yArray) {
					NSString *month = [[NSString alloc] initWithString: @""];
					[df setDateFormat:@"yyyy-MM"];
					NSDate *tempDate = [df dateFromString: dateVal];
					NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
					NSDateComponents *dateComponents = [gregorian components:(NSMonthCalendarUnit) fromDate:tempDate];
					NSInteger i_month = [dateComponents month];
					[gregorian release];
					if (i_month == 1){
						month = @"Jan";
					}
					else if (i_month == 2){
						month = @"Feb";
					}
					else if (i_month == 3){
						month = @"Mar";
					}
					else if (i_month == 4){
						month = @"Apr";
					}
					else if (i_month == 5){
						month = @"May";
					}
					else if (i_month == 6){
						month = @"Jun";
					}
					else if (i_month == 7){
						month = @"Jul";
					}
					else if (i_month == 8){
						month = @"Aug";
					}
					else if (i_month == 9){
						month = @"Sep";
					}
					else if (i_month == 10){
						month = @"Oct";
					}
					else if (i_month == 11){
						month = @"Nov";
					}
					else if (i_month == 12){
						month = @"Dec";
					}
					[dateCSV addObject: month];
				}
				
			}
			dateValues = [dateCSV componentsJoinedByString:@"|"];
			chartViewURL = [chartViewURL stringByAppendingFormat: @"http://chart.apis.google.com/chart?chts=464646,20&cht=bvs&chg=100,20,1,0&chbh=a&chd=t:%@&chs=560x320&chl=%@&chxt=y,x&chds=%d,%d&chxr=0,%d,%d,%d&chf=c,lg,90,FFFFFF,0,FFFFFF,0.5&chco=a3bcd3&chls=4&chxs=0,464646,20,0,t|1,464646,20,0,t", xValues, dateValues, minBuffer,maxBuffer, minBuffer,maxBuffer, yInterval];
			NSLog(@"google chart url: %@", chartViewURL);
			chartViewURL = [chartViewURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			statsRequest = TRUE;
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
					statsPageControlViewController.chart2Error = TRUE;
					[statsPageControlViewController refreshImage: 2];
				}
				else if (statsPageControlViewController.chart1URL == nil) {
					statsPageControlViewController.chart1Error = TRUE;
					[statsPageControlViewController refreshImage: 1];
				}
			}
		} //end chartData if statement
		else{
			if ([reportType isEqualToString:@"viewsData"]){
				self.viewsData = [[NSArray alloc] initWithArray:statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"postViewsData"]){
				self.postViewsData = [[NSArray alloc] initWithArray:statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"referrersData"]){
				self.referrersData = [[NSArray alloc] initWithArray:statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"searchTermsData"]){
				self.searchTermsData = [[NSArray alloc] initWithArray:statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			if ([reportType isEqualToString:@"clicksData"]){
				self.clicksData = [[NSArray alloc] initWithArray:statsTableData copyItems:YES];
				[self.tableView reloadData];		
			}
			
		}
	}
	else {
		NSLog(@"No data returned! oh noes!");
		if (!foundStatsData && ![reportType isEqualToString:@"apiKeyData"]){
			[self showNoDataFoundError];
		}
		
	}
	[self.view setHidden:FALSE];
	[spinner dismissWithClickedButtonIndex:0 animated:YES];
}

-(void) showNoDataFoundError{
	[self.tableView.tableHeaderView removeFromSuperview];
	UILabel *errorMsg = [[UILabel alloc] init];
	errorMsg.text = @"No stats data found.  Please try again later.";
	self.tableView.tableHeaderView = errorMsg;
}

/*  NSURLConnection Methods  */

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge previousFailureCount] == 0)
	{
		NSURLCredential *newCredential;
		NSString *s_username, *s_password;
		s_username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
		s_password = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"];
		
		newCredential=[NSURLCredential credentialWithUser:s_username
												 password:s_password
											  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
		dotorgLogin = TRUE;
		
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
	NSString *xmlString = [[NSString alloc] initWithString: @""]; 
	//get the key name
	NSArray *keys = [connectionInfo allKeys];
	id aKey = [keys objectAtIndex:0];
	NSString *reportType = aKey;
	//format the xml response
	xmlString = [[NSString alloc] initWithData:[connectionInfo objectForKey:aKey] encoding:NSUTF8StringEncoding];
	xmlString = [xmlString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	xmlString = [xmlString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	NSLog(@"xml string = %@", xmlString);
	NSRange textRange;
	
	textRange =[xmlString rangeOfString:@"Error"];
	if ( xmlString != nil && textRange.location == NSNotFound ) {
		[self startParsingStats: xmlString withReportType: reportType];
	}
	else if (textRange.location != NSNotFound){
		[connection cancel];
		[spinner dismiss];
		//it's the wrong API key, prompt for WPCom login details again
		if(DeviceIsPad() == YES) {
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController-iPad" bundle:nil];	
			[self.navigationController pushViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}
		else {
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController" bundle:nil];	
			[appDelegate.navigationController presentModalViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}
		if (!statsAPIAlertShowing){
			BlogDataManager *dm = [BlogDataManager sharedDataManager];	
			
			[dm.currentBlog removeObjectForKey:@"api_key"];
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"WordPress.com Stats" 
															 message:@"API Key not found. Please enter an administrator login for this blog." 
															delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setTag:2];
			[alert show];
			statsAPIAlertShowing = TRUE;
		}
		
	}
	else {
		NSLog(@"no data returned from api");
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
	[spinner dismissWithClickedButtonIndex:0 animated:YES];
	//UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" 
	//												 message:[error errorInfo] 
	//												delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	//[alert show];
	NSLog(@"ERROR: %@", [error localizedDescription]);
	
	[connection autorelease];
}

/*  XML Parsing  */

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	self.currentProperty = [NSMutableString string];
	if (statsRequest) {
		if ([elementName isEqualToString:@"views"] || [elementName isEqualToString:@"postviews"] || [elementName isEqualToString:@"referrers"] 
			|| [elementName isEqualToString:@"clicks"] || [elementName isEqualToString:@"searchterms"] || [elementName isEqualToString:@"videoplays"] 
			|| [elementName isEqualToString:@"title"]) {
			rootTag = elementName;
		}
		else if ([elementName isEqualToString:@"total"]){
			//that'll do pig, that'll do.
			[parser abortParsing];
		}
		else {
			if ([elementName isEqualToString:@"post"]){
				leftColumn = [attributeDict objectForKey:@"title"];
			}
			else if ([elementName isEqualToString:@"day"] || [elementName isEqualToString:@"week"] || [elementName isEqualToString:@"month"]){
				leftColumn = [attributeDict objectForKey:@"date"];
			}
			else if ([elementName isEqualToString:@"referrer"] || [elementName isEqualToString:@"searchterm"]  || [elementName isEqualToString:@"click"]){
				leftColumn = [attributeDict objectForKey:@"value"];
			}
			yValues = [yValues stringByAppendingString: [leftColumn stringByAppendingString: @","]];
			if (leftColumn != nil){
				[yArray addObject: leftColumn];
			}
		}
	}
	
	for (id key in attributeDict) {
		
		NSLog(@"attribute: %@, value: %@", key, [attributeDict objectForKey:key]);
		
	}
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if (self.currentProperty) {
        [currentProperty appendString:string];
    }
    
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if (statsRequest){
		if ([elementName isEqualToString:@"post"] || [elementName isEqualToString:@"day"] || [elementName isEqualToString:@"referrer"] || 
			[elementName isEqualToString:@"week"] || [elementName isEqualToString:@"month"] || [elementName isEqualToString:@"searchterm"]
			|| [elementName isEqualToString:@"click"]){
			rightColumn = self.currentProperty;
			[xArray addObject: [NSNumber numberWithInt:[currentProperty intValue]]];
			NSArray *row = [[NSArray alloc] initWithObjects:leftColumn, rightColumn, nil];
			[statsTableData	addObject:row];
		}
	}
	else if ([elementName isEqualToString:@"apikey"]) {
		[dm.currentBlog setObject:self.currentProperty forKey:@"api_key"];
		[dm saveCurrentBlog];
		apiKeyFound = TRUE;
		[parser abortParsing];
		[spinner show];
		//this will run the 'views' report for the past 7 days
		[self refreshStats: 0 reportInterval: 0];
	}
	
	self.currentProperty = nil;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && alertView.tag == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://wordpress.org/extend/plugins/stats/"]];
    }
	else if (buttonIndex == 0 && alertView.tag == 2) {
        statsAPIAlertShowing = FALSE;
		canceledAPIKeyAlert = TRUE;
		[appDelegate.navigationController dismissModalViewControllerAnimated: TRUE];
    }
	else if (buttonIndex == 1 && alertView.tag == 2) {
        statsAPIAlertShowing = FALSE;
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
	BOOL addLoadMoreFooter = FALSE;
	NSArray *row = [[NSArray alloc] init];
	switch (indexPath.section) {
		case 0:
			row = [viewsData objectAtIndex:indexPath.row];
			break;
		case 1:
			if (indexPath.row == loadMorePostViews){
				addLoadMoreFooter = TRUE;
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
				addLoadMoreFooter = TRUE;
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
				addLoadMoreFooter = TRUE;
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
				addLoadMoreFooter = TRUE;
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
	leftColumn = [[NSString alloc] initWithString: [row objectAtIndex:0]];
	rightColumn = [[NSString alloc] initWithString: [row objectAtIndex:1]];
	}

	NSString *MyIdentifier = [NSString stringWithFormat:@"MyIdentifier %i", indexPath.row];
	
	StatsTableCell *cell = (StatsTableCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	
	//if (cell == nil) {
		cell = [[[StatsTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		if (viewsData != nil) {

		UILabel *label = [[[UILabel	alloc] initWithFrame:CGRectMake(14.0, 0, 140.0, 
																		tableView.rowHeight)] autorelease]; 
			
		if (addLoadMoreFooter){
			[cell addColumn:280];
			label.frame = CGRectMake(14.0, 0, 266.0, tableView.rowHeight);
			label.font = [UIFont systemFontOfSize:14.0]; 
			label.text = @"Show more...";
			label.textAlignment = UITextAlignmentCenter; 
		}
		else {
			[cell addColumn:140];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			label.font = [UIFont boldSystemFontOfSize:14.0]; 
			label.text = leftColumn;
			label.textAlignment = UITextAlignmentLeft; 
		}
			
		label.tag = LABEL_TAG; 
		if (indexPath.section == 0 || indexPath.section == 1){
			label.numberOfLines = 2;
		}
		
		label.textColor = [UIColor blackColor]; 
		label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
		UIViewAutoresizingFlexibleHeight; 
		[cell.contentView addSubview:label]; 
		
		label =  [[[UILabel	alloc] initWithFrame:CGRectMake(160.0, 0, 120.0, tableView.rowHeight)] autorelease]; 
		
		if (!addLoadMoreFooter){
			[cell addColumn:130];
			label.tag = VALUE_TAG; 
			label.font = [UIFont systemFontOfSize:16.0]; 
			label.text = rightColumn;
			label.textAlignment = UITextAlignmentRight; 
			label.textColor = [[UIColor alloc] initWithRed:40.0 / 255 green:82.0 / 255 blue:137.0 / 255 alpha:1.0]; 
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
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *reportName = [[NSString alloc] init];
	switch (section) {
		case 0:
			if (viewsData != nil){
				reportName = @"Daily Views";
			}
			break;
		case 1:
			if (postViewsData != nil){
				reportName = @"Post Views";
			}
			break;
		case 2:
			if (referrersData != nil){
				reportName = @"Referrers";
			}
			break;
		case 3:
			if (referrersData != nil){
				reportName = @"Search Terms";
			}
			break;
		case 4:
			if (clicksData != nil){
				reportName = @"Clicks";
			}
			break;
	}
	return reportName;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	selectedIndexPath = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

@end

