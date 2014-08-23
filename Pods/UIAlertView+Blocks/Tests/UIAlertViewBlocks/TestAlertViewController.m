//
//  TestAlertViewController.m
//  UIAlertViewBlocks
//
//  Created by Ryan Maxwell on 7/09/13.
//  Copyright (c) 2013 Ryan Maxwell. All rights reserved.
//

#import "TestAlertViewController.h"
#import "UIAlertView+Blocks.h"

@interface TestAlertViewController ()

- (IBAction)showAlert:(id)sender;

@end

@implementation TestAlertViewController

- (IBAction)showAlert:(id)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Sign in to my awesome service"
                                                 message:@"I promise I won’t steal your password"
                                                delegate:self
                                       cancelButtonTitle:@"Cancel"
                                       otherButtonTitles:@"OK", nil];
    
    av.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    av.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSLog(@"Username: %@", [[alertView textFieldAtIndex:0] text]);
            NSLog(@"Password: %@", [[alertView textFieldAtIndex:1] text]);
        } else if (buttonIndex == alertView.cancelButtonIndex) {
            NSLog(@"Cancelled.");
        }
    };
    
    av.shouldEnableFirstOtherButtonBlock = ^BOOL(UIAlertView *alertView){
        return ([[[alertView textFieldAtIndex:1] text] length] > 0);
    };
    
    [av show];
}

@end
