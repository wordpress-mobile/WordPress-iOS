#import "SubscribedTopicsViewController.h"
#import "WPStyleGuide.h"
#import "ReaderTopicService.h"
#import "ReaderTopic.h"
#import "ContextManager.h"
#import "WPTableViewHandler.h"
#import "WPAccount.h"
#import "AccountService.h"

@interface SubscribedTopicsViewController ()<WPTableViewHandlerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;

@end

@implementation SubscribedTopicsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Followed Tags", @"Page title for the list of subscribed tags.");

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.rowHeight = 44.0;
    self.tableView.estimatedRowHeight = 44.0;
    if (IS_IPHONE) {
        // Account for 1 pixel header height
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
    }
    [self.view addSubview:self.tableView];

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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];

    if (editing) {
        UITableViewCell *cell = [[self.tableView visibleCells] lastObject];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath.section == 0 && [self.tableView numberOfSections] > 1) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}

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
    NSIndexPath *indexPath  = [self.tableViewHandler.resultsController indexPathForObject:topic];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    if (!self.editing) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
}

- (void)handleReaderTopicChanged:(NSNotification *)notification
{
    [self updateSelectedTopic];
}

- (void)unfollowTopicAtIndexPath:(NSIndexPath *)indexPath
{
    ReaderTopic *topic = (ReaderTopic *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service unfollowTopic:topic withSuccess:^{
        //noop
    } failure:^(NSError *error) {
        DDLogError(@"Could not unfollow topic: %@", error);

        NSString *title = NSLocalizedString(@"Could not Unfollow Topic", @"");
        NSString *description = error.localizedDescription;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:description
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Label text for the close button on an alert view.")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }];
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
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    request.predicate = [NSPredicate predicateWithFormat:@"(topicID = 0 OR isSubscribed = YES) AND (isMenuItem = YES)"];

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
    cell.textLabel.text = topic.title;
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
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    service.currentTopic = topic;

    [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeViaUserInteractionNotification object:nil];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Lists", @"Section title for the default reader lists");
    }

    return NSLocalizedString(@"Tags", @"Section title for reader tags you can browse");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return NO;
    }
    return self.isEditing;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self unfollowTopicAtIndexPath:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Unfollow", @"Label of the table view cell's delete button, when unfollowing tags.");
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self updateSelectedTopic];
    self.topicListChangedBlock();
}

- (BOOL)isEditable
{
    return [self.tableView numberOfSections] > 1 ? YES : NO;
}

@end
