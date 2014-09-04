//
//  ViewController.m
//  ProgressHUD
//
//  Created by Stefan Gugarel on 07/05/14.
//  Copyright (c) 2014 Drobnik KG. All rights reserved.
//

#import "ViewController.h"

#import "DTProgressHUD.h"
#import "DTActionSheet.h"
#import "DTAlertView.h"

@interface ViewController ()

- (IBAction)showStatusAndImagePressed:(id)sender;

- (IBAction)showInfiniteProgressActivityIndicatorPressed:(id)sender;

- (IBAction)showInfiniteProgressPressed:(id)sender;

- (IBAction)showPieProgressWithSnapAnimation:(id)sender;

- (IBAction)showInfiniteProgressWithGravityTilt:(id)sender;

- (IBAction)hidePressed:(id)sender;

@end

@implementation ViewController
{
	DTProgressHUD *_progressHUD;
	
	float progress;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self _createProgressHUD];
}

#pragma mark - Actions

- (IBAction)showStatusAndImagePressed:(id)sender
{
	_progressHUD.hideAnimationType = HUDProgressAnimationTypeFade;
	_progressHUD.showAnimationType = HUDProgressAnimationTypeFade;
	[_progressHUD showWithText:@"Added to favorites - This is a test with very very long TEXT TEXT TEXT" image:[UIImage imageNamed:@"Star"]];
	
	[self performSelector:@selector(_updateStarImage) withObject:self afterDelay:0.8];
	
	[_progressHUD hideAfterDelay:1.5f];
}

- (IBAction)showInfiniteProgressActivityIndicatorPressed:(id)sender
{
	_progressHUD.hideAnimationType = HUDProgressAnimationTypeGravity;
	_progressHUD.showAnimationType = HUDProgressAnimationTypeGravity;
	[_progressHUD showWithText:@"Infinite Progress with ActivityIndicator - This is a test with" progressType:HUDProgressTypeInfinite];
}

- (IBAction)showInfiniteProgressPressed:(id)sender
{
	_progressHUD.hideAnimationType = HUDProgressAnimationTypeGravityRoll;
	_progressHUD.showAnimationType = HUDProgressAnimationTypeGravityRoll;
	[_progressHUD showWithText:@"Pie Progress" progressType:HUDProgressTypePie];
	
	progress = 0;
	
	[self performSelector:@selector(_increaseProgress) withObject:nil afterDelay:0.3];
}

- (IBAction)showPieProgressWithSnapAnimation:(id)sender
{
	_progressHUD.hideAnimationType = HUDProgressAnimationTypeSnap;
	_progressHUD.showAnimationType = HUDProgressAnimationTypeSnap;
	[_progressHUD showWithText:@"Pie Progress" progressType:HUDProgressTypePie];
	
	progress = 0;
	
	[self performSelector:@selector(_increaseProgress) withObject:nil afterDelay:0.3];
}

- (IBAction)showInfiniteProgressWithGravityTilt:(id)sender
{
	_progressHUD.hideAnimationType = HUDProgressAnimationTypeGravityTilt;
	_progressHUD.showAnimationType = HUDProgressAnimationTypeGravityTilt;
	[_progressHUD showWithText:@"Infinite Progress with Gravity Tilt" progressType:HUDProgressTypeInfinite];
}

- (IBAction)hidePressed:(id)sender
{
	[_progressHUD hide];
}

- (IBAction)showDTActionSheet:(id)sender
{
    DTActionSheet *actionSheet = [[DTActionSheet alloc] initWithTitle:@"This is a block-based DTActionSheet"
                                                             delegate:nil
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:@"Destructive"
                                                    otherButtonTitles:@"a", @"b", nil];

    [actionSheet addButtonWithTitle:@"Say hi" block:^
     {
         NSLog(@"Hi!");
     }];
    [actionSheet addCancelButtonWithTitle:@"Cancel" block:^
     {
         NSLog(@"Cancelled :-(");
     }];
    [actionSheet showInView:self.view];
}

- (IBAction)showDTAlertViewidsender:(id)sender {
    DTAlertView *alertView = [[DTAlertView alloc] initWithTitle:@"DTAlertView"
                                                        message:@"This is a block-based DTAlertView"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"a", @"b", nil];
    
    [alertView addButtonWithTitle:@"Say hi" block:^
     {
         NSLog(@"Hi!");
     }];
    [alertView addCancelButtonWithTitle:@"Cancel" block:^
     {
         NSLog(@"Cancelled :-(");
     }];
    [alertView show];
}

- (void)_createProgressHUD
{
	_progressHUD = [[DTProgressHUD alloc] init];
	[self.view addSubview:_progressHUD];
}

- (void)_increaseProgress
{
	if (progress > 1)
	{
		return;
	}
	
	progress += 0.05;
	
	[_progressHUD setProgress:progress];
	[_progressHUD setText:[NSString stringWithFormat:@"Progress in percent: %f", progress]];
	
	[self performSelector:@selector(_increaseProgress) withObject:nil afterDelay:0.05];
}

- (void)_updateStarImage
{
	[_progressHUD setImage:[UIImage imageNamed:@"RotatedStar"]];
	[_progressHUD setText:@"Text changed!!!"];
}

@end
