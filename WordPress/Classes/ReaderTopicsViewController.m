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

NSString *const ReaderCurrentTopicKey = @"ReaderCurrentTopicKey";

@interface ReaderTopicsViewController ()

@property (nonatomic, assign) BOOL topicsLoaded;
@property (nonatomic, strong) NSArray *topicsArray;
@property (nonatomic, strong) NSArray *defaultTopicsArray;
@property (nonatomic, strong) NSDictionary *currentTopic;

- (void)loadTopics;

@end

@implementation ReaderTopicsViewController

@synthesize delegate;

#pragma mark - LifeCycle Methods

- (void)dealloc {
	
}


- (id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self) {
		[self loadTopics];
		
		NSArray *arr = [ReaderPost readerEndpoints];
		NSIndexSet *indexSet = [arr indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *dict = (NSDictionary *)obj;
			return [[dict objectForKey:@"default"] boolValue];
		}];
		self.defaultTopicsArray = [arr objectsAtIndexes:indexSet];
				
		NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ReaderCurrentTopicKey];
		if (dict) {
			self.currentTopic = dict;
		} else {
			self.currentTopic = [_defaultTopicsArray objectAtIndex:0];
			[[NSUserDefaults standardUserDefaults] setObject:_currentTopic forKey:ReaderCurrentTopicKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
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
	[ReaderPost getReaderTopicsWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *dict = (NSDictionary *)responseObject;
		
		NSString *topicEndpoint = [[[ReaderPost readerEndpoints] objectAtIndex:ReaderTopicEndpointIndex] objectForKey:@"endpoint"];
		NSArray *arr = [dict objectForKey:@"topics"];
		NSMutableArray *topics = [NSMutableArray arrayWithCapacity:[arr count]];
		
		for (NSDictionary *dict in arr) {
			NSString *title = [dict objectForKey:@"cat_name"];
			NSString *endpoint = [NSString stringWithFormat:topicEndpoint, [dict objectForKey:@"cat_id"]];
			[topics addObject:@{@"title": title, @"endpoint":endpoint}];
		}
		
		self.topicsArray = topics;		
		
		[self refreshIfReady];
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		// TODO. 
	}];
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
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	switch (section) {
		case 0:
			return [_defaultTopicsArray count];
			break;
			
		default:
			return [_topicsArray count];
			break;
	}
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
	cell.textLabel.text = [dict objectForKey:@"title"];
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
