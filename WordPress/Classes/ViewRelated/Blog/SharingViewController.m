#import "SharingViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "WPTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "Publicizer.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationWebViewController.h"

NS_ENUM(NSInteger, SharingSection) {
    SharingPublicize = 0,
    //SharingConnections,
    //SharingButtons,
    //SharingOptions,
    SharingSectionCount,
};

static NSString *const PublicizeCellIdentifier = @"PublicizeCell";

@interface SharingViewController () <SharingAuthorizationDelegate>

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

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:PublicizeCellIdentifier];
    
    [self refreshPublicizers];

}

- (void)refreshPublicizers
{
    self.publicizeServices = [self.blog.publicizers sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:TRUE]]];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SharingSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicize:
            return NSLocalizedString(@"Publicize", @"Section title for Publicize services in Sharing screen");
        default:
            return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (title.length > 0) {
        WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
        header.title = title;
        return header;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicize:
            return self.publicizeServices.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PublicizeCellIdentifier forIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];

    switch (indexPath.section) {
        case SharingPublicize: {
            Publicizer *publicizer = self.publicizeServices[indexPath.row];
            cell.textLabel.text = publicizer.label;

            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button addTarget:self action:@selector(cellButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            NSString *title = publicizer.isConnected ? NSLocalizedString(@"Disconnect", @"Button title to disconnect a Publicize service") : NSLocalizedString(@"Connect", @"Button title to connect a Publicize service");
            [button setTitle:title forState:UIControlStateNormal];
            [button sizeToFit];
            cell.accessoryView = button;
        } break;
        default:
            break;
    }
    
    return cell;
}

- (void)cellButtonTapped:(UIButton *)sender
{
    UITableViewCell *tappedCell = (UITableViewCell *)[sender superview];
    NSIndexPath *tappedPath = [self.tableView indexPathForCell:tappedCell];
    [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:tappedPath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    Publicizer *publicizer = self.publicizeServices[indexPath.row];
    if (publicizer.isConnected) {
        [self disconnectPublicizer:publicizer];
    } else {
        [self connectPublicizer:publicizer interact:YES];
    }
}

#pragma mark - Publicizer management

- (void)connectPublicizer:(Publicizer *)publicizer interact:(BOOL)interact
{
    NSParameterAssert(publicizer);
    
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService checkAuthorizationForPublicizer:publicizer success:^(NSDictionary *authorization) {
        [blogService connectPublicizer:publicizer
                     withAuthorization:authorization
                               success:^(NSDictionary *authorization) {
            [self refreshPublicizers];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connect failed", @"Message to show when Publicize connect failed")];
        }];
    } failure:^(NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Authorization failed", @"Message to show when Publicize authorization failed")];
        } else if (interact) {
            [self authorizePublicizer:publicizer];
        }
    }];
}

- (void)authorizePublicizer:(Publicizer *)publicizer
{
    NSParameterAssert(publicizer);
    
    SharingAuthorizationWebViewController *webViewController = [SharingAuthorizationWebViewController controllerWithPublicizer:publicizer forBlog:self.blog];
    webViewController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)authorizeDidSucceed:(Publicizer *)publicizer
{
    [self connectPublicizer:publicizer interact:NO];
}

- (void)authorize:(Publicizer *)publicizer didFailWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Authorization failed", @"Message to show when Publicize authorization failed")];
}

- (void)authorizeDidCancel:(Publicizer *)publicizer
{
    // called in response to user dismissal
}

- (void)disconnectPublicizer:(Publicizer *)publicizer
{
    NSParameterAssert(publicizer);
    
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService disconnectPublicizer:publicizer success:^{
        [self refreshPublicizers];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Disconnect failed", @"Message to show when Publicize disconnect failed")];
    }];
}

@end
