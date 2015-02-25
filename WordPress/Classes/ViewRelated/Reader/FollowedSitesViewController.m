#import "FollowedSitesViewController.h"
#import "WPStyleGuide.h"
#import "WPTableViewHandler.h"
#import "ContextManager.h"
#import "ReaderSite.h"
#import "ReaderSiteService.h"
#import "WPTableViewCell.h"
#import "UIImageView+Gravatar.h"
#import "WPNoResultsView.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"

static NSString * const SiteCellIdentifier = @"SiteCellIdentifier";
static CGFloat const FollowSitesRowHeight = 54.0;

@interface FollowedSitesViewController ()<WPTableViewHandlerDelegate>

@property (nonatomic, strong) UITableView *tableView;
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
        [service syncPostsForFollowedSites];
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
    NSString *message = NSLocalizedString(@"You are not following any sites yet. Why not follow one now?", @"A suggestion to the user that they try following a site in their reader.");
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
    UIImage *defaultImage = [UIImage imageNamed:@"icon-feed"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.imageView.image = defaultImage;
    cell.imageView.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    ReaderSite *site = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [site nameForDisplay];
    cell.detailTextLabel.text = [site pathForDisplay];;
    if (site.icon) {
        cell.imageView.backgroundColor = nil;
        [cell.imageView setImageWithBlavatarUrl:site.icon placeholderImage:defaultImage];
    }

    [WPStyleGuide configureTableViewSmallSubtitleCell:cell];

    // The inital layout is a little off and reloading the view doesn't correct it.
    // Forcing layout of the cell's subviews corrects the issue.
    [cell layoutSubviews];
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
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return FollowSitesRowHeight;
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
    // Return an space instead of empty string or nil to preserve the section
    // header's height if all items are removed and then one added back.
    return @" ";
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self.tableViewHandler updateTitleForSection:0];
    [self configureNoResultsView];
}

- (BOOL)isEditable
{
     return [self.tableView numberOfRowsInSection:0] > 0 ? YES : NO;
}

@end
