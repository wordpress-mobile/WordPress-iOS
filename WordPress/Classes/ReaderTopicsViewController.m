//
//  ReaderTopicsViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostsViewController.h"
#import "ReaderTopicsViewController.h"
#import "WordPressComApi.h"
#import "ReaderPost.h"
#import "WPFriendFinderViewController.h"
#import "WPTableViewSectionHeaderView.h"
#import "NSString+XMLExtensions.h"

@interface ReaderTopicsViewController ()

@property (nonatomic, assign) BOOL topicsLoaded;
@property (nonatomic, strong) NSArray *topicsArray;
@property (nonatomic, strong) NSArray *defaultTopicsArray;
@property (nonatomic, strong) NSDictionary *currentTopic;

- (NSArray *)fetchDefaultTopics;
- (void)loadTopics;
- (void)handleFriendFinderButtonTapped:(id)sender;

@end

@implementation ReaderTopicsViewController


#pragma mark - LifeCycle Methods

- (id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self) {
		self.defaultTopicsArray = [self fetchDefaultTopics];
        
        NSArray *arr = [[NSUserDefaults standardUserDefaults] arrayForKey:ReaderExtrasArrayKey];
        if (arr != nil) {
            self.defaultTopicsArray = [_defaultTopicsArray arrayByAddingObjectsFromArray:arr];
        }
        
		arr = [[NSUserDefaults standardUserDefaults] arrayForKey:ReaderTopicsArrayKey];
		if (arr == nil) {
			arr = @[];
		}
		self.topicsArray = arr;
		
        self.currentTopic = [ReaderPost currentTopic];
    }
	
	return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Browse", @"Title of the Reader Topics screen");
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(handleCancelButtonTapped:)];
    self.navigationItem.rightBarButtonItem = cancelButton;

	UIBarButtonItem *friendFinderButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Friends", @"")
																		   style:[WPStyleGuide barButtonStyleForBordered]
																		  target:self
																		  action:@selector(handleFriendFinderButtonTapped:)];
	self.navigationItem.leftBarButtonItem = friendFinderButton;
    
    [self loadTopics];
	
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

#pragma mark - Instance Methods

- (NSArray *)fetchDefaultTopics {
    NSArray *arr = [ReaderPost readerEndpoints];
    NSIndexSet *indexSet = [arr indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = (NSDictionary *)obj;
        return [[dict objectForKey:@"default"] boolValue];
    }];
    return [arr objectsAtIndexes:indexSet];
}

- (void)handleCancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
            title = [title stringByDecodingXMLCharacters];
			NSString *endpoint = [NSString stringWithFormat:topicEndpoint, [dict stringForKey:@"category_nicename"]];
			[topics addObject:@{@"title": title, @"endpoint":endpoint}];
		}
		
		self.topicsArray = topics;
		[[NSUserDefaults standardUserDefaults] setObject:topics forKey:ReaderTopicsArrayKey];
		
		arr = [dict objectForKey:@"extra"];
		if (arr) {
			NSMutableArray *extras = [NSMutableArray array];
			for (NSDictionary *dict in arr) {
				NSString *title = [dict objectForKey:@"cat_name"];
				NSString *endpoint = [dict objectForKey:@"endpoint"];
				[extras addObject:@{@"title": title, @"endpoint":endpoint}];
			}
            [[NSUserDefaults standardUserDefaults] setObject:extras forKey:ReaderExtrasArrayKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
			self.defaultTopicsArray = [[self fetchDefaultTopics] arrayByAddingObjectsFromArray:extras];
		}
        
		[self.tableView reloadData];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[self.tableView setTableFooterView:nil];
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Unable to Load Topics", nil) message:NSLocalizedString(@"Sorry. There was a problem loading the topics list.  Please try again later.", nil)];
	}];
}


- (void)handleFriendFinderButtonTapped:(id)sender {
    WPFriendFinderViewController *controller = [[WPFriendFinderViewController alloc] init];
	[self.navigationController pushViewController:controller animated:YES];
    [controller loadURL:kMobileReaderFFURL];
}


#pragma mark - TableView methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    switch (section) {
		case 0:
			return NSLocalizedString(@"Lists", @"Section title for the default reader lists");
			break;
			
		default:
			return NSLocalizedString(@"Tags", @"Section title for reader tags you can browse");
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
    [WPStyleGuide configureTableViewCell:cell];
	
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeNotification object:self];
	}
	
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
