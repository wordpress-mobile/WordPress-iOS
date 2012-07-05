//
//  StatsWebViewController.m
//
//  Created by Eric Johnson on 5/31/12.
//

#import "StatsWebViewController.h"
#import "AFHTTPClient.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "WPcomLoginViewController.h"

#import "HelpViewController.h"

@interface StatsWebViewController () <WPcomLoginViewControllerDelegate> {
    BOOL loadStatsWhenViewAppears;
    BOOL promptCredentialsWhenViewAppears;
}
@property (nonatomic, strong) NSString *wporgBlogJetpackUsernameKey;
@end

@implementation StatsWebViewController

#define kAlertTagAPIKey 1
#define kAlertTagCredentials 2

@synthesize blog;
@synthesize currentNode;
@synthesize parsedBlog;
@synthesize wporgBlogJetpackUsernameKey;

- (void)dealloc {
    [blog release];
    [currentNode release];
    [parsedBlog release];
    [wporgBlogJetpackUsernameKey release];
    
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Stats";
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (promptCredentialsWhenViewAppears) {
        promptCredentialsWhenViewAppears = NO;
        [self promptForCredentials];
    } else if (loadStatsWhenViewAppears) {
        loadStatsWhenViewAppears = NO;
        [self loadStats];
    }
}


#pragma mark -
#pragma mark Instance Methods

- (void)setBlog:(Blog *)aBlog {
    if ([blog isEqual:aBlog]) {
        return;
    }
    
    if (blog) {
        [blog release]; blog = nil;
    }
    blog = [aBlog retain];
    
    if (blog) {
        if (![blog isWPcom]) {
            self.wporgBlogJetpackUsernameKey = [NSString stringWithFormat:@"jetpackblog-%@",[blog hostURL]];
        }
        [self initStats];
    } else {
        [webView loadHTMLString:@"<html><head></head><body></body></html>" baseURL:nil];
    }
}


- (void)initStats {
	if ([blog apiKey] == nil || [[blog blogID] isEqualToNumber:[NSNumber numberWithInt:1]]) {
		//first run or api key was deleted
		[self getUserAPIKey];
	} else if(![blog isWPcom] && [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackUsernameKey] == nil) {
        // self-hosted blog and no associated .com login.
        [self promptForCredentials];
    } else {
        [self loadStats];
	}
}


- (void)getUserAPIKey {
    NSString *username = @"";
    NSString *password = @"";
    NSError *error;
    if ([blog isWPcom]) {
        //use set username/pw for wpcom blogs
        username = [blog username];
        password = [SFHFKeychainUtils getPasswordForUsername:[blog username] andServiceName:[blog hostURL] error:&error];
    } else {
        //use wpcom preference for self-hosted
        username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
        
        // Safety-net, but probably not needed since we also check in initStats.
        if (!username) {
            [self promptForCredentials];
            return;
        }
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://public-api.wordpress.com/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    
    [httpClient setAuthorizationHeaderWithUsername:username password:password];
    
    NSMutableURLRequest *mRequest = [httpClient requestWithMethod:@"GET" path:@"get-user-blogs/1.0" parameters:nil];
    
    
    AFXMLRequestOperation *currentRequest = [[[AFXMLRequestOperation alloc] initWithRequest:mRequest] autorelease];
    
    [currentRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSXMLParser *parser = (NSXMLParser *)responseObject;
        parser.delegate = self;
        [parser parse];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPLog(@"Error calling get-user-blogs : %@", [error description]);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Service Unavailable", @"")
                                                            message:NSLocalizedString(@"We were unable to look up information about your blog's stats. The service may be temporarily unavailable.", @"")
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                  otherButtonTitles:NSLocalizedString(@"Retry", @""), nil];
        [alertView setTag:kAlertTagAPIKey];
        [alertView show];
        [alertView release];

    }];
    
    [currentRequest start];
    [httpClient release];
}


- (void)loadStats {
    if (!self.isViewLoaded || !self.view.window) {
        loadStatsWhenViewAppears = YES;
        return;
    }

    
    NSString *username = @"";
    NSString *password = @"";
    NSError *error;    
    if ([blog isWPcom]) {
        //use set username/pw for wpcom blogs
        username = [blog username];
        password = [SFHFKeychainUtils getPasswordForUsername:[blog username] andServiceName:[blog hostURL] error:&error];
        
    } else {
        /*
         The value of wpcom_username_preference can get mismatched if the user gets happy about adding/removing blogs and signing
         out and back in to load blogs from different wpcom accounts so we don't want to rely on it.
         */
        username = [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackUsernameKey];
        password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
    }
    
    NSString *pathStr = [NSString stringWithFormat:@"http://wordpress.com/my-stats/no-chrome/?blog=%@&unit=1", [blog blogID]];
    NSMutableURLRequest *mRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    NSString *requestBody = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                             [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             [pathStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [mRequest setURL:[NSURL URLWithString:@"https://wordpress.com/wp-login.php"]];
    [mRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    [mRequest setValue:[NSString stringWithFormat:@"%d", [requestBody length]] forHTTPHeaderField:@"Content-Length"];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    NSString *userAgent = [NSString stringWithFormat:@"%@",[webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"]];
    [mRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [mRequest setHTTPMethod:@"POST"];
    
    [webView loadRequest:mRequest];
}


- (void)promptForCredentials {
    if (!self.view.window) {
        promptCredentialsWhenViewAppears = YES;
        return;
    }
    
    WPcomLoginViewController *controller = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.delegate = self;
    controller.isCancellable = YES;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    if(IS_IPAD == YES) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    [self.panelNavigationController presentModalViewController:navController animated:YES];

    [navController release];
    [controller release];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WordPress.com Stats", @"")
                                                        message:NSLocalizedString(@"To load stats for your blog you will need to have Jetpack or the WordPress.com Stats plugin installed on your blog.", @"") 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Learn More", @"")
                                              otherButtonTitles:NSLocalizedString(@"I'm Ready!", @""), nil];
    alertView.tag = kAlertTagCredentials;
    [alertView show];
    [alertView release];
}


#pragma mark -
#pragma mark XMLParser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	self.currentNode = [NSMutableString string];

    if([elementName isEqualToString:@"blog"]) {
        self.parsedBlog = [NSMutableDictionary dictionary];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (self.currentNode) {
        [self.currentNode appendString:string];
    }	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

    if ([elementName isEqualToString:@"apikey"]) {
        [blog setValue:currentNode forKey:@"apiKey"];
        [blog dataSave];
        
    } else if([elementName isEqualToString:@"blog"]) {
        NSString *url = [parsedBlog objectForKey:@"url"];
        NSRange range = [url rangeOfString:[blog url]];
        if (range.length > 0) {
            NSNumber *blogID = [[parsedBlog objectForKey:@"id"] numericValue];
            if ([blogID isEqualToNumber:[self.blog blogID]]) {
                // do nothing.
            } else {
                blog.blogID = blogID;
                [blog dataSave];
            }
            // All done here.
            [parser abortParsing];
            
            /*
             We've successfully found the wpcom account used for the wporg account's jetpack plugin.
             To avoid a mismatched credentials case, associate the current defaults value for wpcom_username_preference
             with a new key for this jetpack account.
             */
            NSString *jetpackUsernameKey = [NSString stringWithFormat:@"jetpackblog-%@",[blog hostURL]];
            NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
            [[NSUserDefaults standardUserDefaults] setValue:username forKey:jetpackUsernameKey];
            [NSUserDefaults resetStandardUserDefaults];
            
            self.currentNode = nil;
            self.parsedBlog = nil;
            
            // Proceed with the credentials we have.
            [self loadStats];
            
            return;
        }
        
        self.parsedBlog = nil;

    } else if([elementName isEqualToString:@"id"]) {
        [parsedBlog setValue:currentNode forKey:@"id"];
    
    } else if([elementName isEqualToString:@"url"]) {
        [parsedBlog setValue:currentNode forKey:@"url"];
        
    } else if([elementName isEqualToString:@"userinfo"]) {
        [parser abortParsing];

        // We parsed the whole list but did not find a matching blog.
        // This should mean that the user has a self-hosted blog and we searched the api without
        // the correct credentials, or they have not set up Jetpack.
        [self promptForCredentials];
    }
    
	self.currentNode = nil;
}


#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger tag = alertView.tag;
    switch (tag) {
        case kAlertTagAPIKey :
            if (buttonIndex == 0) return; // Cancel

            [self getUserAPIKey]; // Retry

            break;

        case kAlertTagCredentials : 
            if (buttonIndex == 0) {
                // Learn More
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", kJetPackURL]]];
            }
            break;

        default:
            break;
    }
}


#pragma mark -
#pragma mark WPcomLoginViewController Delegate Methods

- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithUsername:(NSString *)username {
    [self dismissModalViewControllerAnimated:YES];

    // In theory we should have good wp.com credentials for .org blog's jetpack linkage.
    [self getUserAPIKey];
}


- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self dismissModalViewControllerAnimated:YES];
    [self.panelNavigationController popViewControllerAnimated:YES];
}


@end
