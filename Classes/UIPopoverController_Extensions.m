//
//  UIPopoverController_Extensions.m
//  WordPress
//
//  Created by Jonathan Wight on 03/18/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "UIPopoverController_Extensions.h"

@implementation UIPopoverController (UIPopoverController_Extensions)

static UIPopoverController *gCurrentPopoverController = NULL;

+ (UIPopoverController *)currentPopoverController
{
return(gCurrentPopoverController);
}

+ (void)setCurrentPopoverController:(UIPopoverController *)inCurrentPopoverController
{
@synchronized(@"currentPopoverController")
	{
	if (gCurrentPopoverController != inCurrentPopoverController)
		{
		if (gCurrentPopoverController != NULL)
			{
			[gCurrentPopoverController dismissPopoverAnimated:YES];
			[gCurrentPopoverController release];
			gCurrentPopoverController = NULL;	
			}
		if (inCurrentPopoverController)
			{
			gCurrentPopoverController = [inCurrentPopoverController retain];
			}
		}
	}
}

@end
