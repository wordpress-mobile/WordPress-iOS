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

- (void)drawRect:(CGRect)inRect
{
}

@end
