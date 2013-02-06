//
//  WPError.m
//  WordPress
//
//  Created by Jorge Bernal on 4/17/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPError.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "WPcomLoginViewController.h"

NSString * const WPErrorResponseKey = @"wp_error_response";

@implementation WPError

+ (NSError *)errorWithResponse:(NSHTTPURLResponse *)response error:(NSError *)error {
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    [userInfo setValue:response forKey:WPErrorResponseKey];
    return [NSError errorWithDomain:error.domain code:error.code userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

+ (void)showAlertWithError:(NSError *)error title:(NSString *)title {
    NSString *message = nil;
    NSString *customTitle = nil;
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)[error.userInfo objectForKey:WPErrorResponseKey];
    
    if ([error.domain isEqual:AFNetworkingErrorDomain]) {
        switch (error.code) {
            case NSURLErrorBadServerResponse:
                if (response) {
                    switch (response.statusCode) {
                        case 400:
                        case 405:
                        case 406:
                        case 411:
                        case 412:
                        case 413:
                        case 414:
                        case 415:
                        case 416:
                        case 417:
                            customTitle = NSLocalizedString(@"Incompatible site", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error being returned from the site.");
                            message = [NSString stringWithFormat:NSLocalizedString(@"Your WordPress site returned a error %d.\nThat probably means you have some special configuration that is not compatible with this app.\nPlease let us know in the forums about it.", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error being returned from the site."), response.statusCode];
                            break;
                        case 403:
                            customTitle = NSLocalizedString(@"Forbidden Access", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site.");
                            message = NSLocalizedString(@"Received 'Forbidden Access'.\nIt seems there is a problem with your WordPress site", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site.");
                            break;
                        case 500:
                        case 501:
                            customTitle = NSLocalizedString(@"Internal Server Error", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install.");
                            message = NSLocalizedString(@"Received 'Internal Server Error'.\nIt seems there is a problem with your WordPress site", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install.");
                            break;
                        case 502:
                        case 503:
                        case 504:
                            customTitle = NSLocalizedString(@"Temporary Server Error", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install, but may be a temporary issue.");
                            message = NSLocalizedString(@"It seems your WordPress site is not accessible at this time, please try again later", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install, but may be a temporary issue.");
                            break;
                        default:
                            break;
                    }
                }
                break;
                
            default:
                break;
        }
    } else if ([error.domain isEqualToString:WordPressComApiErrorDomain]) {
        WPFLog(@"wp.com API error: %@: %@", [error.userInfo objectForKey:WordPressComApiErrorCodeKey], [error localizedDescription]);
        if (error.code == WordPressComApiErrorInvalidToken || error.code == WordPressComApiErrorAuthorizationRequired) {
            if ([WordPressComApi sharedApi].password == nil) {
                [WPcomLoginViewController presentLoginScreenWithSuccess:nil cancel:nil];
            }
            [[WordPressComApi sharedApi] refreshTokenWithSuccess:nil failure:^(NSError *error) {
                [WPcomLoginViewController presentLoginScreenWithSuccess:nil cancel:nil];
            }];
            return;
        }
    }
    
    if (message == nil) {
        message = [error localizedDescription];
    }
    
    if (title == nil) {
        if (customTitle == nil) {
            title = NSLocalizedString(@"Error", @"Generic error alert title");
        } else {
            title = customTitle;
        }
    }
    
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] showAlertWithTitle:title message:message];
}

+ (void)showAlertWithError:(NSError *)error {
    [self showAlertWithError:error title:nil];
}

@end
