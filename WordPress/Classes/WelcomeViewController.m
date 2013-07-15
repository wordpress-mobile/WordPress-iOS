//
//  WelcomeViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//

#import "WelcomeViewController.h"
#import "WordPressAppDelegate.h"
#import "AboutViewController.h"
#import "AddUsersBlogsViewController.h"
#import "CreateWPComBlogViewController.h"
#import "CreateWPComAccountViewController.h"
#import "AddSiteViewController.h"
#import "EditSiteViewController.h"
#import "WPcomLoginViewController.h"
#import "WordPressComApi.h"
#import "WPAccount.h"

@interface WelcomeViewController () <
    WPcomLoginViewControllerDelegate,
    CreateWPComAccountViewControllerDelegate,
    CreateWPComBlogViewControllerDelegate> {
    WordPressAppDelegate *__weak appDelegate;
}

@property (nonatomic, weak) WordPressAppDelegate *appDelegate;

- (void)blogsRefreshNotificationReceived:(NSNotification *)notification;

@end


@implementation WelcomeViewController

@synthesize appDelegate;

@synthesize buttonView;
@synthesize logoView;
@synthesize infoButton;
@synthesize orgBlogButton;
@synthesize addBlogButton;
@synthesize createBlogButton;
@synthesize createLabel;

#pragma mark -
#pragma mark View lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    // If there are blogs, this is being shown in the Settings.
    if ([Blog countWithContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext] > 0) {
        // Hide the Logo View on the iPhone, there isn't enough room for that and the navigation bar.
        if (IS_IPHONE) {
            self.logoView.hidden = YES;
            CGRect frame = buttonView.frame;
            frame.origin.y = 0.0f;
            buttonView.frame = frame;
        }
        createLabel.text = NSLocalizedString(@"If you want to start another blog:", @"");
    }
}


- (void)viewDidUnload {
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.buttonView = nil;
    self.logoView = nil;
    self.infoButton = nil;
    self.orgBlogButton = nil;
    self.addBlogButton = nil;
    self.createBlogButton = nil;
    self.createLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    if (([Blog countWithContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext] <= 0 && ( ![[WordPressComApi sharedApi] hasCredentials] )) || isFirstRun) {
        isFirstRun = YES;
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}


- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE) {
        if ([Blog countWithContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext] == 0) {
            return UIInterfaceOrientationMaskPortrait;
        }
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskAll;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPAD || interfaceOrientation == UIDeviceOrientationPortrait)  
        return YES;
    else if (IS_IPHONE && [Blog countWithContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext] > 0)
        return YES;
    else
        return NO;
}


#pragma mark -
#pragma mark Instance Methods

- (IBAction)handleInfoTapped:(id)sender {
    [self showAboutView];
}


- (IBAction)handleOrgBlogTapped:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventWelcomeViewControllerClickedAddSelfHostedBlog];
    
    AddSiteViewController *addSiteView = [[AddSiteViewController alloc] initWithNibName:nil bundle:nil];    
    [self.navigationController pushViewController:addSiteView animated:YES];
}


- (IBAction)handleAddBlogTapped:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventWelcomeViewControllerClickedAddWordpressDotComBlog];

    if(appDelegate.isWPcomAuthenticated) {
        AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithAccount:[WPAccount defaultWordPressComAccount]];
        addUsersBlogsView.isWPcom = YES;
        [self.navigationController pushViewController:addUsersBlogsView animated:YES];
    }
    else {
        WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
        wpLoginView.delegate = self;
        [self.navigationController pushViewController:wpLoginView animated:YES];
    }
}

- (IBAction)handleCreateBlogTapped:(id)sender {
    [WPMobileStats trackEventForWPCom:StatsEventWelcomeViewControllerClickedCreateWordpressDotComBlog];
    
    if ([WordPressComApi sharedApi].hasCredentials) {
        CreateWPComBlogViewController *viewController = [[CreateWPComBlogViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.delegate = self;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        CreateWPComAccountViewController *viewController = [[CreateWPComAccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.delegate = self;
        [self.navigationController pushViewController:viewController animated:YES];
    }    
}


#pragma mark -
#pragma mark Custom methods

// Add itself as observer for the 'BlogsRefreshNotification' notification. It is used when the app shows the Welcome Screen, since this Screen need to be dismissed upon login action
-(void) automaticallyDismissOnLoginActions {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];    
}


// Called when the AppDelegate receives an URL like 'wordpress://wpcom_signup_completed'
- (void)wpcomSignupNotificationReceived:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"wpcomSignupNotification" object:nil];
    NSDictionary *info = [notification userInfo];
    WPFLog(@"Info received in the notification %@", info);
    [self.navigationController popViewControllerAnimated:NO];
    WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
    wpLoginView.delegate = self;
    wpLoginView.predefinedUsername = [info valueForKey:@"username"];
    [self.navigationController pushViewController:wpLoginView animated:YES];
}


- (void)blogsRefreshNotificationReceived:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BlogsRefreshNotification" object:nil];
    [super dismissModalViewControllerAnimated:YES];
}


- (IBAction)cancel:(id)sender {
	[super dismissModalViewControllerAnimated:YES];
}

- (void)showAboutView {
    AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
	aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentModalViewController:nc animated:YES];
	[self.navigationController setNavigationBarHidden:YES];
}

#pragma mark - WPcomLoginViewControllerDelegate

- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithAccount:(WPAccount *)account {
    [self.navigationController popViewControllerAnimated:NO];
    [self handleAddBlogTapped:nil];
}

#pragma mark - CreateWPComAccountViewControllerDelegate

- (void)createdAndSignedInAccountWithUserName:(NSString *)userName
{
    [self.navigationController popViewControllerAnimated:NO];
    [self handleAddBlogTapped:nil];
}

- (void)createdAccountWithUserName:(NSString *)userName
{
    // In this case the user was able to create an account but for some reason was unable to sign in.
    // Just present the login controller in this case with the data prefilled and give the user the chance to sign in again
    [self.navigationController popViewControllerAnimated:NO];
    WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
    wpLoginView.delegate = self;
    wpLoginView.predefinedUsername = userName;
    [self.navigationController pushViewController:wpLoginView animated:YES];
}

#pragma mark - CreateWPComBlogViewControllerDelegate

- (void)createdBlogWithDetails:(NSDictionary *)blogDetails
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
