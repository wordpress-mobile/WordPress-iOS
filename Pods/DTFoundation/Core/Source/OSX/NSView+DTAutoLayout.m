//
//  NSView+DTAutoLayout.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 26.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSView+DTAutoLayout.h"

@implementation NSView (DTAutoLayout)

- (void)addLayoutConstraintWithWidthGreaterOrEqualThan:(CGFloat)width
{
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:width];
    constraint.priority = NSLayoutPriorityDragThatCanResizeWindow;
	[self addConstraint:constraint];
}

- (void)addLayoutConstraintsForSubview:(NSView *)subview  edgeInsets:(NSEdgeInsets)edgeInsets
{
	NSParameterAssert(subview);
	//NSAssert(subview.superview == self, @"Can only pin a direct subview of the receiver");
	
	// subview cannot have autoresizing mask, that would interfere with these
	subview.translatesAutoresizingMaskIntoConstraints = NO;
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	if (edgeInsets.left >= 0)
	{
		// subview's left is x points from superview's left
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:edgeInsets.left];
		[tmpArray addObject:constraint];
	}
	else
	{
		// subview's left is x points from superview's right
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:edgeInsets.left];
		[tmpArray addObject:constraint];
	}

	if (edgeInsets.right >= 0)
	{
		// subview's right is x points from superview's right
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-edgeInsets.right];
		[tmpArray addObject:constraint];
	}
	else
	{
		// subview's right is x points from superview's left
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-edgeInsets.right];
		[tmpArray addObject:constraint];
	}

	if (edgeInsets.top >= 0)
	{
		// subview's top is x points from superview's top
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:edgeInsets.top];
		[tmpArray addObject:constraint];
	}
	else
	{
		// subview's top is x points from superview's bottom
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:edgeInsets.top];
		[tmpArray addObject:constraint];
	}
	
	if (edgeInsets.bottom >= 0)
	{
		// subview's bottom is x points from superview's bottom
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-edgeInsets.bottom];
		[tmpArray addObject:constraint];
	}
	else
	{
		// subview's bottom is x points from superview's top
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:-edgeInsets.bottom];
		[tmpArray addObject:constraint];
	}
	
	[self addConstraints:tmpArray];
}

@end
