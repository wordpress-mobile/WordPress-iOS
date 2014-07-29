#import "FollowedSitesViewController.h"
#import "WPStyleGuide.h"
#import "WPTableViewHandler.h"
#import "ContextManager.h"
#import "ReaderSite.h"

@interface FollowedSitesViewController ()<WPTableViewHandlerDelegate>

@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;

@end

@implementation FollowedSitesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Followed Sites", @"Page title for the list of followed sites.");

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

#pragma mark - Private Methods

- (void)unfollowSiteAtIndexPath:(NSIndexPath *)indexPath
{
// TODO
}


#pragma mark - TableView Handler Delegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSString *)entityName
{
    return @"ReaderSite";
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    request.sortDescriptors = @[sortDescriptor];

    return request;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.textLabel.text length] == 0) {
        // The sizeToFit call in [WPStyleGuide configureTableViewCell:] seems to mess with the
        // UI when cells are configured the first time round and the modal animation is playing.
        // A work around is to only style the cells when not displaying text.
        [WPStyleGuide configureTableViewCell:cell];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;

    ReaderSite *site = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [site.name capitalizedString];
    cell.detailTextLabel.text = site.path;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    [self unfollowSiteAtIndexPath:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Unfollow", @"Label of the table view cell's delete button, when unfollowing tags.");
}


@end
