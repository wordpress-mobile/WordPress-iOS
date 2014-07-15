//
//  NSObject+SLVisibility.m
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSObject+SLVisibility.h"
#import "SLLogger.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


const CGFloat kMinVisibleAlphaFloat = 0.01;
const unsigned char kMinVisibleAlphaInt = 3; // 255 * 0.01 = 2.55, but our bitmap buffers use integer color components.

@interface UIView (SLVisibility)

/**
 Renders the input view and that views hierarchy using compositing options that
 cause the target view and all of its subviews to be drawn as black rectangles,
 while every view not in the hierarchy of the target renders with kCGBlendModeDestinationOut.
 The result is a rendering with black or gray pixels everywhere that the target view is visible.
 Pixels will be black where the target view is not occluded at all, and gray where the target view
 is occluded by views that are not fully opaque.

 @param view the view to be rendered
 @param context the drawing context in which to render view
 @param target the view whose hierarchy should be drawn as black rectangles
 @param baseView the view which provides the base coordinate system for the rendering, usually target's window.
 */
- (void)renderViewRecursively:(UIView *)view inContext:(CGContextRef)context withTargetView:(UIView *)target baseView:(UIView *)baseView;

/**
 Returns the number of points from a set of test points for which the receiver is visible in a given window.

 @param testPointsInWindow a C array of points to test for visibility
 @param numPoints the number of elements in testPointsInWindow
 @param window the UIWindow in which to test visibility.  This should usually be
 the receiver's window, but could be a different window, for example if the
 point is to test whether the view is in one window or a different window.

 @return the number of points from testPointsInWindow at which the receiver is visible.
 */
- (NSUInteger)numberOfPointsFromSet:(const CGPoint *)testPointsInWindow count:(const NSUInteger)numPoints thatAreVisibleInWindow:(UIWindow *)window;

/**
 Determines if the section of the object located within the specified rect is visible
 on the screen.

 @param rect The area in which to determine if the receiver is visible. This value should
 be provided in screen coordinates.

 @return YES if the portion of the receiver within the specified rect is visible
 within the accessibility hierarchy, NO otherwise.
 */
- (BOOL)slAccessibilityRectIsVisible:(CGRect)rect;

@end


@implementation NSObject (SLVisibility)

// There are objects in the accessibility hierarchy which are neither UIAccessibilityElements
// nor UIViews, e.g. the elements vended by UIWebBrowserViews. For these objects we cannot
// determine whether or not they are visible directly, instead we determine whether the area
// they occupy is visible within their first UIView accessibility ancestor.
- (BOOL)slAccessibilityIsVisible {
    if (![self respondsToSelector:@selector(accessibilityContainer)]) {
        SLLogAsync(@"Cannot locate %@ in the accessibility hierarchy. Returning -NO from -slAccessibilityIsVisible.", self);
        return NO;
    }

    id container = [self performSelector:@selector(accessibilityContainer)];
    while (container) {
        // we should eventually reach a container that is a view
        // --the accessibility hierarchy begins with the main window if nothing else
        if ([container isKindOfClass:[UIView class]]) break;

        // it's not a requirement that accessibility containers vend UIAccessibilityElements,
        // so it might not be possible to traverse the hierarchy upwards
        if (![container respondsToSelector:@selector(accessibilityContainer)]) {
            SLLogAsync(@"Cannot locate %@ in the accessibility hierarchy. Returning -NO from -slAccessibilityIsVisible.", self);
            return NO;
        }
        container = [container accessibilityContainer];
    }

    NSAssert([container isKindOfClass:[UIView class]],
             @"Every accessibility hierarchy should be rooted in a view.");
    UIView *viewContainer = (UIView *)container;
    return [viewContainer slAccessibilityRectIsVisible:self.accessibilityFrame];
}

@end


@implementation UIAccessibilityElement (SLVisibility)

- (BOOL)slAccessibilityIsVisible {
    CGPoint testPoint = CGPointMake(CGRectGetMidX(self.accessibilityFrame),
                                    CGRectGetMidY(self.accessibilityFrame));

    // we first determine that we are the foremost element within our containment hierarchy
    id parentOrSelf = self;
    id container = self.accessibilityContainer;
    while (container) {
        // UIAutomation ignores accessibilityElementsHidden, so we do too

        NSInteger elementCount = [container accessibilityElementCount];
        NSAssert(((elementCount != NSNotFound) && (elementCount > 0)),
                 @"%@'s accessibility container should implement the UIAccessibilityContainer protocol.", self);
        for (NSInteger idx = 0; idx < elementCount; idx++) {
            id element = [container accessibilityElementAtIndex:idx];
            if (element == parentOrSelf) break;

            // if another element comes before us/our parent in the array
            // (thus is z-ordered before us/our parent)
            // and contains our hitpoint, it covers us
            if (CGRectContainsPoint([element accessibilityFrame], testPoint)) return NO;
        }

        // we should eventually reach a container that is a view
        // --the accessibility hierarchy begins with the main window if nothing else--
        // at which point we test the rest of the hierarchy using hit-testing
        if ([container isKindOfClass:[UIView class]]) break;

        // it's not a requirement that accessibility containers vend UIAccessibilityElements,
        // so it might not be possible to traverse the hierarchy upwards
        if (![container respondsToSelector:@selector(accessibilityContainer)]) {
            SLLogAsync(@"Cannot locate %@ in the accessibility hierarchy. Returning -NO from -slAccessibilityIsVisible.", self);
            return NO;
        }
        parentOrSelf = container;
        container = [container accessibilityContainer];
    }

    NSAssert([container isKindOfClass:[UIView class]],
             @"Every accessibility hierarchy should be rooted in a view.");
    UIView *viewContainer = (UIView *)container;
    return [viewContainer slAccessibilityIsVisible];
}

@end


@implementation UIView (SLVisibility)

- (void)renderViewRecursively:(UIView *)view inContext:(CGContextRef)context withTargetView:(UIView *)target baseView:(UIView *)baseView {
    // Skip any views that are hidden or have alpha < kMinVisibleAlphaFloat.
    if (view.hidden || view.alpha < kMinVisibleAlphaFloat) {
        return;
    }

    // Push the drawing state to save the clip mask.
    CGContextSaveGState(context);
    if ([view clipsToBounds]) {
        CGContextClipToRect(context, [baseView convertRect:view.bounds fromView:view]);
    }

    // Push the drawing state to save the CTM.
    CGContextSaveGState(context);

    // Apply a transform that takes the origin to view's top left corner.
    const CGPoint viewOrigin = [baseView convertPoint:view.bounds.origin fromView:view];
    CGContextTranslateCTM(context, viewOrigin.x, viewOrigin.y);

    // If this is *not* in our target view's hierarchy then use the destination
    // out blend mode to reduce the visibility of any already painted pixels by
    // the alpha of the current view.
    //
    // If this is in our target view's hierarchy then just draw a black rectangle
    // covering the whole thing.
    if (![view isDescendantOfView:target]) {
        CGContextSetBlendMode(context, kCGBlendModeDestinationOut);
        // Draw the view.  I haven't found anything better than this, unfortunately.
        // renderInContext is pretty inefficient for our purpose because it renders
        // the whole tree under view instead of *only* rendering view.
        [view.layer renderInContext:context];
    } else {
        CGContextSetFillColor(context, (CGFloat[2]){0.0, 1.0});
        CGContextSetBlendMode(context, kCGBlendModeCopy);
        CGContextFillRect(context, view.bounds);
    }

    // Restore the CTM.
    CGContextRestoreGState(context);

    // Recurse for subviews
    for (UIView *subview in [view subviews]) {
        [self renderViewRecursively:subview inContext:context withTargetView:target baseView:baseView];
    }

    // Restore the clip mask.
    CGContextRestoreGState(context);
}

- (NSUInteger)numberOfPointsFromSet:(const CGPoint *)testPointsInWindow count:(const NSUInteger)numPoints thatAreVisibleInWindow:(UIWindow *)window {
    static CGColorSpaceRef rgbColorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    });

    NSParameterAssert(numPoints > 0);
    NSParameterAssert(testPointsInWindow != NULL);
    NSParameterAssert(window != nil);

    // Allocate a buffer sufficiently large to store a rendering that could possibly cover all the test points.
    int x = rintf(testPointsInWindow[0].x);
    int y = rintf(testPointsInWindow[0].y);
    int minX = x;
    int maxX = x;
    int minY = y;
    int maxY = y;
    for (NSUInteger j = 1; j < numPoints; j++) {
        x = rintf(testPointsInWindow[j].x);
        y = rintf(testPointsInWindow[j].y);
        minX = MIN(minX, x);
        maxX = MAX(maxX, x);
        minY = MIN(minY, y);
        maxY = MAX(maxY, y);
    }
    NSAssert(maxX >= minX, @"maxX (%d) should be greater than or equal to minX (%d)", maxX, minX);
    NSAssert(maxY >= minY, @"maxY (%d) should be greater than or equal to minY (%d)", maxY, minY);
    size_t columns = maxX - minX + 1;
    size_t rows = maxY - minY + 1;
    unsigned char *pixels = (unsigned char *)calloc(columns * rows * 4, 1);
    CGContextRef context = CGBitmapContextCreate(pixels, columns, rows, 8, 4 * columns, rgbColorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(context, -minX, -minY);
    [self renderViewRecursively:window inContext:context withTargetView:self baseView:window];

    NSUInteger count = 0;
    for (NSUInteger j = 0; j < numPoints; j++) {
        int x = rintf(testPointsInWindow[j].x);
        int y = rintf(testPointsInWindow[j].y);
        NSAssert(x >= minX, @"Invalid x encountered, %d, but min is %d", x, minX);
        NSAssert(y >= minY, @"Invalid y encountered, %d, but min is %d", y, minY);
        NSUInteger col = x - minX;
        NSUInteger row = y - minY;
        NSUInteger pixelIndex = row * columns + col;
        NSAssert(pixelIndex < columns * rows, @"Encountered invalid pixel index: %lu", (unsigned long)pixelIndex);
        if (pixels[4 * pixelIndex + 3] >= kMinVisibleAlphaInt) {
            count++;
        }
    }

    CGContextRelease(context);
    free(pixels);

    return count;
}

- (BOOL)slAccessibilityRectIsVisible:(CGRect)rect {
    // View is not visible if it's hidden or has very low alpha.
    if (self.hidden || self.alpha < kMinVisibleAlphaFloat) {
        return NO;
    }

    // View is not visible within a rect if its center point is not inside its window.
    const CGPoint centerInScreenCoordinates = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    const CGPoint centerInWindow = [window convertPoint:centerInScreenCoordinates fromWindow:nil];

    const CGRect windowBounds = [window bounds];
    if (!CGRectContainsPoint(windowBounds, centerInWindow)) {
        return NO;
    }

    // View is not visible if it is a descendent of any hidden view.
    UIView *parent = [self superview];
    while (parent) {
        if (parent.hidden || parent.alpha < kMinVisibleAlphaFloat) {
            return NO;
        }
        parent = [parent superview];
    }

    // Subliminal's visibility rules are:
    // 1.  If the center is visible then the view is visible.
    // 2.  If the center is not visible *and* at least one corner is not visible then the view is not visible.
    // 3.  If the center is not visible but *all four* corners are visible (strange as that would be) the view is visible.
    if ([self numberOfPointsFromSet:&centerInWindow count:1 thatAreVisibleInWindow:window] == 0) {
        // Center is covered, so check the status of the corners.
        const CGPoint topLeftInScreenCoordinates = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
        const CGPoint topRightInScreenCoordinates = CGPointMake(CGRectGetMaxX(rect) - 1.0, CGRectGetMinY(rect));
        const CGPoint bottomLeftInScreenCoordinates = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect) - 1.0);
        const CGPoint bottomRightInScreenCoordinates = CGPointMake(CGRectGetMaxX(rect) - 1.0, CGRectGetMaxY(rect) - 1.0);
        const CGPoint topLeftInWindow = [window convertPoint:topLeftInScreenCoordinates fromWindow:nil];
        const CGPoint topRightInWindow = [window convertPoint:topRightInScreenCoordinates fromWindow:nil];
        const CGPoint bottomLeftInWindow = [window convertPoint:bottomLeftInScreenCoordinates fromWindow:nil];
        const CGPoint bottomRightInWindow = [window convertPoint:bottomRightInScreenCoordinates fromWindow:nil];
        NSUInteger numberOfVisiblePoints = [self numberOfPointsFromSet:(CGPoint[4]){topLeftInWindow, topRightInWindow, bottomLeftInWindow, bottomRightInWindow} count:4 thatAreVisibleInWindow:window];
        // View with a covered center is visible only if all four corners are visible.
        return (numberOfVisiblePoints == 4);
    } else {
        // Center is not covered, so consider the view visible no matter what else is going on.
        return YES;
    }
}

- (BOOL)slAccessibilityIsVisible {
    return [self slAccessibilityRectIsVisible:self.accessibilityFrame];
}

@end
