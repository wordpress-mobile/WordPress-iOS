#import "SharingViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SharingDetailViewController.h"
#import "SVProgressHUD.h"
#import "WPTableViewCell.h"
#import "WordPress-Swift.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <WordPressShared/WPTableViewSectionHeaderFooterView.h>

typedef NS_ENUM(NSInteger, SharingSection){
    SharingPublicizeConnections = 0,
    SharingButtons,
    SharingSectionCount,
};

static NSString *const PublicizeCellIdentifier = @"PublicizeCell";

@interface PublicizeCell : WPTableViewCell
@end

@implementation PublicizeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:style reuseIdentifier:reuseIdentifier];
}

@end

@interface SharingViewController ()

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) NSArray *publicizeServices;

@end

@implementation SharingViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
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
    [self.tableView registerClass:[PublicizeCell class] forCellReuseIdentifier:PublicizeCellIdentifier];

    // Refreshes the tableview.
    [self refreshPublicizers];

    // Syncs servcies and connections.
    [self syncPublicizeServices];
}

- (void)refreshPublicizers
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    self.publicizeServices = [sharingService allPublicizeServices];

    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SharingSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicizeConnections:
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
    if (section == SharingPublicizeConnections) {
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
        case SharingPublicizeConnections:
            return self.publicizeServices.count;
        case SharingButtons:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PublicizeCell *cell = [tableView dequeueReusableCellWithIdentifier:PublicizeCellIdentifier forIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (indexPath.section == SharingPublicizeConnections) {
        PublicizeService *publicizer = self.publicizeServices[indexPath.row];
        cell.textLabel.text = publicizer.label;
        NSURL *url = [NSURL URLWithString:publicizer.icon];
        [cell.imageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"post-blavatar-placeholder"]];

        PublicizeConnection *conn = [self connectionForService:publicizer];
        if (conn) {
            cell.detailTextLabel.text = conn.externalDisplay;
        } else {
            cell.detailTextLabel.text = nil;
        }

    } else if (indexPath.section == SharingButtons) {
        cell.textLabel.text = NSLocalizedString(@"Manage", @"Verb. Text label. Tapping displays a screen where the user can configure 'share' buttons for third-party services.");
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PublicizeService *publicizer = self.publicizeServices[indexPath.row];
    SharingDetailViewController *controller = [[SharingDetailViewController alloc] initWithBlog:self.blog publicizeService:publicizer];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - Publicizer management

- (PublicizeConnection *)connectionForService:(PublicizeService *)publicizeService
{
    for (PublicizeConnection *pubConn in self.blog.connections) {
        if ([pubConn.service isEqualToString:publicizeService.serviceID]) {
            return pubConn;
        }
    }
    return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.blog.managedObjectContext;
}

- (void)syncPublicizeServices
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeServices:^{
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

@end
