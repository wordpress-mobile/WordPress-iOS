//
//  DTStripedLayer.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 01.03.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

/**
 Replacement for `CATiledLayer` when all you need is to have a large scroll view, but don't require zooming.
 
 DTStripedLayer creates tiles on demand, always as wide as its bounds. The height of these tiles is determined by stripeHeight.
 
 @warning This is a work in progress.
 */
@interface DTStripedLayer : CALayer

/**
 The height of the individual stripes/tiles.
 */
@property (nonatomic, assign) CGFloat stripeHeight;

@end
