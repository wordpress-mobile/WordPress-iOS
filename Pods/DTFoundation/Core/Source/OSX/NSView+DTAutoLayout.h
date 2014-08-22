//
//  NSView+DTAutoLayout.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 26.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Useful shortcuts for auto layout on Mac.
 */

@interface NSView (DTAutoLayout)

/**
 Creates and adds a layout contraint to the receiver that enforces a minimum width.
 @param width The width to enforce
 */
- (void)addLayoutConstraintWithWidthGreaterOrEqualThan:(CGFloat)width;

/**
 Pins the edges of a subview to edges of the receiver. 
 
 To pin a view at the top of its superview:
 
    // 22 px high at top full width
    [self addLayoutConstraintsForSubview:barView edgeInsets:NSEdgeInsetsMake(0, 0, -22, 0)];
 
 To have a view underneath it
 
    // rest of view spaced 22 px from top
    [self addLayoutConstraintsForSubview:_tabView edgeInsets:NSEdgeInsetsMake(22, 0, 0, 0)];
 
 @param subview The subview to tie to the receiver
 @param edgeInsets The insets from the receiver's frame. Negative values are from the opposite edge.
 */
- (void)addLayoutConstraintsForSubview:(NSView *)subview edgeInsets:(NSEdgeInsets)edgeInsets;

@end
