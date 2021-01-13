#import "SharingViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SharingConnectionsViewController.h"
#import "SVProgressHUD+Dismiss.h"
#import "WordPress-Swift.h"
#import <WordPressUI/UIImage+Util.h>
#import <WordPressShared/WPTableViewCell.h>

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

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self syncServices];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [ReachabilityUtils dismissNoInternetConnectionNotice];
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == SharingPublicizeServices) {
        return NSLocalizedString(@"Connect your favorite social media services to automatically share new posts with friends.", @"");
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.publicizeServices count] > 0) {
        PublicizeService *publicizer = self.publicizeServices[indexPath.row];
        NSArray *connections = [self connectionsForService:publicizer];
        if ([publicizer.serviceID isEqualToString:PublicizeService.googlePlusServiceID] && [connections count] == 0) { // Temporarily hiding Google+
            return 0;
        }
    }
    
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

    [WPStyleGuide configureTableViewCell:cell];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath == [NSIndexPath indexPathForRow:0 inSection:0] && [[QuickStartTourGuide shared] isCurrentElement:QuickStartTourElementConnections]) {
        cell.accessoryView = [QuickStartSpotlightView new];
    } else {
        cell.accessoryView = nil;
    }

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
    
    if ([publicizer.serviceID isEqualToString:PublicizeService.googlePlusServiceID] && [connections count] == 0) { // Temporarily hiding Google+
        cell.hidden = YES;
        return;
    }

    // Configure the image
    UIImage *image = [WPStyleGuide iconForService: publicizer.serviceID];
    [cell.imageView setImage:image];
    cell.imageView.tintColor = ([connections count] > 0) ? [WPStyleGuide tintColorForConnectedService: publicizer.serviceID] : [UIColor murielListIcon];

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
        if ([pubConn requiresUserAction]) {
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
        [WPAppAnalytics track:WPAnalyticsStatSharingOpenedPublicize withBlog:self.blog];

        [[QuickStartTourGuide shared] visited:QuickStartTourElementConnections];
    } else {
        controller = [[SharingButtonsViewController alloc] initWithBlog:self.blog];
        [WPAppAnalytics track:WPAnalyticsStatSharingOpenedSharingButtonSettings withBlog:self.blog];
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

-(void)syncServices
{
    // Optimistically sync the sharing buttons.
    [self syncSharingButtonsIfNeeded];
    
    // Refreshes the tableview.
    [self refreshPublicizers];
    
    // Syncs servcies and connections.
    [self syncPublicizeServices];
    
}

-(void)showConnectionError
{
    [ReachabilityUtils showNoInternetConnectionNoticeWithMessage: ReachabilityUtils.noConnectionMessage];
}

- (void)syncPublicizeServices
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeServicesForBlog:self.blog success:^{
        [weakSelf syncConnections];
    } failure:^(NSError *error) {
        if (!ReachabilityUtils.isInternetReachable) {
            [weakSelf showConnectionError];
        } else {
            [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Publicize service synchronization failed", @"Message to show when Publicize service synchronization failed")];
            [weakSelf refreshPublicizers];
        }
    }];
}

- (void)syncConnections
{
    SharingService *sharingService = [[SharingService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeConnectionsForBlog:self.blog success:^{
        [weakSelf refreshPublicizers];
    } failure:^(NSError *error) {
        if (!ReachabilityUtils.isInternetReachable) {
            [weakSelf showConnectionError];
        } else {
            [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Publicize connection synchronization failed", @"Message to show when Publicize connection synchronization failed")];
            [weakSelf refreshPublicizers];
        }
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
