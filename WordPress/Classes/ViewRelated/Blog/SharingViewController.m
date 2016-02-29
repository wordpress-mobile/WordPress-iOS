#import "SharingViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SharingConnectionsViewController.h"
#import "SVProgressHUD.h"
#import "WPTableViewCell.h"
#import "WordPress-Swift.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <WordPressShared/UIImage+Util.h>
#import <WordPressShared/WPTableViewSectionHeaderFooterView.h>

typedef NS_ENUM(NSInteger, SharingSectionIdentifier){
    SharingPublicizeServices = 0,
    SharingButtons,
    SharingSectionCount,
};

static NSString *const CellIdentifier = @"CellIdentifier";

@interface SharingViewController ()

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) NSArray *publicizeServices;

@end

@implementation SharingViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [self initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeServices = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Sharing", @"Title for blog detail sharing screen.");

    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    // Optimistically sync the sharing buttons.
    [self syncSharingButtonsIfNeeded];

    // Refreshes the tableview.
    [self refreshPublicizers];

    // Syncs servcies and connections.
    [self syncPublicizeServices];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (void)refreshPublicizers
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    self.publicizeServices = [sharingService allPublicizeServices];

    [self.tableView reloadData];
}


#pragma mark - UITableView Delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = SharingSectionCount;
    if (![self.blog supportsShareButtons]) {
        count -= 1;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderFooterView heightForHeader:title width:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicizeServices:
            return NSLocalizedString(@"Connections", @"Section title for Publicize services in Sharing screen");
        case SharingButtons:
            return NSLocalizedString(@"Sharing Buttons", @"Section title for the sharing buttons section in the Sharing screen");
        default:
            return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    if (title.length == 0) {
        return nil;
    }

    WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
    header.title = title;
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == SharingPublicizeServices) {
        return NSLocalizedString(@"Connect your favorite social media services to automatically share new posts with friends.", @"");
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForFooterInSection:section];
    if (title.length == 0) {
        return nil;
    }

    WPTableViewSectionHeaderFooterView *footer = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleFooter];
    footer.title = title;
    return footer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicizeServices:
            return self.publicizeServices.count;
        case SharingButtons:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

    [WPStyleGuide configureTableViewCell:cell];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;

    if (indexPath.section == SharingPublicizeServices) {
        [self configurePublicizeCell:cell atIndexPath:indexPath];

    } else if (indexPath.section == SharingButtons) {
        cell.textLabel.text = NSLocalizedString(@"Manage", @"Verb. Text label. Tapping displays a screen where the user can configure 'share' buttons for third-party services.");
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
    }

    return cell;
}

- (void)configurePublicizeCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    PublicizeService *publicizer = self.publicizeServices[indexPath.row];
    NSArray *connections = [self connectionsForService:publicizer];

    // Configure the image
    UIImage *image = [WPStyleGuide iconForService: publicizer.serviceID];
    [cell.imageView setImage:image];
    cell.imageView.tintColor = ([connections count] > 0) ? [WPStyleGuide tintColorForConnectedService: publicizer.serviceID] : [WPStyleGuide greyLighten20];

    // Configure the text
    cell.textLabel.text = publicizer.label;

    // Show the name(s) or number of connections.
    NSString *str = @"";
    if ([connections count] > 2) {
        NSString *format = NSLocalizedString(@"%d accounts", @"The number of connected accounts on a third party sharing service connected to the user's blog. The '%d' is a placeholder for the number of accounts.");
        str = [NSString stringWithFormat:format, [connections count]];
    } else {
        NSMutableArray *names = [NSMutableArray array];
        for (PublicizeConnection *pubConn in connections) {
            [names addObject:pubConn.externalDisplay];
        }
        str = [names componentsJoinedByString:@", "];
    }

    cell.detailTextLabel.text = str;

    // Check if any of the connections are broken.
    for (PublicizeConnection *pubConn in connections) {
        if ([pubConn isBroken]) {
            cell.accessoryView = [WPStyleGuide sharingCellWarningAccessoryImageView];
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *controller;
    if (indexPath.section == 0) {
        PublicizeService *publicizer = self.publicizeServices[indexPath.row];
        controller = [[SharingConnectionsViewController alloc] initWithBlog:self.blog publicizeService:publicizer];
    } else {
        controller = [[SharingButtonsViewController alloc] initWithBlog:self.blog];
    }

    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - Publicizer management

// TODO: Good candidate for a helper method
- (NSArray *)connectionsForService:(PublicizeService *)publicizeService
{
    NSMutableArray *connections = [NSMutableArray array];
    for (PublicizeConnection *pubConn in self.blog.connections) {
        if ([pubConn.service isEqualToString:publicizeService.serviceID]) {
            [connections addObject:pubConn];
        }
    }
    return [NSArray arrayWithArray:connections];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.blog.managedObjectContext;
}

- (void)syncPublicizeServices
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeServicesForBlog:self.blog success:^{
        [weakSelf syncConnections];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Publicize service synchronization failed", @"Message to show when Publicize service synchronization failed")];
        [weakSelf refreshPublicizers];
    }];
}

- (void)syncConnections
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeConnectionsForBlog:self.blog success:^{
        [weakSelf refreshPublicizers];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Publicize connection synchronization failed", @"Message to show when Publicize connection synchronization failed")];
        [weakSelf refreshPublicizers];
    }];
}

- (void)syncSharingButtonsIfNeeded
{
    // Sync sharing buttons if they have never been synced. Otherwise, the
    // management vc can worry about fetching the latest sharing buttons.
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    NSArray *buttons = [sharingService allSharingButtonsForBlog:self.blog];
    if ([buttons count] > 0) {
        return;
    }
    [sharingService syncSharingButtonsForBlog:self.blog success:nil failure:^(NSError *error) {
        DDLogError([error description]);
    }];
}

@end
