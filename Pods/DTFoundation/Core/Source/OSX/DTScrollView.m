//
//  DTScrollView.m
//  iCatalogEditor
//
//  Created by Oliver Drobnik on 10/23/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTScrollView.h"

@implementation DTScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
	BOOL shouldForwardScroll = NO;
	
	if (self.usesPredominantAxisScrolling)
	{
		if (fabs(theEvent.deltaX)>fabs(theEvent.deltaY))
		{
			// horizontal scroll
			if (!self.hasHorizontalScroller)
			{
				shouldForwardScroll	= YES;
			}
		}
		else
		{
			// vertical scroll
			if (!self.hasVerticalScroller)
			{
				shouldForwardScroll	= YES;
			}
		}
	}
	
	if (shouldForwardScroll)
	{
		
		[[self nextResponder] scrollWheel:theEvent];
	}
	else
	{
		[super scrollWheel:theEvent];
	}
}

@end
