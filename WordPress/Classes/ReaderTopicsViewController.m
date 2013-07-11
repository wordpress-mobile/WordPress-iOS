//
//  ReaderTopicsViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderTopicsViewController.h"
#import "WordPressComApi.h"
#import "ReaderPost.h"
#import "WPFriendFinderViewController.h"

NSString *const ReaderTopicsArrayKey = @"ReaderTopicsArrayKey";

@interface ReaderTopicsViewController ()

@property (nonatomic, assign) BOOL topicsLoaded;
@property (nonatomic, strong) NSArray *topicsArray;
@property (nonatomic, strong) NSArray *defaultTopicsArray;
@property (nonatomic, strong) NSDictionary *currentTopic;

- (void)loadTopics;
- (void)handleFriendFinderButtonTapped:(id)sender;

@end

@implementation ReaderTopicsViewController

@synthesize delegate;

#pragma mark - LifeCycle Methods

- (id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self) {
		NSArray *arr = [ReaderPost readerEndpoints];
		NSIndexSet *indexSet = [arr indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *dict = (NSDictionary *)obj;
			return [[dict objectForKey:@"default"] boolValue];
		}];
		self.defaultTopicsArray = [arr objectsAtIndexes:indexSet];
		
		arr = [[NSUserDefaults standardUserDefaults] arrayForKey:ReaderTopicsArrayKey];
		if (arr == nil) {
			arr = @[];
		}
		self.topicsArray = arr;
		
		NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ReaderCurrentTopicKey];
		if (dict) {
			self.currentTopic = dict;
		} else {
			self.currentTopic = [_defaultTopicsArray objectAtIndex:0];
			[[NSUserDefaults standardUserDefaults] setObject:_currentTopic forKey:ReaderCurrentTopicKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		
		[self loadTopics];
	}
	
	return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Topics", @"Title of the Reader Topics screen");
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(handleCancelButtonTapped:)];
    self.navigationItem.rightBarButtonItem = cancelButton;

	UIBarButtonItem *friendFinderButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Friends", @"")
																		   style:UIBarButtonItemStyleBordered
																		  target:self
																		  action:@selector(handleFriendFinderButtonTapped:)];
	self.navigationItem.leftBarButtonItem = friendFinderButton;
	
    self.tableView.backgroundView = nil;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];
	
	[self refreshIfReady];
}


#pragma mark - Instance Methods

- (void)refreshIfReady {
	if([self.topicsArray count] && [self isViewLoaded]) {
		[self.tableView reloadData];
	}
}


- (void)handleCancelButtonTapped:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


- (void)loadTopics {
	
	if ([self.topicsArray count] == 0) {
		CGFloat width = self.tableView.frame.size.width;
		UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, activityView.frame.size.height)];
		footerView.backgroundColor = [UIColor clearColor];
		CGRect frame = activityView.frame;
		frame.origin.x = (width / 2.0f ) - (activityView.frame.size.width / 2.0f);
		activityView.frame = frame;
		[footerView addSubview:activityView];
		[self.tableView setTableFooterView:footerView];
		[activityView startAnimating];
	}
	
	[ReaderPost getReaderTopicsWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		[self.tableView setTableFooterView:nil];
		NSDictionary *dict = (NSDictionary *)responseObject;
		
		NSString *topicEndpoint = [[[ReaderPost readerEndpoints] objectAtIndex:ReaderTopicEndpointIndex] objectForKey:@"endpoint"];
		NSArray *arr = [dict arrayForKey:@"topics"];
		NSMutableArray *topics = [NSMutableArray arrayWithCapacity:[arr count]];
		
		for (NSDictionary *dict in arr) {
			NSString *title = [dict objectForKey:@"cat_name"];
			NSString *endpoint = [NSString stringWithFormat:topicEndpoint, [dict objectForKey:@"cat_name"]];
			[topics addObject:@{@"title": title, @"endpoint":endpoint}];
		}
		
		self.topicsArray = topics;
		[[NSUserDefaults standardUserDefaults] setObject:topics forKey:ReaderTopicsArrayKey];
		[NSUserDefaults resetStandardUserDefaults];
		
		arr = [dict objectForKey:@"extra"];
		if (arr) {
			NSMutableArray *extras = [NSMutableArray arrayWithArray:_defaultTopicsArray];
			for (NSDictionary *dict in arr) {
				NSString *title = [dict objectForKey:@"cat_name"];
				NSString *endpoint = [dict objectForKey:@"endpoint"];
				[extras addObject:@{@"title": title, @"endpoint":endpoint}];
			}
			self.defaultTopicsArray = extras;
		}
		
		[self refreshIfReady];
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[self.tableView setTableFooterView:nil];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to Load Topics", @"")
															message:NSLocalizedString(@"Sorry. There was a problem loading the topics list.  Please try again later.", @"")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", @"")
												  otherButtonTitles:nil, nil];
		[alertView show];
	}];
}


- (void)handleFriendFinderButtonTapped:(id)sender {
	NSLog(@"Tapped");
    WPFriendFinderViewController *controller = [[WPFriendFinderViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
    [controller loadURL:kMobileReaderFFURL];
}


#pragma mark - TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return NSLocalizedString(@"Lists", @"Section title for the default reader lists");
			break;
			
		default:
			return NSLocalizedString(@"Topics", @"");
			break;
	}
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([_topicsArray count]) {
		return 2;
	}
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [_defaultTopicsArray count];
	}
	return [_topicsArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TopicCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	NSArray *arr = nil;
	if (indexPath.section == 0) {
		arr = _defaultTopicsArray;
	} else {
		arr = _topicsArray;
	}
    
	NSDictionary *dict = [arr objectAtIndex:indexPath.row];
	cell.textLabel.text = [[dict objectForKey:@"title"] capitalizedString];
	cell.accessoryType = UITableViewCellAccessoryNone;
	if([[_currentTopic objectForKey:@"endpoint"] isEqualToString:[dict objectForKey:@"endpoint"]]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// Selected topics yo.
	NSArray *arr = nil;
	if (indexPath.section == 0) {
		arr = _defaultTopicsArray;
	} else {
		arr = _topicsArray;
	}
    
	NSDictionary *dict = [arr objectAtIndex:indexPath.row];
	
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:ReaderCurrentTopicKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if(![[dict objectForKey:@"endpoint"] isEqualToString:[_currentTopic objectForKey:@"endpoint"]]) {
		if(self.delegate) {
			[delegate readerTopicChanged];
		}
	}
	
	[self dismissModalViewControllerAnimated:YES];
}


@end
