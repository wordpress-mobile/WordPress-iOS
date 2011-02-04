//
//  WPPageControl.m
//  WordPress
//
//  Created by Dan Roundhill on 11/2/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "WPPageControl.h"


@interface WPPageControl (Private)
- (void) updateDots;
@end


@implementation WPPageControl

@synthesize imageNormal = mImageNormal;
@synthesize imageCurrent = mImageCurrent;

- (void) dealloc
{
	[mImageNormal release], mImageNormal = nil;
	[mImageCurrent release], mImageCurrent = nil;
	
	[super dealloc];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
	
    mImageNormal = [[UIImage imageNamed:@"page_control_blue.png"] retain];
    mImageCurrent = [[UIImage imageNamed:@"page_control_blue_active.png"] retain];
	
    return self;
}


/** override to update dots */
- (void) setCurrentPage:(NSInteger)currentPage
{
	[super setCurrentPage:currentPage];
	
	// update dot views
	[self updateDots];
}

/** override to update dots */
- (void) updateCurrentPageDisplay
{
	[super updateCurrentPageDisplay];
	
	// update dot views
	[self updateDots];
}

/** Override setImageNormal */
- (void) setImageNormal:(UIImage*)image
{
	[mImageNormal release];
	mImageNormal = [image retain];
	
	// update dot views
	[self updateDots];
}

/** Override setImageCurrent */
- (void) setImageCurrent:(UIImage*)image
{
	[mImageCurrent release];
	mImageCurrent = [image retain];
	
	// update dot views
	[self updateDots];
}

/** Override to fix when dots are directly clicked */
- (void) endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event 
{
	[super endTrackingWithTouch:touch withEvent:event];
	
	[self updateDots];
}

#pragma mark - (Private)

- (void) updateDots
{
	if(mImageCurrent || mImageNormal)
	{
		// Get subviews
		NSArray* dotViews = self.subviews;
		for(int i = 0; i < dotViews.count; ++i)
		{
			UIImageView* dot = [dotViews objectAtIndex:i];
			// Set image
			dot.image = (i == self.currentPage) ? mImageCurrent : mImageNormal;
		}
	}
}

@end