//
//  CreateWPComAccountViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 3/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateWPComAccountViewController.h"
#import "WordPressComApi.h"

@interface CreateWPComAccountViewController ()

@property (nonatomic, strong) IBOutlet UITextField *emailAddress;
@property (nonatomic, strong) IBOutlet UITextField *username;
@property (nonatomic, strong) IBOutlet UITextField *password;
@property (nonatomic, strong) IBOutlet UITextField *blogurl;

@end

@implementation CreateWPComAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - IBAction Methods
- (IBAction)clickedSignUp:(id)sender
{
    if (![self isFormValid]) {
        [self displayErrorMessagesForForm];
        return;
    }
    
    [[WordPressComApi sharedApi] createWPComAccountWithEmail:self.emailAddress.text andUsername:self.username.text andPassword:self.password.text andBlogUrl:self.blogurl.text success:^(id responseObject){
        [[WordPressComApi sharedApi] signInWithUsername:self.username.text password:self.password.text success:^{
            if (self.delegate != nil) {
                [self.delegate createdAndSignedInAccountWithUserName:self.username.text];
            }
        } failure:^(NSError * error){
            WPFLog(@"Error logging in after creating an account with username : %@", self.username.text);
            [self.delegate createdAccountWithUserName:self.username.text];
        }];
    } failure:^(NSError *error){
        [self handleCreationError:error];
    }];
}


#pragma mark - Private Methods

- (BOOL)isFormValid
{
    return [self.username.text length] != 0 && [self.password.text length] != 0 && [self.emailAddress.text length] !=0 && [self.blogurl.text length] != 0;
}

- (void)displayErrorMessagesForForm
{
    NSMutableArray *errorMessages = [[NSMutableArray alloc] init];
    
    if ([self.emailAddress.text length] == 0) {
        [errorMessages addObject:@"Must enter an email address"];
    }
    
    if ([self.username.text length] == 0) {
        [errorMessages addObject:@"Must enter a username"];
    }
    
    if ([self.password.text length] == 0) {
        [errorMessages addObject:@"Must enter a password"];
    }
        
    if ([self.blogurl.text length] == 0) {
        [errorMessages addObject:@"Must enter a blog url"];
    }
    
    if ([errorMessages count] == 0)
        return;
    
    NSString *errorMessage = [errorMessages componentsJoinedByString:@"\n"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)handleCreationError:(NSError *)error
{
    NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
    NSString *errorMessage;
    if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidUser]) {
        errorMessage = @"Invalid username";
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidEmail]) {
        errorMessage = @"Invalid email address";
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidPassword]) {
        errorMessage = @"Invalid password";
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogUrl]) {
        errorMessage = @"Invalid Blog Url";
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogTitle]) {
        errorMessage = @"Invalid Blog Title";
    } else {
        errorMessage = @"Unknown error";
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
