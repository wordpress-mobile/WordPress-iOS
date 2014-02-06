//
//  DTStripedLayer.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 01.03.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTStripedLayer.h"
#import "DTStripedLayerTile.h"
#import "UIColor+DTDebug.h"

@interface DTStripedLayer () // private

@property (nonatomic, readonly) NSCache *tileCache;

@end

@implementation DTStripedLayer
{
    BOOL _isObservingSuperlayerBounds;
    NSCache *_tileCache;
    NSMutableSet *_tilesWithDrawingInQueue;
    
    CGFloat _stripeHeight;
    CGSize _contentSize;
    
    NSMutableSet *_visibleTileKeys;
    NSOperationQueue *_tileCreationQueue;
    
    id _tileDelegate;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _stripeHeight = 512.0f;
        _visibleTileKeys = [[NSMutableSet alloc] init];
        _tileCreationQueue = [[NSOperationQueue alloc] init];
        _tilesWithDrawingInQueue = [[NSMutableSet alloc] init];
        
        self.borderWidth = 3;
        self.borderColor = [UIColor blueColor].CGColor;
    }
    
    return self;
}

- (void)setBounds:(CGRect)bounds
{
    if (!CGRectEqualToRect(self.bounds, bounds))
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        [super setBounds:bounds];
        
        DTLogDebug(@"setbounds: %@ %@", NSStringFromCGRect(bounds), _tileDelegate);
        
        // store for frequent use
        _contentSize = bounds.size;
        
        [self setNeedsLayout];
        [CATransaction commit];
    }
}

- (void)setFrame:(CGRect)frame
{
    if (!CGRectEqualToRect(self.frame, frame))
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        [super setFrame:frame];
        
        DTLogDebug(@"setFrame: %@ %@", NSStringFromCGRect(frame), _tileDelegate);
        
        // store for frequent use
        _contentSize = frame.size;
        
        [self setNeedsLayout];
            [CATransaction commit];
    }
}

- (NSRange)_rangeOfVisibleStripesInBounds:(CGRect)bounds
{
    NSUInteger firstIndex = floorf(MAX(0, CGRectGetMinY(bounds))/_stripeHeight);
    NSUInteger lastIndex = floorf(MIN(_contentSize.height, CGRectGetMaxY(bounds))/_stripeHeight);
    
    return NSMakeRange(firstIndex, lastIndex - firstIndex + 1);
}

- (CGRect)_frameOfStripeAtIndex:(NSUInteger)index
{
    CGRect frame = CGRectMake(0, index*_stripeHeight, _contentSize.width, _stripeHeight);
    
    // need to crop by total bounds, last item not full height
    frame = CGRectIntersection(self.bounds, frame);
    
    return frame;
}


- (void)_finishedDrawingForTile:(DTStripedLayerTile *)tile withResult:(UIImage *)image
{
    @synchronized(self)
    {
        // iOS 5 requires this on main queue, iOS 6 doesn't care
        dispatch_async(dispatch_get_main_queue(), ^{
            tile.contents = (__bridge id)(image.CGImage);
            
            // remove from queue
            [_tilesWithDrawingInQueue removeObject:tile];
        });
    }
}

- (void)_cancelDrawingForTile:(DTStripedLayerTile *)tile
{
    @synchronized(self)
    {
        
        
        
    }
}


- (void)_enqueueDrawingForTile:(DTStripedLayerTile *)tile
{
    @synchronized(self)
    {
        if ([_tilesWithDrawingInQueue containsObject:tile])
        {
            // image is already being created
            return;
        }
    }
    
    [_tileCreationQueue addOperationWithBlock:^{
        UIGraphicsBeginImageContextWithOptions(tile.bounds.size, YES, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        // shift the context such that its clip rect matches the tile bounds
        CGContextTranslateCTM(ctx, tile.bounds.origin.x, -tile.bounds.origin.y);
        
        // draw the tile
        [_tileDelegate drawLayer:tile inContext:ctx];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [self _finishedDrawingForTile:tile withResult:image];
    }];
}

- (void)layoutSublayers
{
    [super layoutSublayers];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CGRect visibleBounds = [self convertRect:self.superlayer.bounds fromLayer:self.superlayer];
    NSRange visibleStripeRange = [self _rangeOfVisibleStripesInBounds:visibleBounds];
    
    _contentSize = self.frame.size;
    
    // remove invisible tiles
    
    NSMutableSet *indexesAlreadyPresent = [NSMutableSet set];
    
    for (DTStripedLayerTile *oneSubLayer in [self.sublayers copy])
    {
        if (![oneSubLayer isKindOfClass:[DTStripedLayerTile class]])
        {
            // not our business
            continue;
        }
        
        if (oneSubLayer.bounds.size.width != _contentSize.width || !NSLocationInRange(oneSubLayer.index, visibleStripeRange))
        {
            [oneSubLayer removeFromSuperlayer];
        }
        else
        {
            // check frame, might have changed, especially last stripes if bounds has changed
            CGRect tileFrame = [self _frameOfStripeAtIndex:oneSubLayer.index];
            
            if (CGRectEqualToRect(tileFrame, oneSubLayer.frame))
            {
            }
            else
            {
                DTLogError(@"layer frame differs! %@ <-> %@", NSStringFromCGRect(oneSubLayer.frame), NSStringFromCGRect(tileFrame));
                
                oneSubLayer.anchorPoint = CGPointZero;
                oneSubLayer.bounds = tileFrame;
                oneSubLayer.position = tileFrame.origin;
                oneSubLayer.frame = tileFrame;
                
                [self _enqueueDrawingForTile:oneSubLayer];
            }
            
            // store in set so that we know that we already have that
            NSNumber *indexNumber = [NSNumber numberWithUnsignedInteger:oneSubLayer.index];
            [indexesAlreadyPresent addObject:indexNumber];
        }
    }
    
    // add the ones that are not already visible
    
    for (NSUInteger index=visibleStripeRange.location; index<NSMaxRange(visibleStripeRange); index++)
    {
        NSNumber *indexNumber = [NSNumber numberWithUnsignedInteger:index];
        
        if ([indexesAlreadyPresent containsObject:indexNumber])
        {
            // already got that
            continue;
        }
        
        NSString *tileKey = [NSString stringWithFormat:@"%f-%ld", _contentSize.width, (unsigned long)index];
        
        DTStripedLayerTile *cachedTile = [self.tileCache objectForKey:tileKey];
        
        CGRect tileFrame = [self _frameOfStripeAtIndex:index];
        
        if (cachedTile)
        {
            [self insertSublayer:cachedTile atIndex:0];
            //            [cachedTile setNeedsDisplay];
            
            if (!cachedTile.contents)
            {
                [self _enqueueDrawingForTile:cachedTile];
            }
            
            DTLogDebug(@"cached %@", cachedTile);
        }
        else
        {
            // need new tile
            DTStripedLayerTile *newTile = [[DTStripedLayerTile alloc] init];
            newTile.contentsScale = self.contentsScale;
            newTile.rasterizationScale = self.rasterizationScale;
            newTile.index = index;
            
            newTile.anchorPoint = CGPointZero;
            newTile.bounds = tileFrame;
            newTile.position = tileFrame.origin;
            newTile.frame = tileFrame;
            
            newTile.needsDisplayOnBoundsChange = YES;
            [self insertSublayer:newTile atIndex:0];
            
            [self _enqueueDrawingForTile:newTile];
            //            newTile.delegate = self;
            //            [newTile setNeedsDisplay];
            
            newTile.borderColor = [UIColor redColor].CGColor;
            newTile.borderWidth = 3;
            
            DTLogDebug(@"new %@", newTile);
            
            // cost in cache is number of pixels
            [self.tileCache setObject:newTile forKey:tileKey cost:tileFrame.size.width * tileFrame.size.height];
        }
    }
    
    if (!_isObservingSuperlayerBounds)
    {
        // observe superlayer bounds
        [self.superlayer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
        
        _isObservingSuperlayerBounds = YES;
    }
    
    [CATransaction commit];
}

- (void)removeFromSuperlayer
{
    if (_isObservingSuperlayerBounds)
    {
        [self.superlayer removeObserver:self forKeyPath:@"bounds" context:NULL];
        _isObservingSuperlayerBounds = NO;
        
        [_tileCache removeAllObjects];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsLayout];
}

- (void)setDelegate:(id)delegate
{
    // [super setDelegate:delegate];
    
    _tileDelegate = delegate;
}

- (void)setContents:(id)contents
{
    // ignore setContents so that the layer itself stays empty
}

- (NSArray *)_visibleTiles
{
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    for (DTStripedLayerTile *oneSubLayer in self.sublayers)
    {
        if (![oneSubLayer isKindOfClass:[DTStripedLayerTile class]])
        {
            // not our business
            continue;
        }
        
        [tmpArray addObject:oneSubLayer];
    }
    
    return tmpArray;
}

- (void)_resetTiles
{
    for (DTStripedLayerTile *oneTile in [self.sublayers copy])
    {
        [oneTile removeFromSuperlayer];
    }
    
    [_tileCache removeAllObjects];
}

- (void)setNeedsDisplay
{
    for (DTStripedLayerTile *oneTile in [self _visibleTiles])
    {
        //oneTile.contents = nil;
        
        [self _enqueueDrawingForTile:oneTile];
        //        [oneTile setNeedsDisplay];
    }
}

- (void)setNeedsDisplayInRect:(CGRect)rect
{
    for (DTStripedLayerTile *oneTile in [self _visibleTiles])
    {
        // only inform tiles that are affected by this rect
        if (CGRectIntersectsRect(rect, oneTile.frame))
        {
            [self _enqueueDrawingForTile:oneTile];
            //          [oneTile setNeedsDisplayInRect:rect];
        }
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    [_tileDelegate drawLayer:layer inContext:ctx];
    
    CGRect clipRect = CGContextGetClipBoundingBox(ctx);
    
    CGContextSetRGBStrokeColor(ctx, 1, 0, 0, 0.5);
    CGContextStrokeRect(ctx, clipRect);
}

#pragma mark - Properties

- (void)setStripeHeight:(CGFloat)stripeHeight
{
    if (_stripeHeight != stripeHeight)
    {
        _stripeHeight = stripeHeight;
        
        [self _resetTiles];
        [self setNeedsLayout];
    }
}

- (NSCache *)tileCache
{
    if (!_tileCache)
    {
        _tileCache = [[NSCache alloc] init];
    }
    
    return _tileCache;
}

@synthesize tileCache = _tileCache;

@end
