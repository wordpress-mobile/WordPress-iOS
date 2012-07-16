//
//  WelcomeViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//

#import "WelcomeViewController.h"
#import "SFHFKeychainUtils.h"
#import "WordPressAppDelegate.h"
#import "AboutViewController.h"
#import "AddUsersBlogsViewController.h"
#import "AddSiteViewController.h"
#import "EditSiteViewController.h"
#import "WebSignupViewController.h"
#import "WPcomLoginViewController.h"
#import "XMLSignupViewController.h"


@interface WelcomeViewController () <WPcomLoginViewControllerDelegate> {
    WordPressAppDelegate *appDelegate;
}

@property (nonatomic, assign) WordPressAppDelegate *appDelegate;

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

- (id)init {
    self = [super init];
    if (self) {
        forceLogoView = NO;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [buttonView release];
    [logoView release];
    [infoButton release];
    [orgBlogButton release];
    [addBlogButton release];
    [createBlogButton release];
    [createLabel release];

    [super dealloc];
}


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    // The welcome screen is presented without a navbar so this is a convenient way to
    // know if the user has blogs or not.
    if ([self.navigationController.viewControllers count] > 1 && !forceLogoView) {
        if (IS_IPHONE) {        
            self.logoView.hidden = YES;
            CGRect frame = buttonView.frame;
            frame.origin.y = 0.0f;
            buttonView.frame = frame;
        }
        createLabel.text = NSLocalizedString(@"Want to start another blog?", @"");
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
    if ([self.navigationController.viewControllers count] <= 1 || forceLogoView)
        [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark -
#pragma mark Instance Methods

- (IBAction)handleInfoTapped:(id)sender {
    [self showAboutView];
}


- (IBAction)handleOrgBlogTapped:(id)sender {
    AddSiteViewController *addSiteView;
    if(IS_IPAD == YES) {
        addSiteView = [[AddSiteViewController alloc] initWithNibName:@"AddSiteViewController-iPad" bundle:nil];
    } else {
        addSiteView = [[AddSiteViewController alloc] initWithNibName:@"AddSiteViewController" bundle:nil];
    }
    
    [self.navigationController pushViewController:addSiteView animated:YES];
    [addSiteView release];
}


- (IBAction)handleAddBlogTapped:(id)sender {
    NSString *username = nil;
    NSString *password = nil;
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] != nil) {
        NSError *error = nil;
        username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        password = [SFHFKeychainUtils getPasswordForUsername:username
                                              andServiceName:@"WordPress.com"
                                                       error:&error];
    }
    
    if(appDelegate.isWPcomAuthenticated) {
        AddUsersBlogsViewController *addUsersBlogsView;
        if (IS_IPAD == YES)
            addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController-iPad" bundle:nil];
        else
            addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
        addUsersBlogsView.isWPcom = YES;
        [addUsersBlogsView setUsername:username];
        [addUsersBlogsView setPassword:password];
        [self.navigationController pushViewController:addUsersBlogsView animated:YES];
        [addUsersBlogsView release];
    }
    else {
        WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
        wpLoginView.delegate = self;
        [self.navigationController pushViewController:wpLoginView animated:YES];
        [wpLoginView release];
    }
}


- (IBAction)handleCreateBlogTapped:(id)sender {
    NSString *newNibName = @"WebSignupViewController";
    if(IS_IPAD == YES)
        newNibName = @"WebSignupViewController-iPad";
    WebSignupViewController *webSignup = [[WebSignupViewController alloc] initWithNibName:newNibName bundle:[NSBundle mainBundle]];
    [self.navigationController pushViewController:webSignup animated:YES];
    [webSignup release];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wpcomSignupNotificationReceived:) name:@"wpcomSignupNotification" object:nil];
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
    [wpLoginView release];
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
	//aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self.navigationController pushViewController:aboutViewController animated:YES];
    [aboutViewController release];
}


- (void)forceLogoView {
    forceLogoView = YES;
}


#pragma mark - WPcomLoginViewControllerDelegate

- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithUsername:(NSString *)username {
    [self.navigationController popViewControllerAnimated:NO];
    [self handleAddBlogTapped:nil];
}


@end
