#import "SharingViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "SharingConnectionsViewController.h"
#import "SVProgressHUD+Dismiss.h"
#import "WordPress-Swift.h"
#import <WordPressUI/UIImage+Util.h>
#import <WordPressShared/WPTableViewCell.h>

typedef NS_ENUM(NSInteger, SharingSectionType) {
    SharingSectionUndefined = 1000,
    SharingSectionAvailableServices,
    SharingSectionUnsupported,
    SharingSectionSharingButtons
};

static NSString *const CellIdentifier = @"CellIdentifier";

@interface SharingViewController ()

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) NSArray<PublicizeService *> *publicizeServices;

// Contains Publicize services that are currently available for use.
@property (nonatomic, strong) NSArray<PublicizeService *> *supportedServices;

// Contains unsupported Publicize services that are deprecated or temporarily disabled.
@property (nonatomic, strong) NSArray<PublicizeService *> *unsupportedServices;

// A list of `SharingSectionType` that represents the sections displayed in the table view.
@property (nonatomic, strong) NSArray<NSNumber *> *sections;

@property (nonatomic, weak) id delegate;
@property (nonatomic) PublicizeServicesState *publicizeServicesState;
@property (nonatomic) JetpackModuleHelper *jetpackModuleHelper;

@end

@implementation SharingViewController

- (instancetype)initWithBlog:(Blog *)blog delegate:(id)delegate
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [self initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _blog = blog;
        _publicizeServices = [NSMutableArray new];
        _supportedServices = @[];
        _unsupportedServices = @[];
        _delegate = delegate;
        _publicizeServicesState = [PublicizeServicesState new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Sharing", @"Title for blog detail sharing screen.");
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    if (self.isModal) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(doneButtonTapped)];
    }

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.publicizeServicesState addInitialConnections:[self allConnections]];

    self.navigationController.presentationController.delegate = self;

    if ([self.blog supportsPublicize]) {
        [self syncServices];
    } else {
        self.jetpackModuleHelper = [[JetpackModuleHelper alloc] initWithViewController:self moduleName:@"publicize" blog:self.blog];

        [self.jetpackModuleHelper showWithTitle:NSLocalizedString(@"Enable Publicize", "Text shown when the site doesn't have the Publicize module enabled.") subtitle:NSLocalizedString(@"In order to share your published posts to your social media you need to enable the Publicize module.", "Title of button to enable publicize.")];

        self.tableView.dataSource = NULL;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [ReachabilityUtils dismissNoInternetConnectionNotice];
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
    [self notifyDelegatePublicizeServicesChangedIfNeeded];
}

- (void)refreshPublicizers
{
    self.publicizeServices = [PublicizeService allPublicizeServicesInContext:[self managedObjectContext] error:nil];

    // Separate supported and unsupported Publicize services.
    NSPredicate *supportedPredicate = [NSPredicate predicateWithFormat:@"status == %@", PublicizeService.defaultStatus];
    self.supportedServices = [self.publicizeServices filteredArrayUsingPredicate:supportedPredicate];

    NSPredicate *unsupportedPredicate = [NSPredicate predicateWithFormat:@"status == %@", PublicizeService.unsupportedStatus];
    NSArray<PublicizeService *> *unsupportedList = [self.publicizeServices filteredArrayUsingPredicate:unsupportedPredicate];

    // only list unsupported services with existing connections.
    NSMutableArray<PublicizeService *> *unsupportedServicesWithConnections = [NSMutableArray new];
    for (PublicizeService *service in unsupportedList) {
        if ([self connectionsForService:service].count > 0) {
            [unsupportedServicesWithConnections addObject:service];
        }
    }
    self.unsupportedServices = unsupportedServicesWithConnections;

    // Refresh table sections in case anything changes.
    [self refreshSections];

    [self.tableView reloadData];
}

- (void)doneButtonTapped
{
    [self notifyDelegatePublicizeServicesChangedIfNeeded];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view sections

- (void)refreshSections {
    NSMutableArray<NSNumber *> *sections = [NSMutableArray new];

    if ([self.supportedServices count] > 0) {
        [sections addObject:@(SharingSectionAvailableServices)];
    }

    if (self.unsupportedServices.count > 0) {
        [sections addObject:@(SharingSectionUnsupported)];
    }

    if ([self.blog supportsShareButtons]) {
        [sections addObject:@(SharingSectionSharingButtons)];
    }

    self.sections = sections;
}

- (SharingSectionType)sectionTypeForIndex:(NSInteger)index
{
    if (index >= self.sections.count) {
        return SharingSectionUndefined;
    }

    return [self.sections objectAtIndex:index].intValue;
}

#pragma mark - UITableView Delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SharingSectionType sectionType = [self sectionTypeForIndex:section];
    switch (sectionType) {
        case SharingSectionAvailableServices:
            return NSLocalizedString(@"Jetpack Social Connections", @"Section title for Publicize services in Sharing screen");

        case SharingSectionUnsupported:
            return NSLocalizedStringWithDefaultValue(
                                              @"social.section.disabledTwitter.header",
                                              nil,
                                              [NSBundle mainBundle],
                                              @"Twitter Auto-Sharing Is No Longer Available",
                                              @"Section title for the disabled Twitter service in the Social screen");

        case SharingSectionSharingButtons:
            return NSLocalizedString(@"Sharing Buttons", @"Section title for the sharing buttons section in the Sharing screen");

        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    SharingSectionType sectionType = [self sectionTypeForIndex:section];
    if (sectionType == SharingSectionAvailableServices) {
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
    SharingSectionType sectionType = [self sectionTypeForIndex:section];
    switch (sectionType) {
        case SharingSectionAvailableServices:
            return self.supportedServices.count;
        case SharingSectionUnsupported:
            return self.unsupportedServices.count;
        case SharingSectionSharingButtons:
            return 1;
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Remove?
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

    SharingSectionType sectionType = [self sectionTypeForIndex:indexPath.section];
    switch (sectionType) {
        case SharingSectionAvailableServices: // fallthrough
        case SharingSectionUnsupported:
            [self configurePublicizeCell:cell atIndexPath:indexPath];
            break;

        case SharingSectionSharingButtons:
            cell.textLabel.text = NSLocalizedString(@"Manage", @"Verb. Text label. Tapping displays a screen where the user can configure 'share' buttons for third-party services.");
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            break;

        default:
            return [UITableViewCell new];
    }

    return cell;
}

- (PublicizeService *)publicizeServiceForIndexPath:(NSIndexPath *)indexPath
{
    SharingSectionType sectionType = [self sectionTypeForIndex:indexPath.section];
    switch (sectionType) {
        case SharingSectionAvailableServices:
            return self.supportedServices[indexPath.row];
        case SharingSectionUnsupported:
            return self.unsupportedServices[indexPath.row];
        default:
            return nil;
    }
}

- (void)configurePublicizeCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    PublicizeService *publicizer = [self publicizeServiceForIndexPath:indexPath];
    NSArray *connections = [self connectionsForService:publicizer];

    // TODO: Remove?
    if ([publicizer.serviceID isEqualToString:PublicizeService.googlePlusServiceID] && [connections count] == 0) { // Temporarily hiding Google+
        cell.hidden = YES;
        return;
    }

    // Configure the image
    UIImage *image = [WPStyleGuide socialIconFor:publicizer.serviceID];
    [cell.imageView setImage:image];

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

    if (![publicizer isSupported]) {
        cell.accessoryView = [WPStyleGuide sharingCellErrorAccessoryImageView];
        return;
    }

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
    SharingSectionType sectionType = [self sectionTypeForIndex:indexPath.section];
    switch (sectionType) {
        case SharingSectionAvailableServices: // fallthrough
        case SharingSectionUnsupported: {
            PublicizeService *publicizer = [self publicizeServiceForIndexPath:indexPath];
            controller = [[SharingConnectionsViewController alloc] initWithBlog:self.blog publicizeService:publicizer];
            [WPAppAnalytics track:WPAnalyticsStatSharingOpenedPublicize withBlog:self.blog];

            [[QuickStartTourGuide shared] visited:QuickStartTourElementConnections];
            break;
        }

        case SharingSectionSharingButtons:
            controller = [[SharingButtonsViewController alloc] initWithBlog:self.blog];
            [WPAppAnalytics track:WPAnalyticsStatSharingOpenedSharingButtonSettings withBlog:self.blog];
            break;

        default:
            return;
    }

    [self.navigationController pushViewController:controller animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    SharingSectionType sectionType = [self sectionTypeForIndex:section];
    switch (sectionType) {
        case SharingSectionUnsupported:
            return [self makeTwitterDeprecationFooterView];

        case SharingSectionSharingButtons:
            if ([SharingViewController jetpackBrandingVisibile]) {
                return [self makeJetpackBadge];
            }
            break;

        default:
            break;
    }

    return nil;
}

#pragma mark - JetpackModuleHelper

- (void)jetpackModuleEnabled
{
    self.tableView.dataSource = self;
    [self syncServices];
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

- (NSArray *)allConnections
{
    NSMutableArray *allConnections = [NSMutableArray new];
    for (PublicizeService *service in self.publicizeServices) {
        NSArray *connections = [self connectionsForService:service];
        if (connections.count > 0) {
            [allConnections addObjectsFromArray:connections];
        }
    }
    return allConnections;
}

-(void)notifyDelegatePublicizeServicesChangedIfNeeded
{
    if ([self.publicizeServicesState hasAddedNewConnectionTo:[self allConnections]]) {
        [self.delegate didChangePublicizeServices];
    }
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
    SharingService *sharingService = [[SharingService alloc] initWithContextManager:[ContextManager sharedInstance]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeServicesForBlog:self.blog success:^{
        [weakSelf syncConnections];
    } failure:^(NSError * __unused error) {
        if (!ReachabilityUtils.isInternetReachable) {
            [weakSelf showConnectionError];
        } else {
            [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Jetpack Social service synchronization failed", @"Message to show when Publicize service synchronization failed")];
            [weakSelf refreshPublicizers];
        }
    }];
}

- (void)syncConnections
{
    SharingSyncService *sharingService = [[SharingSyncService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    __weak __typeof__(self) weakSelf = self;
    [sharingService syncPublicizeConnectionsForBlog:self.blog success:^{
        [weakSelf refreshPublicizers];
    } failure:^(NSError * __unused error) {
        if (!ReachabilityUtils.isInternetReachable) {
            [weakSelf showConnectionError];
        } else {
            [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Jetpack Social connection synchronization failed", @"Message to show when Publicize connection synchronization failed")];
            [weakSelf refreshPublicizers];
        }
    }];
}

- (void)syncSharingButtonsIfNeeded
{
    // Sync sharing buttons if they have never been synced. Otherwise, the
    // management vc can worry about fetching the latest sharing buttons.
    NSArray *buttons = [SharingButton allSharingButtonsForBlog:self.blog inContext:[self managedObjectContext] error:nil];
    if ([buttons count] > 0) {
        return;
    }

    SharingService *sharingService = [[SharingService alloc] initWithContextManager:[ContextManager sharedInstance]];
    [sharingService syncSharingButtonsForBlog:self.blog success:nil failure:^(NSError *error) {
        DDLogError([error description]);
    }];
}

@end
