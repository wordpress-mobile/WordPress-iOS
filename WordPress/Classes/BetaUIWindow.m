    //
//  BetaUIWindow.m
//  WordPress
//
//  Created by Dan Roundhill on 2/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "BetaUIWindow.h"
#import "WordPressAppDelegate.h"

#define kStatusBarHeight 20
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@implementation BetaUIWindow

@synthesize betaFeedbackViewController;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Place the window on the correct level and position
        self.windowLevel = UIWindowLevelStatusBar+1.0f;
        self.frame = [[UIApplication sharedApplication] statusBarFrame];
		UIButton *betaButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 20)];
		[betaButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		betaButton.backgroundColor = [UIColor orangeColor];
		betaButton.titleLabel.font = [UIFont systemFontOfSize:12];
		betaButton.titleLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.35];
		betaButton.titleLabel.shadowOffset = CGSizeMake(0, -1.0);
		[betaButton setTitle:@"Version 2.7 beta - tap here to leave feedback!" forState:UIControlStateNormal];
		[betaButton addTarget:self action:@selector(showBetaFeedbackForm:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:betaButton];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didChangeStatusBarFrame:)
													 name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
		
    }
	return self;
}

-(void)showBetaFeedbackForm:(id)sender {
	betaFeedbackViewController = [[BetaFeedbackViewController alloc] init];
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if (IS_IPAD) {
		betaFeedbackViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		betaFeedbackViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [appDelegate.panelNavigationController presentModalViewController:betaFeedbackViewController animated:YES];
//		[appDelegate.splitViewController presentModalViewController:betaFeedbackViewController animated:YES];
	}
	else
		[appDelegate.navigationController presentModalViewController:betaFeedbackViewController animated:YES];
	
}

- (void)didChangeStatusBarFrame:(NSNotification *)notification {
	NSValue * statusBarFrameValue = [notification.userInfo valueForKey:UIApplicationStatusBarFrameUserInfoKey];
	
	// have to use performSelector to prohibit animation of rotation
	[self performSelector:@selector(rotateToStatusBarFrame:) withObject:statusBarFrameValue afterDelay:0];
}

- (void)rotateToStatusBarFrame:(NSValue *)statusBarFrameValue {
	// current interface orientation
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	
	CGFloat pi = (CGFloat)M_PI;
	if (orientation == UIDeviceOrientationPortrait) {
		self.transform = CGAffineTransformIdentity;
		self.frame = CGRectMake(0,0,kScreenWidth,kStatusBarHeight);
	}else if (orientation == UIDeviceOrientationLandscapeLeft) {
		self.transform = CGAffineTransformMakeRotation(pi * (90) / 180.0f);
		self.frame = CGRectMake(kScreenWidth - kStatusBarHeight,0, kStatusBarHeight, kScreenHeight);
	} else if (orientation == UIDeviceOrientationLandscapeRight) {
		self.transform = CGAffineTransformMakeRotation(pi * (-90) / 180.0f);
		self.frame = CGRectMake(0,0, kStatusBarHeight, kScreenHeight);
	} else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
		self.transform = CGAffineTransformMakeRotation(pi);
		self.frame = CGRectMake(0,kScreenHeight - kStatusBarHeight,kScreenWidth,kStatusBarHeight);
	}
}

@end
