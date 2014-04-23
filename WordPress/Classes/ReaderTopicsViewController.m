#import "ReaderPostsViewController.h"
#import "ReaderTopicsViewController.h"
#import "WordPressComApi.h"
#import "ReaderPost.h"
#import "WPFriendFinderViewController.h"
#import "WPTableViewSectionHeaderView.h"
#import "NSString+XMLExtensions.h"
#import "Constants.h"

@interface ReaderTopicsViewController ()

@property (nonatomic, assign) BOOL topicsLoaded;
@property (nonatomic, strong) NSArray *topicsArray;
@property (nonatomic, strong) NSArray *listsArray;
@property (nonatomic, strong) NSDictionary *currentTopic;

@end

@implementation ReaderTopicsViewController


#pragma mark - LifeCycle Methods

- (id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self) {
		self.listsArray = [self fetchLists];
        
		self.topicsArray = [[NSUserDefaults standardUserDefaults] arrayForKey:ReaderTopicsArrayKey] ?: @[];
		
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
    
    [self fetchTagsAndLists];
	
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

#pragma mark - Instance Methods

- (NSArray *)fetchLists {
    NSArray *arr = [[NSUserDefaults standardUserDefaults] arrayForKey:ReaderListsArrayKey];
    
    if (arr.count > 0) {
        return arr;
    }
    
    arr = [ReaderPost readerEndpoints];
    NSIndexSet *indexSet = [arr indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = (NSDictionary *)obj;
        return [[dict objectForKey:@"default"] boolValue];
    }];
    return [arr objectsAtIndexes:indexSet];
}

- (void)handleCancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)fetchTagsAndLists {
	
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
	
	[ReaderPost getReaderMenuItemsWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.tableView setTableFooterView:nil];
        NSDictionary *dict = (NSDictionary *)responseObject;
		
        NSDictionary *defaultItems, *subscribedItems;
        
        if ([dict[@"default"] isKindOfClass:[NSDictionary class]]) {
            defaultItems = dict[@"default"];
        }
        
        if ([dict[@"subscribed"] isKindOfClass:[NSDictionary class]]) {
            subscribedItems = dict[@"subscribed"];
        } else if ([dict[@"recommended"] isKindOfClass:[NSDictionary class]]) {
            subscribedItems = dict[@"recommended"];
        }
        
        NSMutableArray *lists = [NSMutableArray arrayWithCapacity:defaultItems.count];
        NSMutableArray *tags = [NSMutableArray arrayWithCapacity:subscribedItems.count];
		
        [defaultItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *title = [obj objectForKey:@"title"];
            title = [title stringByDecodingXMLCharacters];
            NSString *endpoint = [obj objectForKey:@"URL"];
            [lists addObject:@{@"title": title, @"endpoint":endpoint}];
        }];
		
        [subscribedItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *title = [obj objectForKey:@"title"];
            title = [title stringByDecodingXMLCharacters];
            NSString *endpoint = [obj objectForKey:@"URL"];
            [tags addObject:@{@"title": title, @"endpoint":endpoint}];
        }];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        self.listsArray = [lists sortedArrayUsingDescriptors:@[sortDescriptor]];
        self.topicsArray = [tags sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:tags forKey:ReaderTopicsArrayKey];
        [defaults setObject:lists forKey:ReaderListsArrayKey];
        [defaults synchronize];
        
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView setTableFooterView:nil];
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Unable to Load Topics", nil) message:NSLocalizedString(@"Sorry. There was a problem loading the topics list.  Please try again later.", nil)];
    }];
}


- (void)handleFriendFinderButtonTapped:(id)sender {
    WPFriendFinderViewController *controller = [[WPFriendFinderViewController alloc] init];
	[self.navigationController pushViewController:controller animated:YES];
    [controller loadURL:WPMobileReaderFFURL];
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
		return [_listsArray count];
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
		arr = _listsArray;
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
		arr = _listsArray;
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
