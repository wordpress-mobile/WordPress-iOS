//
//  CreateWPComBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateWPComBlogViewController.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "SFHFKeychainUtils.h"
#import "Blog.h"

@interface CreateWPComBlogViewController ()

@property (nonatomic, strong) IBOutlet UITextField *blogUrl;
@property (nonatomic, strong) IBOutlet UITextField *blogTitle;

@end

@implementation CreateWPComBlogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - IBAction Methods

- (IBAction)clickedCreateBlog:(id)sender
{
    if (![self areFieldsValid]) {
        [self displayErrorMessages];
        return;
    }
    
    [[WordPressComApi sharedApi] createWPComBlogWithUrl:self.blogUrl.text andBlogTitle:self.blogTitle.text success:^(id responseObject){
        if (self.delegate != nil) {
            NSDictionary *blogDetails = [responseObject dictionaryForKey:@"blog_details"];
            [self createBlog:blogDetails];
            [self.delegate createdBlogWithDetails:blogDetails];
        }
    } failure:^(NSError *error){
        [self handleCreationError:error];
    }];
}


#pragma mark - Private Methods

- (BOOL)areFieldsValid
{
    return self.blogUrl.text.length != 0 && self.blogTitle.text.length != 0;
}

- (void)displayErrorMessages
{
    NSMutableArray *errorMessages = [[NSMutableArray alloc] init];
    if (self.blogUrl.text.length == 0) {
        [errorMessages addObject:@"Must include a valid url"];
    }
    
    if (self.blogTitle.text.length == 0) {
        [errorMessages addObject:@"Must include a valid Blog Title"];
    }
    
    NSString *errorMessage = [errorMessages componentsJoinedByString:@"\n"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)handleCreationError:(NSError *)error
{
    NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
    NSString *errorMessage;
    if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogUrl]) {
        errorMessage = @"Invalid Blog Url";
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogTitle]) {
        errorMessage = @"Invalid Blog Title";
    } else {
        errorMessage = @"Unknown error";
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alertView show];
}

// TODO : Figure out where to put this so we aren't duplicating code with AddUsersBlogViewController
- (void)createBlog:(NSDictionary *)blogInfo {
    NSError *error;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
                                          andServiceName:@"WordPress.com"
                                                   error:&error];

    NSMutableDictionary *newBlog = [NSMutableDictionary dictionary];
    [newBlog setObject:username forKey:@"username"];
    [newBlog setObject:password forKey:@"password"];
    [newBlog setObject:[blogInfo objectForKey:@"blogname"] forKey:@"blogName"];
    [newBlog setObject:[blogInfo objectForKey:@"blogid"] forKey:@"blogid"];
    [newBlog setObject:[blogInfo objectForKey:@"url"] forKey:@"url"];
    [newBlog setObject:[blogInfo objectForKey:@"xmlrpc"] forKey:@"xmlrpc"];
    
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    Blog *blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
//	blog.geolocationEnabled = self.geolocationEnabled;
	[blog dataSave];
    [blog syncBlogWithSuccess:^{
        if( ! [blog isWPcom] )
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
    }
                      failure:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
    
    [appDelegate.managedObjectContext save:&error];
    if (error != nil) {
        NSLog(@"Error adding blogs: %@", [error localizedDescription]);
    }
    [[WordPressComApi sharedApi] syncPushNotificationInfo];
}

@end
