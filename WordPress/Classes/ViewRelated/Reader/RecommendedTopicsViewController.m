#import "RecommendedTopicsViewController.h"
#import "WPStyleGuide.h"
#import "ReaderTopicService.h"
#import "ReaderTopic.h"
#import "ContextManager.h"
#import "WPTableViewHandler.h"
#import "WPAccount.h"
#import "AccountService.h"

@interface RecommendedTopicsViewController ()<WPTableViewHandlerDelegate>

@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;

@end

@implementation RecommendedTopicsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Popular Tags", @"Page title for the list of recommended tags.");

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.rowHeight = 44.0;
    self.tableView.estimatedRowHeight = 44.0;
    [self.view addSubview:self.tableView];

    if (IS_IPHONE) {
        // Account for 1 pixel header height
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
    }
    
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.delegate = self;

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReaderTopicChanged:) name:ReaderTopicDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Instance Methods

- (BOOL)isWPComUser
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    return [defaultAccount isWpcom];
}

- (ReaderTopic *)currentTopic
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    return [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
}

- (void)updateSelectedTopic
{
    NSArray *cells = [self.tableView visibleCells];
    for (UITableViewCell *cell in cells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    ReaderTopic *topic = [self currentTopic];
    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:topic];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)handleReaderTopicChanged:(NSNotification *)notification
{
    [self updateSelectedTopic];
}


#pragma mark - TableView Handler Delegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSString *)entityName
{
    return @"ReaderTopic";
}

- (NSFetchRequest *)fetchRequest
{
    NSString *predStr;
    if ([self isWPComUser]) {
        predStr = @"topicID > 0 AND isSubscribed = NO";
    } else {
        // include lists for non wpcom users
        predStr = @"topicID = 0 OR isSubscribed = NO";
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    request.predicate = [NSPredicate predicateWithFormat:predStr];

    NSSortDescriptor *sortDescriptorType = [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES];
    NSSortDescriptor *sortDescriptorTitle = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    request.sortDescriptors = @[sortDescriptorType, sortDescriptorTitle];

    return request;
}

- (NSString *)sectionNameKeyPath
{
    return @"type";
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.textLabel.text length] == 0) {
        // The sizeToFit call in [WPStyleGuide configureTableViewCell:] seems to mess with the
        // UI when cells are configured the first time round and the modal animation is playing.
        // A work around is to only style the cells when not displaying text.
        [WPStyleGuide configureTableViewCell:cell];
    }
    ReaderTopic *topic = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [topic.title capitalizedString];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([[[self.currentTopic objectID] URIRepresentation] isEqual:[[topic objectID] URIRepresentation]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.detailTextLabel.text = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

    ReaderTopic *topic = (ReaderTopic *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([self isWPComUser]) {
        // Subscribe to this recommended topic.
        ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
        [service subscribeToAndMakeTopicCurrent:topic];
        [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeViaUserInteractionNotification object:nil];
    } else {
        // Make this the current topic
        ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
        service.currentTopic = topic;
        [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeViaUserInteractionNotification object:nil];
    }
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
		case 0:
			return NSLocalizedString(@"Lists", @"Section title for the default reader lists");
			break;

		default:
			return NSLocalizedString(@"Tags", @"Section title for reader tags you can browse");
			break;
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
