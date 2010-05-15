//
//  CInvisibleTabBar.m
//  WordPress
//
//  Created by Jonathan Wight on 03/02/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CInvisibleToolbar.h"

@implementation CInvisibleToolbar

- (id)initWithFrame:(CGRect)frame
{
if ((self = [super initWithFrame:frame]) != NULL)
	{
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	}
return(self);
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
if ((self = [super initWithCoder:aDecoder]) != NULL)
	{
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	}
return(self);
}

- (void)drawRect:(CGRect)inRect
{
}

- (CGSize)sizeThatFits:(CGSize)size;
{
	CGFloat width = 0.0;
	for (UIBarButtonItem *item in self.items) {
		width += item.width;
	}
	return CGSizeMake(width, self.frame.size.height);
}

@end
