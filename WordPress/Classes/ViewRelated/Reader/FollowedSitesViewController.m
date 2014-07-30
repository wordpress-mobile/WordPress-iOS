#import "FollowedSitesViewController.h"
#import "WPStyleGuide.h"
#import "WPTableViewHandler.h"
#import "ContextManager.h"
#import "ReaderSite.h"
#import "ReaderSiteService.h"
#import "WPTableViewCell.h"
#import "UIImageView+Gravatar.h"
#import "WPNoResultsView.h"

static NSString * const SiteCellIdentifier = @"SiteCellIdentifier";

@interface FollowedSitesViewController ()<WPTableViewHandlerDelegate>

@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) WPNoResultsView *noResultsView;

@end

@implementation FollowedSitesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Followed Sites", @"Page title for the list of followed sites.");

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.rowHeight = 54.0;
    self.tableView.estimatedRowHeight = 54.0;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self configureNoResultsView];
    [self syncSites];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}


#pragma mark - Private Methods

- (void)syncSites
{
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service fetchFollowedSitesWithSuccess:^{
        [self configureNoResultsView];
    } failure:^(NSError *error) {
        DDLogError(@"Could not sync sites: %@", error);
        [self configureNoResultsView];
    }];
}

- (void)unfollowSiteAtIndexPath:(NSIndexPath *)indexPath
{
    ReaderSite *site = (ReaderSite *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service unfollowSite:site success:^{
        [self syncSites];

    } failure:^(NSError *error) {
        DDLogError(@"Could not unfollow site: %@", error);

        NSString *title = NSLocalizedString(@"Could not Unfollow Site", @"");
        NSString *description = error.localizedDescription;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:description
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Label text for the close button on an alert view.")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

- (void)configureNoResultsView
{
    if ([[self.tableViewHandler.resultsController fetchedObjects] count] > 0) {
        [self.noResultsView removeFromSuperview];
    } else {
        [self.view addSubview:self.noResultsView];
        [self.noResultsView centerInSuperview];
    }
}

- (WPNoResultsView *)noResultsView
{
    if (_noResultsView) {
        return _noResultsView;
    }

    NSString *title = NSLocalizedString(@"No Sites", @"Title of a message explaining that the user is not currently following any blogs in their reader.");
    NSString *message = NSLocalizedString(@"You're not following any sites yet.  Why not follow one now?", @"A suggestion to the user that they try following a site in their reader.");
    _noResultsView = [WPNoResultsView noResultsViewWithTitle:title
                                                     message:message
                                               accessoryView:nil
                                                 buttonTitle:nil];
    return _noResultsView;
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
    cell.imageView.image = [UIImage imageNamed:@"gravatar-reader"];

    ReaderSite *site = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [site.name capitalizedString];
    cell.detailTextLabel.text = site.path;
    if (site.icon) {
        [cell.imageView setImageWithBlavatarUrl:site.icon];
    }

    [WPStyleGuide configureTableViewSmallSubtitleCell:cell];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SiteCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SiteCellIdentifier];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54.0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    return NSLocalizedString(@"Unfollow", @"Label of the table view cell's delete button, when unfollowing a site.");
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if ([[self.tableViewHandler.resultsController fetchedObjects] count] > 0) {
        return NSLocalizedString(@"Sites", @"Section title for sites the user has followed.");
    }
    return nil;
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self configureNoResultsView];
}

@end
