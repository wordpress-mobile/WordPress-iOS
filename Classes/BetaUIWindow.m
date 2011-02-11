    //
//  BetaUIWindow.m
//  WordPress
//
//  Created by Dan Roundhill on 2/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "BetaUIWindow.h"
#import "WordPressAppDelegate.h"

@implementation BetaUIWindow

@synthesize betaFeedbackViewController;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Place the window on the correct level and position
        self.windowLevel = UIWindowLevelStatusBar+1.0f;
        self.frame = [[UIApplication sharedApplication] statusBarFrame];
		
		UIButton *betaButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
		betaButton.backgroundColor = [UIColor orangeColor];
		betaButton.titleLabel.font = [UIFont systemFontOfSize:12];
		[betaButton setTitleShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.35] forState:UIControlStateNormal];
		[betaButton setTitleShadowOffset:CGSizeMake(0, -1.0)];
		[betaButton setTitle:@"Version 2.7 beta - Tap to leave feedback" forState:UIControlStateNormal];
		[betaButton addTarget:self action:@selector(showBetaFeedbackForm:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:betaButton];
    }
	return self;
}

-(void)showBetaFeedbackForm:(id)sender {
		betaFeedbackViewController = [[BetaFeedbackViewController alloc] init];
		WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate.navigationController presentModalViewController:betaFeedbackViewController animated:YES];
		[betaFeedbackViewController release];
}

@end
