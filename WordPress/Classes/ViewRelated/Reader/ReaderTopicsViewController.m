#import "ReaderTopicsViewController.h"
#import "WPTableViewControllerSubclass.h"
#import "WPFriendFinderViewController.h"
#import "WPTableViewSectionHeaderView.h"
#import "Constants.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "ContextManager.h"
#import "WPTableViewCell.h"

NSString * const ReaderTopicDidChangeNotification = @"ReaderTopicDidChangeNotification";

@interface ReaderTopicsViewController ()<NSFetchedResultsControllerDelegate>

@property (nonatomic, copy) NSString *currentTopicPath;
@property (nonatomic, readonly) ReaderTopic *currentTopic;
@property (nonatomic, strong) NSDate *dateLastSynced;

@end

@implementation ReaderTopicsViewController


#pragma mark - LifeCycle Methods

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

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}


#pragma mark - Instance Methods

- (ReaderTopic *)currentTopic {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    return [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
}

- (void)handleCancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleFriendFinderButtonTapped:(id)sender {
    WPFriendFinderViewController *controller = [[WPFriendFinderViewController alloc] init];
	[self.navigationController pushViewController:controller animated:YES];
    [controller loadURL:WPMobileReaderFFURL];
}

- (void)dispatchTopicDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeNotification object:nil];
}

#pragma mark - TableView methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

    ReaderTopic *topic = (ReaderTopic *)[self.resultsController objectAtIndexPath:indexPath];

    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    service.currentTopic = topic;

    [self dispatchTopicDidChangeNotification];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WPTableViewController Subclass Methods

- (NSString *)entityName {
    return @"ReaderTopic";
}

- (NSDate *)lastSyncDate {
    return self.dateLastSynced;
}

- (NSFetchRequest *)fetchRequest {
    // If the user has subscriptions show those, else show the recommended topics.
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
	NSUInteger numberOfSubscribedReaderTopics = [service numberOfSubscribedTopics];
    NSString *predStr;
    if (numberOfSubscribedReaderTopics > 0) {
         predStr = @"topicID = 0 OR isSubscribed = YES";
    } else {
         predStr = @"topicID = 0 OR isSubscribed = NO";
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    request.predicate = [NSPredicate predicateWithFormat:predStr];

    NSSortDescriptor *sortDescriptorType = [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES];
    NSSortDescriptor *sortDescriptorTitle = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];

    request.sortDescriptors = @[sortDescriptorType, sortDescriptorTitle];

    return request;
}

- (NSString *)sectionNameKeyPath {
    return @"type";
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if ([cell.textLabel.text length] == 0) {
        // The sizeToFit call in [WPStyleGuide configureTableViewCell:] seems to mess with the
        // UI when cells are configured the first time round and the modal animation is playing.
        // A work around is to only style the cells when not displaying text.
        [WPStyleGuide configureTableViewCell:cell];
    }
    ReaderTopic *topic = [self.resultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [topic.title capitalizedString];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([[[self.currentTopic objectID] URIRepresentation] isEqual:[[topic objectID] URIRepresentation]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.detailTextLabel.text = nil;
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *error))failure {
    self.currentTopicPath = self.currentTopic.path;
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [service fetchReaderMenuWithSuccess:^{
        self.dateLastSynced = [NSDate date];
        success();

        // Its possible the user deleted the current topic via the web so make sure the selection is accurate
        ReaderTopic *topic = [self currentTopic];
        if (![self.currentTopicPath isEqualToString:topic.path]) {
            self.currentTopicPath = topic.path;
            [self updateSelectedTopic];
        }

    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)updateSelectedTopic {
    ReaderTopic *topic = [self currentTopic];
    NSIndexPath *indexPath = [self.resultsController indexPathForObject:topic];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self dispatchTopicDidChangeNotification];
}

- (Class)cellClass {
    return [WPTableViewCell class];
}

@end
