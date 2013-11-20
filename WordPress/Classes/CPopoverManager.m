//
//  CPopoverManager.m
//  WordPress
//
//  Created by Jonathan Wight on 03/29/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CPopoverManager.h"

static CPopoverManager *gInstance = nil;

@implementation CPopoverManager

+ (id)instance
{
    @synchronized(self)
	{
        if (gInstance == nil) {
            gInstance = [[self alloc] init];
		}
	}
    return(gInstance);
}

- (UIPopoverController *)currentPopoverController
{
    return(currentPopoverController);
}

- (void)setCurrentPopoverController:(UIPopoverController *)inCurrentPopoverController
{
    @synchronized(@"currentPopoverController")
	{
        if (currentPopoverController != inCurrentPopoverController) {
            if (currentPopoverController)
			{
                [currentPopoverController dismissPopoverAnimated:YES];
                currentPopoverController = nil;
			}
            if (inCurrentPopoverController) {
                currentPopoverController = inCurrentPopoverController;
			}
		}
	}
}


@end
