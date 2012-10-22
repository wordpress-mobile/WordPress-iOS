//
//  BetaUIWindow.h
//  WordPress
//
//  Created by Dan Roundhill on 2/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BetaFeedbackViewController.h"


@interface BetaUIWindow : UIWindow {
	BetaFeedbackViewController *betaFeedbackViewController;
}

@property (nonatomic, strong) BetaFeedbackViewController *betaFeedbackViewController;

@end
