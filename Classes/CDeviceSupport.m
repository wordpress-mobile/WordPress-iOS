//
//  CDeviceSupport.m
//  WordPress
//
//  Created by Jonathan Wight on 03/29/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CDeviceSupport.h"

BOOL DeviceIsPad(void)
{

if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)])
	{
	return([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);	
	}

return(NO);
}