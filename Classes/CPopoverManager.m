//
//  CPopoverManager.m
//  WordPress
//
//  Created by Jonathan Wight on 03/29/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CPopoverManager.h"

static CPopoverManager *gInstance = NULL;

@implementation CPopoverManager

+ (id)instance
{
@synchronized(self)
	{
	if (gInstance == NULL)
		{
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
	if (currentPopoverController != inCurrentPopoverController)
		{
		if (currentPopoverController != NULL)
			{
			[currentPopoverController dismissPopoverAnimated:YES];
			currentPopoverController = NULL;	
			}
		if (inCurrentPopoverController)
			{
			currentPopoverController = inCurrentPopoverController;
			}
		}
	}
}


@end
