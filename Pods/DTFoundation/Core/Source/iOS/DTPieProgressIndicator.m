//
//  DTPieProgressIndicator.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 16.05.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTPieProgressIndicator.h"

#define PIE_SIZE 34.0f

@implementation DTPieProgressIndicator
{
	CGFloat _progressPercent;
	UIColor *_color;
}

+ (DTPieProgressIndicator *)pieProgressIndicator
{
	return [[DTPieProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, PIE_SIZE, PIE_SIZE)];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	// Drawing code
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (_color)
	{
		[_color set];
	}
	else 
	{
		[[UIColor whiteColor] set];
	}
	
	CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 1, [UIColor blackColor].CGColor);
	CGContextBeginTransparencyLayer(ctx, NULL);
	
	CGFloat smallerDimension = MIN(self.bounds.size.width-6.0f, self.bounds.size.height-6.0f);
	CGRect drawRect =  CGRectMake(roundf(CGRectGetMidX(self.bounds)-smallerDimension/2.0f), roundf(CGRectGetMidY(self.bounds)-smallerDimension/2.0f), smallerDimension, smallerDimension);
	
	CGContextSetLineWidth(ctx, 3.0f);
	CGContextStrokeEllipseInRect(ctx, drawRect);
	
	// enough percent to draw
	if (_progressPercent > 0.1f)
	{
		CGPoint center = CGPointMake(CGRectGetMidX(drawRect), CGRectGetMidY(drawRect));
		CGFloat radius = center.x - drawRect.origin.x;
		CGFloat angle = _progressPercent * 2.0f * M_PI;
		
		CGContextMoveToPoint(ctx, center.x, center.y);
		//CGContextAddLineToPoint(ctx, center.x, drawRect.origin.y);
		CGContextAddArc(ctx, center.x, center.y, radius, -M_PI_2, angle-M_PI_2, 0);
		CGContextAddLineToPoint(ctx, center.x, center.y);
		
		CGContextFillPath(ctx);
	}
	
	CGContextEndTransparencyLayer(ctx);
}


#pragma mark Properties

- (void)setProgressPercent:(CGFloat)progressPercent
{
	if (_progressPercent != progressPercent)
	{
		_progressPercent = progressPercent;
		
		[self setNeedsDisplay];
	}
}

- (void)setColor:(UIColor *)color
{
	if (_color != color)
	{
		_color = color;
		
		[self setNeedsDisplay];
	}
}

@synthesize progressPercent = _progressPercent;
@synthesize color = _color;

@end
